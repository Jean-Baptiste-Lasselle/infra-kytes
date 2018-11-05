#!/bin/bash

# -- Le tout doit correspondre aux variables déclarées en fichier de fichier ./.env : 

# # -- VERSIONS IMAGES DOCKER -- 
# # + À noter : ces variables d'envrionnement sont utilisée à la fois dans le docker-compose.yml, mais ne peuvent être utilisées dans les fichiers Dockerfile ('on recourera à du template jinja2 / ansible)
# VERSION_IMAGE_CENTOS=centos:7
# # VERSION_IMAGE_GITLAB_CE=gitlab/gitlab-ce:$GITLAB_CE_VERSION
# # VERSION_IMAGE_GITLAB_RUNNER=gitlab/gitlab-runner:${GITLAB_RUNNER_VERSION}
# VERSION_IMAGE_NGINX=nginx:latest
# VERSION_IMAGE_ROCKETCHAT=rocketchat/rocket.chat:latest
# VERSION_IMAGE_MONGO=mongo:latest
# # VERSION_IMAGE_POSTGRES=postgres:${POSTGRES_VERSION}
# # VERSION_IMAGE_REDIS=redis:{REDIS_VERSION}

# -- 


# VERSION_IMAGE_CENTOS=centos:7
export ID_IMAGE_CENTOS=$(cat ./.env|grep VERSION_IMAGE_CENTOS | awk -F = '{print $2}')


# VERSION_IMAGE_MONGO=mongo:latest
export ID_IMAGE_MONGO=$(cat ./.env|grep VERSION_IMAGE_MONGO | awk -F = '{print $2}')

# VERSION_IMAGE_GITLAB_CE=gitlab/gitlab-ce:latest
# export ID_IMAGE_GITLAB_CE=$(cat ./.env|grep VERSION_IMAGE_GITLAB_CE | awk -F = '{print $2}')
export CETTE_GITLAB_CE_VERSION=$(cat ./.env|grep GITLAB_CE_VERSION | awk -F = '{print $2}')
export ID_IMAGE_GITLAB_CE="gitlab/gitlab-ce:$CETTE_GITLAB_CE_VERSION"

# VERSION_IMAGE_GITLAB_RUNNER=gitlab/gitlab-runner:latest
# export ID_IMAGE_GITLAB_RUNNER=$(cat ./.env|grep VERSION_IMAGE_GITLAB_RUNNER | awk -F = '{print $2}')
export ID_IMAGE_GITLAB_RUNNER=$(cat ./.env|grep GITLAB_RUNNER_VERSION | awk -F = '{print $2}')
export ID_IMAGE_GITLAB_RUNNER="gitlab/gitlab-runner:$ID_IMAGE_GITLAB_RUNNER"

# VERSION_IMAGE_GITLAB_CE=gitlab/gitlab-ce:latest
# export ID_IMAGE_GITLAB_CE=$(cat ./.env|grep VERSION_IMAGE_GITLAB_CE | awk -F = '{print $2}')
export CETTE_POSTGRES_VERSION=$(cat ./.env|grep POSTGRES_VERSION | awk -F = '{print $2}')
export ID_IMAGE_POSTGRES="postgres:$POSTGRES_VERSION"

# VERSION_IMAGE_GITLAB_CE=gitlab/gitlab-ce:latest
# export ID_IMAGE_GITLAB_CE=$(cat ./.env|grep VERSION_IMAGE_GITLAB_CE | awk -F = '{print $2}')
export CETTE_REDIS_VERSION=$(cat ./.env|grep REDIS_VERSION | awk -F = '{print $2}')
export ID_IMAGE_REDIS="redis:REDIS_VERSION"

# VERSION_IMAGE_ROCKETCHAT=rocketchat/rocket.chat:latest
export ID_IMAGE_ROCKETCHAT=$(cat ./.env|grep VERSION_IMAGE_ROCKETCHAT | awk -F = '{print $2}')


# VERSION_IMAGE_NGINX=nginx:latest
export ID_IMAGE_NGINX=$(cat ./.env|grep VERSION_IMAGE_NGINX | awk -F = '{print $2}')


echo "   "
echo "   "
echo "  -------------------------------------------  "
echo "  +  initialisation-iaac-cible-deploiement.sh "
echo "  -------------------------------------------  "
echo "    ID_IMAGE_CENTOS=$ID_IMAGE_CENTOS "
echo "  -------------------------------------------  "
echo "    ID_IMAGE_MONGO=$ID_IMAGE_MONGO "
echo "  -------------------------------------------  "
echo "    ID_IMAGE_GITLAB_CE=$ID_IMAGE_GITLAB_CE "
echo "  -------------------------------------------  "
echo "    ID_IMAGE_GITLAB_RUNNER=$ID_IMAGE_GITLAB_RUNNER "
echo "  -------------------------------------------  "
echo "    ID_IMAGE_POSTGRES=$ID_IMAGE_POSTGRES "
echo "  -------------------------------------------  "
echo "    ID_IMAGE_REDIS=$ID_IMAGE_REDIS "
echo "  -------------------------------------------  "
echo "    ID_IMAGE_ROCKETCHAT=$ID_IMAGE_ROCKETCHAT "
echo "  -------------------------------------------  "
echo "    ID_IMAGE_NGINX=$ID_IMAGE_NGINX "
echo "  -------------------------------------------  "
echo "   "
echo "   "


docker system prune -f
# + Permet d'initialiser le contexte de déploiement, la cible de déploiement, pour un cycle IAAC
docker pull "$ID_IMAGE_CENTOS"
docker pull "$ID_IMAGE_MONGO"
docker pull "$ID_IMAGE_GITLAB_CE"
docker pull "$ID_IMAGE_GITLAB_RUNNER"
docker pull "$ID_IMAGE_POSTGRES"
docker pull "$ID_IMAGE_REDIS"
docker pull "$ID_IMAGE_ROCKETCHAT"
docker pull "$ID_IMAGE_NGINX"
