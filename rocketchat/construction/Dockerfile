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
#         - UTILISATEUR_ROCKETCHAT_JOUEUR=$UTILISATEUR_ROCKETCHAT_JOUEUR
#         - UTILISATEUR_ROCKETCHAT_JOUEUR_MDP=$UTILISATEUR_ROCKETCHAT_JOUEUR_MDP
ARG UTILISATEUR_ROCKETCHAT_JOUEUR
ENV UTILISATEUR_ROCKETCHAT_JOUEUR=$UTILISATEUR_ROCKETCHAT_JOUEUR

ARG UTILISATEUR_ROCKETCHAT_JOUEUR_MDP
ENV UTILISATEUR_ROCKETCHAT_JOUEUR_MDP=$UTILISATEUR_ROCKETCHAT_JOUEUR_MDP

# ARG CHATROOM_ROCKETCHAT_HUBOT
# ENV CHATROOM_ROCKETCHAT_HUBOT=$CHATROOM_ROCKETCHAT_HUBOT

# RUN apt-get update -y && apt-get install -y curl

# ADD ./avail-to-hubot-healthcheck .
ADD ./healthcheck .

USER root

# curl pour envoyer les requêtes avec le healthcheck, et jq pour parser les réponses JSON de la REST API RocketChat
RUN apt-get update -y && apt-get install -y curl jq 
RUN curl --version
RUN jq --version


# RUN chmod +x ./avail-to-hubot-healthcheck .
# RUN chmod +x ./healthcheck .

# toutes les 5 minutes, le daemon DOcker invoquera le HEALTHCHECK, pour actualiser le statutu du conteneur
# HEALTHCHECK --interval=5s --timeout=3s   CMD curl -f http://localhost:3000/ || exit 1
# exactement les même paramètres de hEALTHCHECK, entre mongo et rocketchat
# HEALTHCHECK --interval=6s --timeout=5s --retries=150 CMD ./avail-to-hubot-healthcheck && ./healthcheck
HEALTHCHECK --interval=6s --timeout=5s --retries=150 CMD ./healthcheck

# pour tout le reste, on hérite et conserve tout de RocketChat
