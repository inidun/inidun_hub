# Copyright (c) Humlab Development Team.
# Distributed under the terms of the Modified BSD License.

include .env

SHELL = /bin/bash

.DEFAULT_GOAL=build

SPACY_DATA=/data/lib/spacy_data
NLTK_DATA=/data/lib/nltk_data

HOST_USERNAME=$(PROJECT_NAME)

build: check-files network host-volume lab-image hub-image host-user
	@echo "Build done"

host-user:
	@getent group $(HOST_USERNAME) &> /dev/null || echo addgroup --gid $(LAB_GID) $(HOST_USERNAME) &>/dev/null
	@id -u $(HOST_USERNAME) &> /dev/null || sudo adduser $(HOST_USERNAME) --uid $(LAB_UID) --gid $(LAB_GID) --no-create-home --disabled-password --gecos '' --shell /bin/bash

rebuild: down clear-user-volumes build jupyterhub-config up
	@echo "Rebuild done"
	@exit 0

jupyterhub-config:
	@echo "Copying jupyterhub_config.py to /etc/jupyterhub/jupyterhub_config.py"
	@sudo cp -f jupyterhub_config.py /etc/jupyterhub/jupyterhub_config.py
	# @echo "info: remember to clear host volume if jupyterhub_config.py has been changed!"
	# @docker volume rm $(HUB_HOST_VOLUME_NAME)

network:
	@docker network inspect $(HUB_NETWORK_NAME) >/dev/null 2>&1 || docker network create $(HUB_NETWORK_NAME)

host-volume:
	@docker volume inspect $(HUB_HOST_VOLUME_NAME) >/dev/null 2>&1 || docker volume create --name $(HUB_HOST_VOLUME_NAME)

.ONESHELL: data
.PHONY: data
data:
	@if [ ! -d /data/lib/spacy_data ] ; then \
		sudo ./scripts/download-spacy-data.sh ;
	fi ; \
	if [ ! -d /data/lib/nltk_data ] ; then \
		sudo ./scripts/download-nltk-data.sh ;
	fi ; \
	sudo mkdir -p /data/$(PROJECT_NAME)

secrets/.env.oauth2:
	@echo "File .env.oauth2 file is missing (GitHub parameters)"
	@exit 1

userlist:
	@echo "Add usernames, one per line, to ./userlist, such as:"
	@echo "    zoe admin"
	@echo "    wash"
	@exit 1

check-files: config/userlist secrets/.env.oauth2

# hub-image:
# 	@docker-compose build
# 	@docker tag $(HUB_IMAGE_NAME):latest $(HUB_IMAGE_NAME):$(PYPI_PACKAGE_VERSION)

lab-image:
	@echo "Building lab image"
	docker build \
		--build-arg PYPI_PACKAGE=$(PYPI_PACKAGE) \
		--build-arg PYPI_PACKAGE_VERSION=$(PYPI_PACKAGE_VERSION) \
		--build-arg GITHUB_REPOSITORY_URL=$(GITHUB_REPOSITORY_URL) \
		--build-arg JUPYTERHUB_VERSION=$(JUPYTERHUB_VERSION) \
		--build-arg LAB_UID=$(LAB_UID) \
		--build-arg LAB_GID=$(LAB_GID) \
		-t $(LAB_IMAGE_NAME):latest \
		-t $(LAB_IMAGE_NAME):$(PYPI_PACKAGE_VERSION) \
		-f $(LAB_IMAGE_NAME)/Dockerfile $(LAB_IMAGE_NAME)

hub-image:
	@echo "Building hub image"
	docker build \
		--build-arg JUPYTERHUB_VERSION=$(JUPYTERHUB_VERSION) \
		-t $(HUB_IMAGE_NAME):latest \
		-t $(HUB_IMAGE_NAME):$(PYPI_PACKAGE_VERSION) \
		-f ./Dockerfile .

