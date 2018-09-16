#!/bin/bash

cat ./.env|grep 
VERSION_IMAGE_CENTOS=centos:7
VERSION_IMAGE_MONGO=mongo:latest
VERSION_IMAGE_GITLAB_CE=gitlab/gitlab-ce:latest
VERSION_IMAGE_GITLAB_RUNNER=gitlab/gitlab-runner:latest
VERSION_IMAGE_ROCKETCHAT=rocketchat/rocket.chat:latest
VERSION_IMAGE_HUBOT_ROCKETCHAT=rocketchat/hubot-rocketchat:latest
VERSION_IMAGE_RNGINX=nginx:latest

# + Permet d'initialiser le contexte de déploimeent, la cible de déploiement, pour un cycle IAAC
docker pull centos:7
docker pull mongo:latest
docker pull gitlab/gitlab-ce:latest
docker pull gitlab/gitlab-runner:latest
docker pull rocketchat/rocket.chat:latest
docker pull rocketchat/hubot-rocketchat:latest
docker pull nginx:latest
