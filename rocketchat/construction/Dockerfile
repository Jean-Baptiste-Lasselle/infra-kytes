FROM rocketchat/rocket.chat:latest

# RUN apt-get update -y && apt-get install -y curl

ADD avail-to-hubot-healthcheck .
ADD healthcheck .
# toutes les 5 minutes, le daemon DOcker invoquera le HEALTHCHECK, pour actualiser le statutu du conteneur
# HEALTHCHECK --interval=5s --timeout=3s   CMD curl -f http://localhost:3000/ || exit 1
HEALTHCHECK --interval=1s --timeout=3s CMD avail-to-hubot-healthcheck && healthcheck
# pour tout le reste, on hérite et conserve tout de RocketChat
