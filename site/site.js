// Starfield, the support button and the game loading on demand.
(function () {
  // --- Stars, as the game's menu: twinkling, a few drifting. -----------
  var canvas = document.getElementById('stars');
  var ctx = canvas.getContext('2d');
  var still = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var colours = ['#ffffff', '#9fb4ff', '#6e86e8'];
  var stars = [];
  for (var i = 0; i < 220; i++) {
    stars.push({ x: Math.random(), y: Math.random(), c: i % 3, p: Math.random() * 6.3 });
  }
  function resize() {
    canvas.width = innerWidth * devicePixelRatio;
    canvas.height = innerHeight * devicePixelRatio;
  }
  function draw(t) {
    var w = canvas.width, h = canvas.height, s = devicePixelRatio;
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, w, h);
    var g = ctx.createRadialGradient(w * .5, h * .3, 0, w * .5, h * .3, Math.max(w, h) * .6);
    g.addColorStop(0, '#2a1b5c55');
    g.addColorStop(1, '#00000000');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, w, h);
    for (var i = 0; i < stars.length; i++) {
      var st = stars[i];
      var a = still ? .8 : .45 + .55 * Math.abs(Math.sin(t / 1000 * 1.7 + st.p));
      var drift = st.c === 0 && !still ? (t / 1000 * .004 * (1 + st.p / 6.3)) % 1 : 0;
      ctx.globalAlpha = a;
      ctx.fillStyle = colours[st.c];
      var r = (st.c === 0 ? 1.6 : 1.1) * s;
      ctx.fillRect(((st.x - drift + 1) % 1) * w, st.y * h, r, r);
    }
    ctx.globalAlpha = 1;
    if (!still) requestAnimationFrame(draw);
  }
  addEventListener('resize', function () { resize(); if (still) draw(0); });
  resize();
  requestAnimationFrame(draw);

  // --- Support link, from config.js. -------------------------------------
  var url = (window.SITE && window.SITE.supportUrl) || '';
  if (url) {
    ['support-button', 'support-button-2'].forEach(function (id) {
      var b = document.getElementById(id);
      b.href = url;
      b.hidden = false;
    });
    document.getElementById('support-panel').hidden = false;
  }

  // --- APK size, if the server tells. ------------------------------------
  fetch('download/space-cadet.apk', { method: 'HEAD' }).then(function (r) {
    var n = +r.headers.get('content-length');
    if (r.ok && n) document.getElementById('apk-size').textContent = Math.round(n / 1e6) + ' MB';
  }).catch(function () {});

  // --- The game, loaded only when asked for (it is some 20 MB). ----------
  function launch() {
    var screen = document.getElementById('screen');
    if (screen.querySelector('iframe')) return;
    var f = document.createElement('iframe');
    f.src = 'play/';
    f.title = 'Space Cadet Pinball';
    f.allow = 'autoplay; fullscreen';
    screen.innerHTML = '';
    screen.appendChild(f);
    f.focus();
  }
  document.getElementById('start').addEventListener('click', launch);
  document.getElementById('play-button').addEventListener('click', function (e) {
    // On phones the full-screen version plays best.
    if (matchMedia('(max-width: 720px)').matches) {
      e.preventDefault();
      location.href = 'play/';
    }
  });
})();
