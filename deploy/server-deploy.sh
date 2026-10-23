#!/bin/sh
# Deploys the develop branch. Install on the server as ~/deploy.sh (outside the repo, so a
# deploy never rewrites the script while it runs). Run by GitHub Actions and by `dip deploy`.
set -eu
exec 9>/tmp/nearshare-deploy.lock
flock 9   # one deploy at a time

cd /home/ubuntu/share-app
git fetch --quiet origin develop
git checkout --quiet -B develop FETCH_HEAD
echo "Deploying $(git log --oneline -1)"

cd deploy
sh generate-rtc-config.sh
sudo docker compose up -d --build --remove-orphans --wait --wait-timeout 120
sudo docker compose ps --format "{{.Name}}\t{{.Status}}"
sudo docker image prune -f >/dev/null
