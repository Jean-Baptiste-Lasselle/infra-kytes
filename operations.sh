#!/bin/bash

# - ENV 
export NOM_CONTENEUR_HUBOT=hubot
export NOM_CONTENEUR_ROCKETCHAT=rocketchat
export NOM_CONTENEUR_BDD_ROCKETCHAT=mongo
export NOM_CONTENEUR_INIT_REPLICASET_BDD_ROCKETCHAT=mongo-init-replica
export UTILISATEUR_HUBOT_ROCKETCHAT_USERNAME=jbl
export UTILISATEUR_HUBOT_ROCKETCHAT_PWD=jbl
export ALIAS_INFRA=kytes

# - Fonctions
# --------------------------------------------------------------------------------------------------------------------------------------------
# 
# Cette fonction permet d'attendre que le conteneur soit dans l'état healthy
# Cette fonction prend un argument, nécessaire sinon une erreur est générée (TODO: à implémenter avec exit code)
checkHealth () {
	export ETATCOURANTCONTENEUR=starting
	export ETATCONTENEURPRET=healthy
	export NOM_DU_CONTENEUR_INSPECTE=$1
	
	while  $(echo "+provision+$ALIAS_INFRA+ $NOM_DU_CONTENEUR_INSPECTE - HEALTHCHECK: [$ETATCOURANTCONTENEUR]" >> ./check-health.coquelicot); do
	
	ETATCOURANTCONTENEUR=$(sudo docker inspect -f '{{json .State.Health.Status}}' $NOM_DU_CONTENEUR_INSPECTE)
	if [ $ETATCOURANTCONTENEUR == "\"healthy\"" ]
	then
		echo "+provision+$ALIAS_INFRA+ $NOM_DU_CONTENEUR_INSPECTE est prêt - HEALTHCHECK: [$ETATCOURANTCONTENEUR]"
		break;
	else
		echo "+provision+$ALIAS_INFRA+ $NOM_DU_CONTENEUR_INSPECTE n'est pas prêt - HEALTHCHECK: [$ETATCOURANTCONTENEUR] - attente d'une seconde avant prochain HealthCheck - "
		sleep 1s
	fi
	done
	rm -f ./check-health.coquelicot
	# DEBUG LOGS
	echo " provision-$ALIAS_INFRA-  ------------------------------------------------------------------------------ " 
	echo " provision-$ALIAS_INFRA-  - Contenu du répertoire [/etc/gitlab] dans le conteneur [$NOM_DU_CONTENEUR_INSPECTE]:" 
	echo " provision-$ALIAS_INFRA-  - " 
	sudo docker exec -it $NOM_DU_CONTENEUR_INSPECTE /bin/bash -c "ls -all /etc/gitlab"
	echo " provision-$ALIAS_INFRA-  ------------------------------------------------------------------------------ " 
	echo " provision-$ALIAS_INFRA-  - Existence du fichier [/etc/gitlab/gitlab.rb] dans le conteneur  [$NOM_DU_CONTENEUR_INSPECTE]:" 
	echo " provision-$ALIAS_INFRA-  - "
	sudo docker exec -it $NOM_DU_CONTENEUR_INSPECTE /bin/bash -c "ls -all /etc/gitlab/gitlab.rb" 
	echo " provision-$ALIAS_INFRA-  - " 
	echo " provision-ALIAS_INFRA-  ------------------------------------------------------------------------------ " 
}

# - OPS 

# - Je récupère, dans le fichier 'docker-compose.yml', les valeurs de configuration pour le username et le password

# export UTILISATEUR_HUBOT_ROCKETCHAT_USERNAME=$(cat ./docker-compose.yml|grep ROCKETCHAT_USER | awk -F = '{print $2}')
# export UTILISATEUR_HUBOT_ROCKETCHAT_PWD=$(cat ./docker-compose.yml|grep ROCKETCHAT_PASSWORD | awk -F = '{print $2}')

