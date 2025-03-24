#!/usr/bin/env bash

include .env
export $(shell sed 's/=.*//' .env)

DOCKER_COMPOSE = docker compose -p $(ROOT_PROJECT_NAME)

CONTAINER_PHP := $(shell docker container ls -f "name=$(ROOT_PROJECT_NAME)-php" -q)

PHP := docker exec -ti $(CONTAINER_PHP)

start:
	cd subclip-api && $(DOCKER_COMPOSE) up -d && cd ..

stop:
	cd subclip-api && $(DOCKER_COMPOSE) down --remove-orphans && cd ..

build: 
	cd subclip-api && $(DOCKER_COMPOSE) build --pull --no-cache && cd ..

fix:
	cd subclip-api && make php-cs-fixer && cd ..

setupenv:
	bash setup-env.sh
