# Copyright (c) Humlab Development Team.
# Distributed under the terms of the Modified BSD License.

include .env

.DEFAULT_GOAL=build

build: check-files network volumes notebook_image
	docker-compose build

rebuild: down clear_volumes build up
	@echo "Rebuild done"
	@exit 0

network:
	@docker network inspect $(DOCKER_NETWORK_NAME) >/dev/null 2>&1 || docker network create $(DOCKER_NETWORK_NAME)

volumes:
	@docker volume inspect $(DATA_VOLUME_HOST) >/dev/null 2>&1 || docker volume create --name $(DATA_VOLUME_HOST)

secrets/.env.oauth2:
	@echo "File .env.oauth2 file is missing (GitHub parameters)"
	@exit 1

userlist:
	@echo "Add usernames, one per line, to ./userlist, such as:"
	@echo "    zoe admin"
	@echo "    wash"
	@exit 1

check-files: config/userlist secrets/.env.oauth2 requirements.txt # $(cert_files) secrets/postgres.env

pull:
	docker pull $(DOCKER_NOTEBOOK_IMAGE)

text_base_image:
	docker build -t rogermahler/humlab_text_base:latest -f inidun_lab/Dockerfile.text_base inidun_lab
	docker login docker.io
	docker push rogermahler/humlab_text_base:latest

notebook_image:
	docker build -t $(LOCAL_NOTEBOOK_IMAGE):latest -f inidun_lab/Dockerfile inidun_lab

bash:
	@docker exec -it -t inidun_hub_jupyterhub_1 /bin/bash

bash_lab:
	@docker exec -it -t `docker ps -f "ancestor=inidun_lab" -q --all | head -1` /bin/bash

clear_volumes:
	-docker volume rm `docker volume ls -q | grep jupyterhub-user` >/dev/null 2>&1
	-docker volume rm $(DATA_VOLUME_HOST) >/dev/null 2>&1

clean: down
	-docker rm `docker ps -f "ancestor=inidun_lab" -q --all` >/dev/null 2>&1
	-docker rm `docker ps -f "ancestor=inidun_jupyterhub" -q --all` >/dev/null 2>&1
	@docker volume rm `docker volume ls -q`

down:
	-docker-compose down

up:
	@docker-compose up -d

follow:
	@docker logs inidun_hub --follow

follow_lab:
	@docker logs `docker ps -f "ancestor=inidun_lab" -q --all | head -1` --follow

restart: down up follow

nuke:
	-docker stop `docker ps --all -q`
	-docker rm -fv `docker ps --all -q`
	-docker images -q --filter "dangling=true" | xargs docker rmi

requirements.txt:
	@wget -qO Pipfile.lock  https://raw.githubusercontent.com/inidun/text_analytics/master/Pipfile.lock
	@jq -r '.default | to_entries[] | .key + .value.version' Pipfile.lock > requirements.txt
	@if ! cmp -s ./requirements.txt inidun_lab/requirements.txt ; then \cp -f ./requirements.txt inidun_lab/requirements.txt; fi
	@rm -f requirements.txt Pipfile.lock

.PHONY: bash clear_volumes clean down up follow build restart pull nuke network userlist requirements.txt
