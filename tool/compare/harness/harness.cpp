// Measurement harness around the SpaceCadetPinball decompilation: loads
// PINBALL.DAT headless, plays scripted scenarios at a fixed update rate and
// prints the ball's track as CSV, for comparison with the Flutter port.
//
// Scenario file:
//   scenario <name> <seconds>
//   ball <x> <y> <vx> <vy>      (optional: otherwise the ball stays on the plunger)
//   at <t> <action>             leftDown leftUp rightDown rightUp plungerDown plungerUp
//   end
#include "pch.h"
#include "winmain.h"
#include "options.h"
#include "pb.h"
#include "Sound.h"
#include "midi.h"
#include "TPinballTable.h"
#include "TBall.h"
#include "maths.h"

bool HarnessNoRandom = false;

struct Event { float t; std::string action; };
struct Scenario
{
	std::string name;
	float duration = 3;
	bool placeBall = false;
	float x = 0, y = 0, vx = 0, vy = 0;
	std::vector<Event> events;
};

static std::vector<Scenario> readScenarios(const char* path)
{
	std::vector<Scenario> list;
	FILE* f = fopen(path, "r");
	if (!f) { fprintf(stderr, "cannot open %s\n", path); exit(1); }
	char line[512];
	Scenario cur;
	while (fgets(line, sizeof line, f))
	{
		char word[64]{}, arg[128]{};
		if (sscanf(line, "%63s", word) != 1 || word[0] == '#') continue;
		std::string w = word;
		if (w == "scenario") { cur = Scenario{}; sscanf(line, "%*s %127s %f", arg, &cur.duration); cur.name = arg; }
		else if (w == "ball") { cur.placeBall = true; sscanf(line, "%*s %f %f %f %f", &cur.x, &cur.y, &cur.vx, &cur.vy); }
		else if (w == "at") { Event e; sscanf(line, "%*s %f %127s", &e.t, arg); e.action = arg; cur.events.push_back(e); }
		else if (w == "end") list.push_back(cur);
	}
	fclose(f);
	return list;
}

static void act(const std::string& a)
{
	auto table = pb::MainTable;
	auto now = pb::time_now;
	if (a == "leftDown") table->Message(MessageCode::LeftFlipperInputPressed, now);
	else if (a == "leftUp") table->Message(MessageCode::LeftFlipperInputReleased, now);
	else if (a == "rightDown") table->Message(MessageCode::RightFlipperInputPressed, now);
	else if (a == "rightUp") table->Message(MessageCode::RightFlipperInputReleased, now);
	else if (a == "plungerDown") table->Message(MessageCode::PlungerInputPressed, now);
	else if (a == "plungerUp") table->Message(MessageCode::PlungerInputReleased, now);
	else fprintf(stderr, "unknown action %s\n", a.c_str());
}

int main(int argc, char* argv[])
{
	if (argc < 3)
	{
		fprintf(stderr, "usage: harness <data dir> <scenarios> [ups] [--random]\n");
		return 1;
	}
	const float ups = argc > 3 ? static_cast<float>(atof(argv[3])) : 120.0f;
	HarnessNoRandom = !(argc > 4 && strcmp(argv[4], "--random") == 0);
	srand(1);

	SDL_SetHint(SDL_HINT_VIDEODRIVER, "dummy");
	SDL_SetMainReady();
	if (SDL_Init(SDL_INIT_TIMER | SDL_INIT_VIDEO | SDL_INIT_EVENTS) < 0)
	{
		fprintf(stderr, "SDL: %s\n", SDL_GetError());
		return 1;
	}
	winmain::MainWindow = SDL_CreateWindow("harness", 0, 0, 600, 416, SDL_WINDOW_HIDDEN);
	winmain::Renderer = SDL_CreateRenderer(winmain::MainWindow, -1, SDL_RENDERER_SOFTWARE);
	if (!winmain::Renderer)
	{
		fprintf(stderr, "renderer: %s\n", SDL_GetError());
		return 1;
	}

	ImGui::CreateContext();
	static std::string ini = std::string(SDL_GetBasePath()) + "harness.ini";
	ImGui::GetIO().IniFilename = ini.c_str();
	winmain::ImIO = &ImGui::GetIO();
	options::InitPrimary();
	std::vector<const char*> paths{argv[1]};
	pb::SelectDatFile(paths);
	options::InitSecondary();
	Sound::Init(false, 8, false, 0);
	midi::music_init(false, 0);
	if (pb::init())
	{
		fprintf(stderr, "could not load %s\n", argv[1]);
		return 1;
	}
	pb::reset_table();
	pb::firsttime_setup();

	const float dtMs = 1000.0f / ups;
	auto step = [&](float seconds)
	{
		for (int i = 0, n = static_cast<int>(seconds * ups + 0.5f); i < n; i++)
			pb::frame(dtMs);
	};

	printf("scenario,t,x,y,z,vx,vy,mask,holder\n");
	for (auto& s : readScenarios(argv[2]))
	{
		pb::replay_level(false);
		step(8); // light show, then the ball is fed onto the plunger
		auto ball = pb::MainTable->BallList.at(0);
		if (s.placeBall)
		{
			ball->CollisionComp = nullptr;
			ball->CollisionMask = 1;
			ball->EdgeCollisionCount = 0;
			ball->Position = {s.x, s.y, ball->Radius};
			ball->PrevPosition = ball->Position;
			ball->Direction = {s.vx, s.vy, 0};
			ball->Speed = maths::normalize_2d(ball->Direction);
			// As TPinballTable::AddBall: a fresh ball, not one that has
			// been standing on the plunger for seconds.
			ball->StuckCounter = 0;
			ball->LastActiveTime = pb::time_ticks;
		}
		size_t next = 0;
		const int frames = static_cast<int>(s.duration * ups + 0.5f);
		for (int i = 0; i <= frames; i++)
		{
			const float t = i / ups;
			while (next < s.events.size() && s.events[next].t <= t + 1e-6f)
				act(s.events[next++].action);
			// Log every 10 ms.
			if (i % std::max(1, static_cast<int>(ups / 100.0f + 0.5f)) == 0)
			{
				if (ball->ActiveFlag)
					printf("%s,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%d,%s\n", s.name.c_str(), t,
					       ball->Position.X, ball->Position.Y, ball->Position.Z,
					       ball->Direction.X * ball->Speed, ball->Direction.Y * ball->Speed,
					       ball->CollisionMask,
					       ball->CollisionComp && ball->CollisionComp->GroupName
						       ? ball->CollisionComp->GroupName
						       : "");
				else
					printf("%s,%.4f,,,,,,,\n", s.name.c_str(), t);
			}
			pb::frame(dtMs);
		}
		for (auto a : {"leftUp", "rightUp", "plungerUp"}) act(a);
	}
	return 0;
}
