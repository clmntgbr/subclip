#!/usr/bin/env bash

include .env
export $(shell sed 's/=.*//' .env)

DOCKER_COMPOSE = docker compose -p $(ROOT_PROJECT_NAME)

CONTAINER_PHP := $(shell docker container ls -f "name=$(ROOT_PROJECT_NAME)-php" -q)

PHP := docker exec -ti $(CONTAINER_PHP)
PHP_SH := docker exec -ti $(CONTAINER_PHP) sh -c

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

protobuf:
	cp subclip-protobuf/Message.proto subclip-api
	$(PHP_SH) "find /app/src/Protobuf -mindepth 1 ! -name '.gitkeep' -delete"
	$(PHP) protoc --proto_path=/app --php_out=src/Protobuf /app/Message.proto
	$(PHP_SH) "mv /app/src/Protobuf/App/Protobuf/* /app/src/Protobuf"
	$(PHP_SH) "rm -r /app/src/Protobuf/App"
	$(PHP_SH) "rm -r /app/Message.proto"
