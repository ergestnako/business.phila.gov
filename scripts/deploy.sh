#!/bin/bash


set -e

_dir="$(dirname "$0")"

source "$_dir/lib/mo"

echo 'Installing non-free plugins and themes'
"$_dir/non-free.sh"

echo 'Modifying php.ini'
sudo ed -s /etc/php5/fpm/php.ini <<'EOF'
g/post_max_size/s/8/100
g/upload_max_filesize/s/2/100
g/expose_php/s/On/Off
w
EOF

echo 'Reloading php-fpm'
# https://bugs.launchpad.net/ubuntu/+source/php5/+bug/1242376
sudo kill -USR2 "$(cat /var/run/php5-fpm.pid)"

echo 'Refreshing WordPress'
wp rewrite flush
wp core update-db
mkdir -p wp/wp-content/uploads
sudo chmod 777 -R wp/wp-content/uploads

echo 'Rendering nginx confs'
# Render nginx confs into /etc with mo
sudo rm -rf /etc/nginx
shopt -s globstar
# Defaults
[ ! "$ROBOTS_DISALLOW" ] && export ROBOTS_DISALLOW=/
for f in nginx/**; do
  [ ! -f "$f" ] && continue
  sudo mkdir -p "$(dirname "/etc/$f")"
  mo "$f" | sudo tee "/etc/$f" > /dev/null
done

echo 'Testing nginx config'
sudo nginx -t

echo 'Purging nginx cache'
sudo rm -rf /var/run/nginx-cache

sudo service nginx reload
