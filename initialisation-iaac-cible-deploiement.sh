#!/bin/bash

# + Permet d'initialiser le contexte de déploimeent, la cible de déploiement, pour un cycle IAAC
docker pull centos:7
docker pull mongo:latest
docker pull gitlab/gitlab-ce:latest
docker pull gitlab/gitlab-runner:latest
docker pull rocketchat/rocket.chat:latest
docker pull rocketchat/hubot-rocketchat:latest
docker pull nginx:latest