# Depuis l'utiliation du fichier de variables globales [.env]
export UTILISATEUR_HUBOT_ROCKETCHAT_USERNAME=$(cat ./.env|grep UTILISATEUR_ROCKETCHAT_HUBOT | grep -v MDP | awk -F = '{print $2}')
export UTILISATEUR_HUBOT_ROCKETCHAT_PWD=$(cat ./.env|grep UTILISATEUR_ROCKETCHAT_HUBOT_MDP | awk -F = '{print $2}')



# - Je rends exécutables les scripts invoqués dans la présente recette
chmod +x ./initialisation-iaac-cible-deploiement.sh
# J'initialise tout de suite la cible de déploiement
./initialisation-iaac-cible-deploiement.sh



echo "  "
echo " ---------------------------------------------------------------------- "
echo "  INIITALISATION IAAC TERMINEE : "
echo " ---------------------------------------------------------------------- "
echo "  "
docker images
echo "  "
echo " ---------------------------------------------------------------------- "
echo "  "
echo "  Pressez la touche entrée.  "
echo " ---------------------------------------------------------------------- "
echo "  "
read DEBUGJBL
clear

# - Je rends exéutable les fichiers de script utilisés dans les builds d'images Docker qui doivent l'être : 
chmod +x ./mongo-init-replica/construction/*
# - cf. ./mongodb/construction/Dockerfile 
chmod +x ./mongodb/construction/* 
chmod +x ./rocketchat/construction/* 
# chmod +x ./hubot-init-rocketcha/construction/* 
# - Je créée "tout"
# docker-compose down --rmi all && docker system prune -f && docker-compose build && docker-compose up -d 
# - Non: il y a un volume trop grand d'image téléchargées
docker-compose down && docker system prune -f && sudo rm -rf ./db/ && docker-compose up -d --build --force-recreate

# - 1 - Je dois relancer le conteneur qui créée et initialise le replicaSet mongoDB, dès que mongoDB est disponible :
# checkHealth $NOM_CONTENEUR_BDD_ROCKETCHAT
# docker start $NOM_CONTENEUR_INIT_REPLICASET_BDD_ROCKETCHAT

# - 2 - Maintenant que le replicaSet Existe, je peux re-démarrer le conteneur rocketchat : 
#       cela se fait tout seul, parce que rocketchat est en restart=always dans le dokcer-compose.yml
# docker-compose up -d $NOM_CONTENEUR_ROCKETCHAT
# sleep 3 && docker ps -a
# docker logs $NOM_CONTENEUR_ROCKETCHAT
# -->> À terme, je voudrais, au lieu de re-démarrer de force le service rocketchat, le laisser re-démarrer, et vérifier que
#      Rocket Chat est dans un état "Healthy", avant de créer manuellement le USER utilisé par le service HUBOT ensuite :
#           pour cela, il faudra donc faire un HEALTHCHECK rocketchat, et invoquer la focntion [checkHealth] de ce script : 
# 
#    checkHealth $NOM_CONTENEUR_ROCKETCHAT
# 
# 
# - 3 - Il faut manuellement créer l'utilisateur RocketChat mentionné dans la configuration du service 'hubot' dans le fichier docker-compose.yml : 


# - 4 - Maintenant que l'utilisateur dont le hubot a besoin existe, on re-démarre le hubot :

clear
echo "  "
echo " ---------------------------------------------------------------------- "
echo "  "
checkHealth $NOM_CONTENEUR_ROCKETCHAT
echo "  "
echo " ---------------------------------------------------------------------- "
echo "  "
echo " ---------------------------------------------------------------------- "
echo "   FIN de la provision Kytes  : "
echo " ---------------------------------------------------------------------- "
# echo "    - \"UTILISATEUR_HUBOT_ROCKETCHAT_USERNAME=$UTILISATEUR_HUBOT_ROCKETCHAT_USERNAME\" "
echo "  "
docker ps -a
echo "  "
docker images
echo "  "
echo "   Pressez la touche entrée pour terminer la provision, un checkhealth sera déclenché. "
echo " ---------------------------------------------------------------------- "
echo "  "
read ATTENTE_CREATION_UTILISATEUR_ROCKETCHAT

# - Maintenant, examinons les logs du conteneur hubot :

docker logs  kytes_gitlab_service -f 




