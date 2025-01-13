#!/bin/sh

set -xe
cd /var/www || exit
sleep 10s # Wait for postgres
php artisan migrate:refresh --seed
php artisan optimize

php -d variables_order=EGPCS /var/www/artisan serve --host=0.0.0.0 --port=9090
