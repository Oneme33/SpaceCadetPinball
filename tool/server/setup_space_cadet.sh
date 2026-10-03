#!/bin/bash
# One-off setup of space-cadet.nl on the Lukraak server (Apache, certbot).
# Run on the server with sudo:
#
#   sudo bash ~/space-cadet/setup_space_cadet.sh
#
# Creates /var/www/space-cadet.nl/www (owned by beheer, readable by Apache,
# so deploys need no sudo), installs and enables the Apache site, and, once
# the DNS points here, gets the HTTPS certificate. Safe to run again.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
OWNER="${SUDO_USER:-beheer}"
SITE=space-cadet.nl
ROOT=/var/www/$SITE/www

mkdir -p "$ROOT"
chown -R "$OWNER":www-data "/var/www/$SITE"
chmod -R u=rwX,g=rX,o=rX "/var/www/$SITE"
[ -f "$ROOT/index.html" ] || echo '<!doctype html><title>Space Cadet</title><p>Coming soon.</p>' > "$ROOT/index.html"
chown "$OWNER":www-data "$ROOT/index.html"

install -m 644 "$HERE/$SITE.conf" "/etc/apache2/sites-available/$SITE.conf"
install -m 644 "$HERE/space-cadet-cache.conf" /etc/apache2/conf-available/space-cadet-cache.conf
a2enconf -q space-cadet-cache
a2enmod headers deflate >/dev/null
a2ensite "$SITE" >/dev/null
apache2ctl configtest
systemctl reload apache2
echo "Apache serves $SITE from $ROOT."

ip=$(curl -s -4 https://ifconfig.me || true)
if [ -n "$ip" ] && [ "$(dig +short A $SITE | tail -1)" = "$ip" ] && [ "$(dig +short A www.$SITE | tail -1)" = "$ip" ]; then
  certbot --apache -d "$SITE" -d "www.$SITE" --redirect --non-interactive --agree-tos --keep-until-expiring \
    ${CERTBOT_EMAIL:+-m "$CERTBOT_EMAIL"} ${CERTBOT_EMAIL:---register-unsafely-without-email}
  echo "HTTPS is on."
else
  echo "DNS for $SITE and www.$SITE does not point to this server ($ip) yet."
  echo "Once it does, run this script again for HTTPS."
fi
