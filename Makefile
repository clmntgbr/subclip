#!/usr/bin/env bash

include .env
export $(shell sed 's/=.*//' .env)

DOCKER_COMPOSE = docker compose -p $(ROOT_PROJECT_NAME)

CONTAINER_PHP := $(shell docker container ls -f "name=$(ROOT_PROJECT_NAME)-php" -q)
CONTAINER_SE := $(shell docker container ls -f "name=$(ROOT_PROJECT_NAME)-sound-extractor" -q)
CONTAINER_SG := $(shell docker container ls -f "name=$(ROOT_PROJECT_NAME)-subtitle-generator" -q)
CONTAINER_SM := $(shell docker container ls -f "name=$(ROOT_PROJECT_NAME)-subtitle-merger" -q)
CONTAINER_ST := $(shell docker container ls -f "name=$(ROOT_PROJECT_NAME)-subtitle-transformer" -q)
CONTAINER_SI := $(shell docker container ls -f "name=$(ROOT_PROJECT_NAME)-subtitle-incrustator" -q)

PHP := docker exec -ti $(CONTAINER_PHP)
PHP_SH := docker exec -ti $(CONTAINER_PHP) sh -c
SE := docker exec -ti $(CONTAINER_SE)
SG := docker exec -ti $(CONTAINER_SG)
SM := docker exec -ti $(CONTAINER_SM)
ST := docker exec -ti $(CONTAINER_ST)
SI := docker exec -ti $(CONTAINER_SI)

start:
	cd subclip-api && $(DOCKER_COMPOSE) up -d && cd ..
	cd subclip-sound-extractor && $(DOCKER_COMPOSE) up -d && cd ..
	cd subclip-subtitle-generator && $(DOCKER_COMPOSE) up -d && cd ..
	cd subclip-subtitle-merger && $(DOCKER_COMPOSE) up -d && cd ..
	cd subclip-subtitle-transformer && $(DOCKER_COMPOSE) up -d && cd ..
	cd subclip-subtitle-incrustator && $(DOCKER_COMPOSE) up -d && cd ..

stop:
	cd subclip-api && $(DOCKER_COMPOSE) down --remove-orphans && cd ..
	cd subclip-sound-extractor && $(DOCKER_COMPOSE) down --remove-orphans && cd ..
	cd subclip-subtitle-generator && $(DOCKER_COMPOSE) down --remove-orphans && cd ..
	cd subclip-subtitle-merger && $(DOCKER_COMPOSE) down --remove-orphans && cd ..
	cd subclip-subtitle-transformer && $(DOCKER_COMPOSE) down --remove-orphans && cd ..
	cd subclip-subtitle-incrustator && $(DOCKER_COMPOSE) down --remove-orphans && cd ..

build: 
	cd subclip-api && $(DOCKER_COMPOSE) build --pull --no-cache && cd ..
	cd subclip-sound-extractor && $(DOCKER_COMPOSE) build --pull --no-cache && cd ..
	cd subclip-subtitle-generator && $(DOCKER_COMPOSE) build --pull --no-cache && cd ..
	cd subclip-subtitle-merger && $(DOCKER_COMPOSE) build --pull --no-cache && cd ..
	cd subclip-subtitle-transformer && $(DOCKER_COMPOSE) build --pull --no-cache && cd ..
	cd subclip-subtitle-incrustator && $(DOCKER_COMPOSE) build --pull --no-cache && cd ..

fix:
	cd subclip-api && make php-cs-fixer && cd ..
	cd subclip-sound-extractor && make fix && cd ..
	cd subclip-subtitle-generator && make fix && cd ..
	cd subclip-subtitle-merger && make fix && cd ..
	cd subclip-subtitle-transformer && make fix && cd ..
	cd subclip-subtitle-incrustator && make fix && cd ..

setupenv:
	bash setup-env.sh

protobuf:
	cp subclip-protobuf/Message.proto subclip-api
	cp subclip-protobuf/Message.proto subclip-sound-extractor
	cp subclip-protobuf/Message.proto subclip-subtitle-generator
	cp subclip-protobuf/Message.proto subclip-subtitle-merger
	cp subclip-protobuf/Message.proto subclip-subtitle-transformer
	cp subclip-protobuf/Message.proto subclip-subtitle-incrustator
	$(PHP_SH) "find /app/src/Protobuf -mindepth 1 ! -name '.gitkeep' -delete"
	
	$(PHP) protoc --proto_path=/app --php_out=src/Protobuf /app/Message.proto
	$(SE) protoc --proto_path=/app --python_out=src/Protobuf /app/Message.proto
	$(SG) protoc --proto_path=/app --python_out=src/Protobuf /app/Message.proto
	$(SM) protoc --proto_path=/app --python_out=src/Protobuf /app/Message.proto
	$(ST) protoc --proto_path=/app --python_out=src/Protobuf /app/Message.proto
	$(SI) protoc --proto_path=/app --python_out=src/Protobuf /app/Message.proto

	$(PHP_SH) "mv /app/src/Protobuf/App/Protobuf/* /app/src/Protobuf"
	$(PHP_SH) "rm -r /app/src/Protobuf/App"
	$(PHP_SH) "rm -r /app/Message.proto"

	rm -r subclip-sound-extractor/Message.proto
	rm -r subclip-subtitle-generator/Message.proto
	rm -r subclip-subtitle-merger/Message.proto
	rm -r subclip-subtitle-transformer/Message.proto
	rm -r subclip-subtitle-incrustator/Message.proto
