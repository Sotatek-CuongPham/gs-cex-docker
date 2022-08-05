ifndef u
u:=sotatek
endif

ifndef env
env:=dev
endif

OS:=$(shell uname)

docker-start:
	cp laravel-echo-server.json.example laravel-echo-server.json
	@if [ $(OS) = "Linux" ]; then\
		sed -i -e "s/localhost:8000/web:8000/g" laravel-echo-server.json; \
		sed -i -e "s/\"redis\": {}/\"redis\": {\"host\": \"redis\"}/g" laravel-echo-server.json; \
	else\
		sed -i '' -e "s/localhost:8000/web:8000/g" laravel-echo-server.json; \
		sed -i '' -e "s/\"redis\": {}/\"redis\": {\"host\": \"redis\"}/g" laravel-echo-server.json; \
	fi
	docker-compose up -d

docker-restart:
	docker-compose down
	make docker-start
	make docker-init-db-full
	make docker-link-storage

docker-connect:
	./bin/docker-connect.sh

init-app:
	cp .env.example .env
	composer install
	php artisan key:generate
	php artisan passport:keys --force
	php artisan migrate
	php artisan db:seed
	php artisan storage:link

docker-init:
	#git submodule update --init
	docker exec -it php-ec make init-app
	docker exec -it php-ec rm -rf node_modules
	docker exec -it php-ec npm install

backup-db:
	mysqldump --add-drop-table -u root -p amanpuri1 > ~/amanpuri1_`date +"%d%m%Y%H%M%S"`.sql
	mysqldump --add-drop-table -u root -p amanpuri2 > ~/amanpuri2_`date +"%d%m%Y%H%M%S"`.sql

init-db-full:
	make autoload
	php artisan migrate:fresh
	make update-master
	php artisan db:seed
	./bin/import_seed_data.sh

gen-i18n:
	php artisan vue-i18n:generate

docker-gen-i18n:
	docker exec -it php-ec make gen-i18n

docker-init-db-full:
	docker exec -it php-ec make init-db-full

docker-link-storage:
	docker exec -it php-ec php artisan storage:link

init-db:
	make autoload
	php artisan migrate:fresh

start:
	php artisan serve

log:
	tail -f storage/logs/laravel.log

test-js:
	npm test

reset-env:
	php artisan config:cache
	php artisan config:clear

reset-queue:
	supervisorctl restart all

test-php:
	vendor/bin/phpcs --standard=phpcs.xml && vendor/bin/phpmd app text phpmd.xml

build:
	npm run dev

watch:
	npm run watch

docker-watch:
	docker exec -it php-ec make watch

autoload:
	composer dump-autoload

cache:
	php artisan cache:clear && php artisan view:clear && php artisan config:clear

docker-cache:
	docker exec php-ec make cache

route:
	php artisan route:list

generate-master:
	php bin/generate_master.php $(lang)

update-master:
	php artisan master:update $(lang)
	make cache

deploy:
	ssh $(u)@$(h) "mkdir -p $(dir)"
	rsync -avhzL --delete \
				--no-perms --no-owner --no-group \
				--exclude .git \
				--exclude .idea \
				--exclude .env \
				--exclude laravel-echo-server.json \
				--exclude storage/*.key \
				--exclude node_modules \
				--exclude /vendor \
				--exclude bootstrap/cache \
				--exclude storage/logs \
				--exclude storage/excel \
				--exclude storage/framework \
				--exclude storage/app \
				--exclude public/storage \
				--exclude public/excel \
				--exclude mysql \
				--exclude .env.example \
				--exclude storage/oauth-private.key \
				--exclude storage/oauth-public.key \
				. $(u)@$(h):$(dir)/

connect-master:
	ssh root@52.78.104.238

connect-slave:
	ssh root@160.16.50.160

init-db-dev:
	ssh $(u)@192.168.1.20$(n) "cd /var/www/trading/ && make init-db-full"

deploy-dev:
	make deploy h=192.168.1.205 dir=/var/www/exchange-api
	make deploy h=192.168.1.205 dir=/var/www/exchange-queue
	ssh $(u)@192.168.1.205 "cd /var/www/exchange-api && make cache && ./bin/queue/restart_all.sh && php artisan apidoc:generate "
	ssh $(u)@192.168.1.205 "cp -r /var/www/exchange-api/public/api/ /var/www/exchange/public/"

deploy-staging:
	make deploy u=root h=54.250.147.141 dir=/root/php-ec
	ssh root@54.250.147.141 "cd /root/php-ec && ./bin/deploy/deploy.sh stg-amanpuri-web1 1 && make reset-env"
	ssh root@54.250.147.141 "cd /root/php-ec && ./bin/deploy/deploy.sh stg-amanpuri-web1-lp 1"
	ssh root@54.250.147.141 "cd /root/php-ec && ./bin/deploy/deploy_queue.sh stg-amanpuri-queue 1"
	ssh root@54.250.147.141 "cd /root/php-ec && ./bin/deploy/deploy_spot.sh stg-amanpuri-spot 1"
	ssh root@54.250.147.141 "cd /root/php-ec && ./bin/deploy/deploy_margin.sh stg-amanpuri-margin 1"
	ssh root@54.250.147.141 "cd /root/php-ec && ./bin/deploy/deploy_margin.sh stg-amanpuri-margin-indexes 1"
	ssh root@54.250.147.141 "cd /root/php-ec && ./bin/deploy/deploy.sh stg-amanpuri-web2 1 && make reset-env"
	ssh root@54.250.147.141 "cd /root/php-ec && ./bin/deploy/deploy_rabbitmq.sh stg-amanpuri-rabbitmq 1"
	ssh root@54.250.147.141 "sshpass ssh stg-amanpuri-web1 \"cd /var/www/php-ec && php artisan apidoc:generate\""
	ssh root@54.250.147.141 "sshpass ssh stg-amanpuri-web2 \"cd /var/www/php-ec && php artisan apidoc:generate\""

# 	make deploy u=root h=3.217.177.14 dir=/var/www/php-ec
# 	ssh root@3.217.177.14 "cp -r /var/www/php-ec/public/api/ /var/www/amanpuri-web/public/"
# 	ssh root@3.217.177.14 "chown -R apache:apache /var/www/php-ec/database/migrations/erc20/"
# 	ssh root@3.217.177.14 "chcon -t httpd_sys_rw_content_t -R /var/www/php-ec/database/migrations/erc20"
# 	make deploy u=root h=3.92.119.98 dir=/var/www/php-ec
# 	make deploy u=root h=3.92.119.98 dir=/var/www/amanpuri-queue
# 	ssh root@3.92.119.98 "cd /var/www/php-ec && make cache && pm2 restart all "

# deploy-staging:
# 	make deploy u=root h=13.250.31.83 dir=/root/vcc
# 	ssh root@13.250.31.83 "cd /root/vcc\
# 		&& composer install\
# 		&& npm install\
# 		&& composer dump-autoload\
# 		"
# 	ssh root@13.250.31.83 "cd /root/deploy-staging\
# 		&& ./deploy_all.sh\
# 		"

deploy-env-staging:
	./bin/deploy/deploy_env_stg.sh

compile:
	ssh $(u)@$(h) "cd $(dir) && npm install && composer install && make cache && make autoload && npm run production"

deploy-dev-full:
	make deploy h=192.168.1.205 dir=/var/www/aisx$(n)
	make compile h=192.168.1.205 dir=/var/www/aisz$(n)

fix-domain:
	echo "ServerName 172.18.0.5" >> /etc/apache2/apache2.conf

fix-php:
	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
	composer self-update --1
	rm -rf vendor
	composer install