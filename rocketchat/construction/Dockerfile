FROM rocketchat:latest
# toutes les 5 minutes, le daemon DOcker invoquera le HEALTHCHECK, pour actualiser le statutu du conteneur
HEALTHCHECK --interval=5s --timeout=3s   CMD curl -f http://localhost:3000/ || exit 1
# pour tout le reste, on hérite et conserve tout de RocketChat
