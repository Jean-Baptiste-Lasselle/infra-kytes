FROM rocketchat/rocket.chat:latest

# - HEALTHCHECK ENVIRONMENT => HEALTHCHECK SERVICE IS THERFORE BUILT IN THE IMAGE AS WELL, IN THIS MODEL :
#   so what if we consider that a dependency, that HAS to be resolved as such?
#   Okay, I we think like that, then this HEALTHCHECK, as an app, is a dependency to who?
#    It is not a ROcketChat Dependency.
#    It is not A hubot dependency
#    Neither is it a dependency of the HUBOT developed by RocketChat Team, used in this recipe, to connect gitlab to RocketChat.
#    So, to me, this HEALTHCHECK is an infrastructure dependency. It's like a RAID controller driver, to a Linux installed on a server.
#    The it has to be resolved when building his infrastructure, i.e., when building a Docker Image, for example.
#    And there I end up setting up a Jenkins Pipeline, to build an app, to build an infrastructure, that will receive other apps.

# And....
# There you go.
ARG UTILISATEUR_ROCKETCHAT_HUBOT
ENV UTILISATEUR_ROCKETCHAT_HUBOT=$UTILISATEUR_ROCKETCHAT_HUBOT

ARG UTILISATEUR_ROCKETCHAT_HUBOT_MDP
ENV UTILISATEUR_ROCKETCHAT_HUBOT_MDP=$UTILISATEUR_ROCKETCHAT_HUBOT_MDP

ARG CHATROOM_ROCKETCHAT_HUBOT
ENV CHATROOM_ROCKETCHAT_HUBOT=$CHATROOM_ROCKETCHAT_HUBOT

# RUN apt-get update -y && apt-get install -y curl

ADD ./avail-to-hubot-healthcheck .
ADD ./healthcheck .

# USER root

# RUN chmod +x ./avail-to-hubot-healthcheck .
# RUN chmod +x ./healthcheck .

# toutes les 5 minutes, le daemon DOcker invoquera le HEALTHCHECK, pour actualiser le statutu du conteneur
# HEALTHCHECK --interval=5s --timeout=3s   CMD curl -f http://localhost:3000/ || exit 1
HEALTHCHECK --interval=4s --timeout=3s --retries=150 CMD ./avail-to-hubot-healthcheck && ./healthcheck
# pour tout le reste, on hérite et conserve tout de RocketChat
