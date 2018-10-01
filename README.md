# Principe

Ce repo versionne la recette de provision de l'infrastrcuture interne Kytes.

Gitlab CE

TODOs: 
* ajouter la provision LetsEncrypt avec une intégration pour le HTTPS Gitlab, avc un conteneur Lets Encrypt seul (pas dans Free IPA Server). Ajouter dans la documentation le cycle de gestion de l'autorité de certification.
* ajouter la provision serveur DNS, avec intégration 


# Utilisation

## Provision et Initialisation du cycle IAAC

Pour exécuter cette recette une première fois : 

```bash
export PROVISIONING_HOME=$HOME/infra-kytes
mkdir -p $PROVISIONING_HOME
cd $PROVISIONING_HOME
git clone "https://github.com/Jean-Baptiste-Lasselle/infra-kytes " . 
chmod +x ./operations.sh
./operations.sh
```
Soit, en une seule ligne : 

```bash
export PROVISIONING_HOME=$HOME/infra-kytes && mkdir -p $PROVISIONING_HOME && cd $PROVISIONING_HOME && git clone "https://github.com/Jean-Baptiste-Lasselle/infra-kytes " . && chmod +x ./operations.sh && ./operations.sh
```
Toujours en une seule ligne, mais en mode verbeux : 

```bash
export PROVISIONING_HOME=$HOME/infra-kytes && mkdir -p $PROVISIONING_HOME && cd $PROVISIONING_HOME && git clone "https://github.com/Jean-Baptiste-Lasselle/infra-kytes " . && chmod +x ./operations-verbose.sh && ./operations-verbose.sh
```


### Configuration de la recette de provision : le fichier “.env”

La provision de cette infrastructure est configurable à l'aide du fichier ".env" présent à la racine de ce repo.
Les variables d'environnement utilisables sont :


| Variable                              | Configure                                                                           |
|---------------------------------------|-------------------------------------------------------------------------------------|
| `USERNAME_UTILISATEUR_ADMIN_INITIAL`  | Le username du premier utilsiateur admin initial                                    |
| `MDP_UTILISATEUR_ADMIN_INITIAL`       | Le secret du premier utilsiateur admin initial (un mot de passe, ou un "token"...)  |
| `EMAIL_UTILISATEUR_ADMIN_INITIAL`     | L'adresse email du premier utilsiateur admin initial                                |
| `ADRESSE_IP_SERVEUR_DNS`              | L'adresse IP du servveur DNS de l'infrastructure Kytes                              |
| `GITLAB_CE_VERSION`                   | La version de Gitlab CE utilisée                                                    |
| `POSTGRES_VERSION`                    | La version de PostGReSQL utilisée pour la BDD de Gitlab                             |
| `REDIS_VERSION`                       | La version de Redis utilisée pour la BDD de Gitlab                                  |
| `NOM_DU_RESEAU_INFRA_DOCKER`          | Le nom du réseau DOcker Bridge, dans la cible de déploiement Hôte Docker            |
| `GITLAB_HOST`                | La valeur qui sera donnée à la variable d'environnement `GITLAB_HOST`du conteneur Gitlab    |
| `GITLAB_SSH_IP`              | L'adresse IP par laquelle le serveur  Gitlab sera accessible par SSH, depuis l'extérieur    |
| `GITLAB_SSH_PORT`            | Le numéro de port par lequel le serveur Gitlab sera accessible par SSH, depuis l'extérieur  |
| `GITLAB_HTTP_IP`             | L'adresse IP par laquelle le serveur Gitlab sera accessible par HTTP, depuis l'extérieur    |
| `GITLAB_HTTP_PORT`           | Le numéro de port par lequel le serveur Gitlab sera accessible par HTTP, depuis l'extérieur |
| `GITLAB_HTTPS_IP`            | L'adresse IP par laquelle le serveur Gitlab sera accessible par HTTPS, depuis l'extérieur   |
| `GITLAB_HTTPS_PORT`          | Le numéro de port par lequel le serveur Gitlab sera accessible par HTTPS, depuis l'extérieur |
| `TZ`                         | La "Time Zone" qui sera utilisée par l'instance Gitlab, exemple `TZ=Europe/Paris`           |
| `LETSENCRYPT_EMAIL`          | L'adresse email qui sera utilisée pour l'intégration LetsEncrypt    |
| `VERSION_IMAGE_FREE_IPA_SERVER`        | La version de l'image docker FREE IPA SERVER utilisée    |
| `VERSION_IMAGE_LETSENCRYPT`        | La version de l'image docker LETSENCRYPT utilisée    |
| `VERSION_IMAGE_NGINX`        | La version de l'image docker NGINX utilisée    |


*Rappel, à propos du fichier `.env` Docker*

Attention,un piège existe quant à ces variables d'environnement, et leur interpolation : 

Lorsque vous précisez une valeur de variable d'environnement dans le `./docker-compose.yml` (ou un `Dockerfile`), et que : 
  * Dans votre `docker-compose.yml`, vous avez le contenu : 
  ```yaml
    rocketchat:
      container_name: "$NOM_CONTENEUR_ROCKETCHAT"
      image: coquelicot/rocket.chat:1.0.0
      build: 
        context: ./rocketchat/construction/
        args:
          - UNEVARIABLE_ENV_ROCKETCHAT_PAR_EXEMPLE="$VALEUR_UNEVARIABLE"
  ```
  * Dans votre `./.env`, vous avez le contenu : 
  ```yaml
  UNEVARIABLE=bernard
  ```
  Alors, la valeur envoyée sera `"bernard"`, et non la valeur `bernard` !!! (ce qui m'a causé quelques soucis pour passer
  certaines valeurs, comme des mots de passes, et des logs RocketCHat dont la gestion semble largement améliorable !
  (ne serait qu'en pensant aux pauvres architectes / devops, qui font un `docker logs rockerchat` .... :100:)


## Cycle IAAC : Idempotence

Lorsque vous aurez exécuté une première fois l'instruction en une ligne ci-dessus, vous pourrez faire un cycle IAAC, sans re-télécharger d'image extérieures, en reconstruisant toutes les images qui ne sont pas téléchargées, avec : 

```bash
export PROVISIONING_HOME=$HOME/infra-kytes && cd $PROVISIONING_HOME && docker-compose down && cd .. && sudo rm -rf $PROVISIONING_HOME && mkdir -p $PROVISIONING_HOME && cd $PROVISIONING_HOME && git clone "https://github.com/Jean-Baptiste-Lasselle/infra-kytes" . && chmod +x ./operations.sh && ./operations.sh
``` 
La commande ci-dessus, modulo la première exécution de cette recette exécutée, est idempotente