run-lab-image:
	@echo "Building lab image"
	@docker build \
		--build-arg PYPI_PACKAGE=$(PYPI_PACKAGE) \
		--build-arg PYPI_PACKAGE_VERSION=$(PYPI_PACKAGE_VERSION) \
		--build-arg GITHUB_REPOSITORY_URL=$(GITHUB_REPOSITORY_URL) \
		--build-arg JUPYTERHUB_VERSION=$(JUPYTERHUB_VERSION) \
		--build-arg LAB_PORT=8889 \
		-t $(LAB_IMAGE_NAME):8889 \
		-f $(LAB_IMAGE_NAME)/Dockerfile $(LAB_IMAGE_NAME)
	@docker run --rm -p 8889:8889 --mount "type=bind,source=/data,target=/data" $(LAB_IMAGE_NAME):8889

bash-exec-hub:
	@docker exec -it -t `docker ps -f "ancestor=$(HUB_IMAGE_NAME)" -q --all | head -1` /bin/bash

bash-exec-lab:
	@docker exec -it -t `docker ps -f "ancestor=$(LAB_IMAGE_NAME)" -q --all | head -1` /bin/bash

bash-run-hub:
	@docker run --rm -it $(HUB_IMAGE_NAME) /bin/bash

bash-run-lab:
	@docker run --rm -it $(LAB_IMAGE_NAME):latest /bin/bash

USER_VOLUMES=$(shell docker volume ls -q | grep -E 'jupyterhub-$(PROJECT_NAME)')
USER_VOLUMES_BACKUP_NAME="jupyterhub-$(PROJECT_NAME)-user-volumes-"`date '+%Y%m%d-%H%M'`.tar.gz

.ONESHELL:
clear-user-volumes: backup-user-volumes
	@if [ "$(USER_VOLUMES)" != "" ]; then \
		echo "Removing user volumes: $(USER_VOLUMES)" ; \
		docker volume rm $(USER_VOLUMES) ; \
	fi

.ONESHELL:
backup-user-volumes:
	@echo "Backing up to $(USER_VOLUMES_BACKUP_NAME)"
	@mkdir -p ~/backup/docker-volumes/
	@sudo find /var/lib/docker/volumes -maxdepth 1 -mindepth 1 -name "*$(PROJECT_NAME)*" -not -type l -print | \
		sudo tar -czvf ~/backup/docker-volumes/$(USER_VOLUMES_BACKUP_NAME) --files-from=- >/dev/null 2>&1

clean: down
	-docker rm `docker ps -f "ancestor=$(LAB_IMAGE_NAME)" -q --all` >/dev/null 2>&1
	-docker rm `docker ps -f "ancestor=$(HUB_IMAGE_NAME)" -q --all` >/dev/null 2>&1
	echo "FIX THIS: @docker volume rm `docker volume ls -q`"

down:
	-docker-compose down

up:
	@docker-compose up -d

follow-hub:
	@docker logs $(LAB_IMAGE_NAME) --follow

follow-lab:
	@docker logs `docker ps -f "ancestor=$(LAB_IMAGE_NAME)" -q --all | head -1` --follow

restart: down up follow

nuke:
	-docker stop `docker ps --all -q`
	-docker rm -fv `docker ps --all -q`
	-docker images -q --filter "dangling=true" | xargs docker rmi

tag: guard_clean_working_repository
	@git tag $(PYPI_PACKAGE_VERSION) -a
	@git push origin --tags

.ONESHELL: guard_clean_working_repository
guard_clean_working_repository:
	@status="$$(git status --porcelain)"
	@if [ "$$status" != "" ]; then
		echo "error: changes exists, please commit or stash them: "
		echo "$$status"
		exit 65
	fi

.PHONY: bash-run-hub bash-run-lab bash-exec-hub bash-exec-lab follow-hub follow-lab
.PHONY: clear-user-volumes clean
.PHONY: down up build restart network userlist host-volume
.PHONY: lab-image hub-image
.PHONY: nuke tag guard_clean_working_repository
