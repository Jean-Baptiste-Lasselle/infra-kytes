# Warning to the reader

Since I tagged this repo, users may expect communication from me.

My work here (writing this on October, the 30th of October, 2018) is notfinished, and I will bring a neat boilerplate by Xmas Eve. 

That  first usable version will be released as [3.0.0-xmas]. I will consider authorizing branchning this repo by other architects/devops/developers, only after that 3.0.0-xmas release.


Any previous release is just for my personal project management automation. (I have in house 24 U stack + 2 zero-U PDUs )

I wil  never provide ansible / terraform recipe for that repo : those are things company will have to pay, to get.

You may request my services, by submitting an issue with a github account, I will then find you, you don't need to write any email contact or phone number. Don't be shy about asking me if I would fly 11 000 miles to work op a project: I will, especially I f don' understand a word of your native language.

All in all, 3.0.0-xmas release will provide you a way to say f*** u to microsoft buying github.com, and you will find out how then, but for now, consider :

* This repo is a boilerplate I use to manufacture consistent business processes for production management of an infrastrutucture.
* This boilerplate infrastructure includes Gitlab Rocketchat, for the time being
* This boiler plate has 1/2/3 backup capabilites : as long as you have got enough money to buy 2 external hard drive, then you 'll have a proper 1/2/3



If you see anything written in French, just don't pay atention. You may, but be informed that I use french to mislead my business conccurent, and what you see in mess here, is in mess on purpose. Indeed, as any social network, Github is massively used to gather intel about IT professionals. Massive doesn't mean bad. Massive means there has to be mean stuff around, it's  a statistical fact. Just as if you would pick a random person in the street. Just some words some Executive Directors hear from me, and ask me further explanantions, studies, IT stategy consultancy, zlong with the usual source code/build artefacts/apps.


Sit back, have some fine French Cheese, and see you on christmas :)

Thank you for reading me,


> I heard Linus Torvalds say Linux is nothing, compared to Git.
> 
> And I agree with him. 
> 
> _J.B. Lasselle_




# TODO du mataîngLancer l'évolution FRee IPA sver pour  :
* gestion serveurs Autroités de Certification, et gestion des certificat SSL
* gestion des serveurs de nom de domaine
* gestion du bootstrap de la gestion d'identité des humains

Eténdre Free IPA pour la gestion de l'inventaire matériel, sans automatisation de la gestion du réseau d'alimentation électrique, kje m'arrête au niveau Wake ON LAN.


# Principe

https://slackmojis.com/

Ce repo versionne la recette de provision de l'infrastrcuture interne Kytes.

Gitlab CE

TODOs: 
* Ajouter la provision LetsEncrypt avec une intégration pour le HTTPS Gitlab, avec un conteneur Lets Encrypt seul (Lets Encrypt hors Free IPA server). 
* Ajouter dans cette documentation le cycle de gestion de l'autorité de certification (Lets Encrypt hors Free IPA server).

* Ajouter la provision serveur DNS, avec intégration pour cohérence avec la configuration NGINX (serveur DNS hors Free IPA server)
* Ajouter dans cette documentation le cycle de gestion du serveur DNS (serveur DNS hors Free IPA server).

* Changer cette recette pour qu'elle utilise le serveur DNS et le Lets Encrypt compris dans Free IPA server, au lieu du letsencrypt et du serveur DNS standalone utilisés précédemment.

* Ajouter dans cette documentation le cycle de gestion de l'autorité de certification Lets Encrypt incluse dans Free IPA server.
* Ajouter dans cette documentation le cycle de gestion du serveur DNS inclut dans Free IPA server.

* Ajouter une automatisation des opérations Backup / Restore :
  * un script `./backup.sh` : il prendra en argument, un chemin, le chemin du répertoire dans lequel le zip des fichiers de backup est conservé. le zip contient:
    - le fichier `.env`,
    - un fichier ".history", qui contient:  au moment du backup, la date, l'heure à la seconde, et l'ID de la machine cible de déploiement (permettra de retrouver  une référence vers le repository Git histprique des oéprations de ladite machine, et le commit id du plus récent commit avant le backup).  
  * un script `./restore.sh` :  celui-là est secret.
  
 
# Dépendances des variables de configuration

Quelquies dépendances, qui nécessitent une templatisation Jinja 2 / Ansible : 

* Le numéro de port interne au conteneur docker nginx, déclaré dans le `./docker-compose.yml` : 
  * pour le conteneur gitlab : doit être égal au numéro de port spécifié pour la directive `listen` dans le fichier `./infra-kytes/nginx/gitlab.conf`.
  * pour le conteneur rocketchat : doit être égal au numéro de port spécifié pour la directive `listen` dans le fichier `./infra-kytes/nginx/rocketchat.conf`.
* Le numéro de port interne au conteneur gitlab, déclaré dans le `./docker-compose.yml`, pour s'interfacer au nginx interne au conteneur gitlab : 
  * est configuré dans le `./docker-compose.yml`, via le fichier `./.env`, et la varible d'environnement `GITLAB_HTTP_PORT_VIA_NGINX_INTERNE_GITLAB`.
  * doit être égal au numéro de port spécifié dans le `./infra-kytes/nginx/gitlab.conf`, pour la directive `proxy_pass`

* Le numéro de port interne au conteneur rocketchat, déclaré dans le `./docker-compose.yml`, pour s'interfacer au nginx interne au conteneur gitlab : 
  * est configuré dans le `./docker-compose.yml`, via le fichier `./.env`, et la variable d'environnement `NUMERO_PORT_ECOUTE_ROCKETCHAT`. La variable d'environnement `PORT=$NUMERO_PORT_ECOUTE_ROCKETCHAT`, propre à la distribution de l'image docker rocketchat, est utilisée pour cette configuration, cf. la section `environment: ` de la configuration du service `rockerchat`, dans le `./docker-compose.yml`.
  * doit être égal au numéro de port spécifié dans le `./infra-kytes/nginx/rocketchat.conf`, pour la directive `proxy_pass`
* Les noms d'hôtes réseau docker utilisés dans les configurations reverse proxy, doivent correspondre aux décalrations `container_name`, dans le fichier `./docker-compose.yml`, pour les conteneurs respectifs.


# Utilisation

## Provision et Initialisation du cycle IAAC

Pour exécuter cette recette une première fois : 

```bash
export PROVISIONING_HOME=$HOME/infra-kytes
mkdir -p $PROVISIONING_HOME
cd $PROVISIONING_HOME
git clone "https://github.com/Jean-Baptiste-Lasselle/infra-kytes" . 
chmod +x ./operations.sh
./operations.sh
```
Soit, en une seule ligne : 

```bash
export PROVISIONING_HOME=$HOME/infra-kytes && mkdir -p $PROVISIONING_HOME && cd $PROVISIONING_HOME && git clone "https://github.com/Jean-Baptiste-Lasselle/infra-kytes" . && chmod +x ./operations.sh && ./operations.sh
```
Toujours en une seule ligne, mais en mode verbeux : 

```bash
export PROVISIONING_HOME=$HOME/infra-kytes && mkdir -p $PROVISIONING_HOME && cd $PROVISIONING_HOME && git clone "https://github.com/Jean-Baptiste-Lasselle/infra-kytes" . && chmod +x ./operations-verbose.sh && ./operations-verbose.sh
```


### Configuration de la recette de provision : le fichier “.env”

La provision de cette infrastructure est configurable à l'aide du fichier ".env" présent à la racine de ce repo.
Pour l'ensemble de ces variables, le tableau ci-dessous explicite le rôle de chacune, il est à noter que la notion d'utilisateur intiial Kytes, correspond à la notion d'administrateur de l'infrastructure Kytes.

Les variables d'environnement utilisables sont :


| Variable                              | Configure                                                                           |
|---------------------------------------|-------------------------------------------------------------------------------------|
| `KYTES_USERNAME_UTILISATEUR_ADMIN_INITIAL`  | Le username du premier utilsiateur admin initial                              |
| `KYTES_MDP_UTILISATEUR_ADMIN_INITIAL`       | Le secret du premier utilisateur admin initial                                |
|                                       | ( "secret" :un mot de passe, ou un "token"...)                                      |
| `KYTES_EMAIL_UTILISATEUR_ADMIN_INITIAL`     | L'adresse email du premier utilsiateur admin initial                          |
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
| `TZ`                         | La "Time Zone" qui sera utilisée par l'instance Gitlab, exemple `TZ=Europe/Paris` . Des tests pour l'intégration à la configuration NTP dans l'OS de l'hôte Docker sous jacent, sont à faire.         |
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
  certaines valeurs, comme des mots de passes ....)
  


## Cycle IAAC : Idempotence

Lorsque vous aurez exécuté une première fois l'instruction en une ligne ci-dessus, vous pourrez faire un cycle IAAC, sans re-télécharger d'image extérieures, en reconstruisant toutes les images qui ne sont pas téléchargées, avec : 

```bash
export PROVISIONING_HOME=$HOME/infra-kytes && cd $PROVISIONING_HOME && docker-compose down && cd .. && sudo rm -rf $PROVISIONING_HOME && mkdir -p $PROVISIONING_HOME && cd $PROVISIONING_HOME && git clone "https://github.com/Jean-Baptiste-Lasselle/infra-kytes" . && chmod +x ./operations.sh && ./operations.sh
``` 
La commande ci-dessus, modulo la première exécution de cette recette exécutée, est idempotente


## Inventaire des noms de domaines

```bash
# Infra Kytes
192.168.1.30    rocketchat.kytes.io
192.168.1.30    gitlab.kytes.io
# Hôte Docker, VM constituant l'infrastructure de déploiement.
192.168.1.30    production-docker-host-1.kytes.io
```


# RUN: journal de bord

* à noter : 

Dans le run, j'ai constaté que la seule manière de tout relancer correctement étaient de tout détruire et re-construire, jusqu'au build des images, et ce avec sudo, pour pouvoir reprendre en main les répertoires mappés en tant que docker volumes : 
```bash
sudo docker-compose down --rmi all && docker-compose up -d --force-recreate
```

ceci n'est pas satisfaisant. Ceci st du au plongeur soudeur,  et il y a quelque chose de très intéressant à faire en terme de disnction entre la recette de provision, et les opérations standards de déploiemùent, ainsi que leur tests. C'est RocketChat et le healthcheck de mongoDB qui ont posé problème. repo historique des ops. repos des operatiosn standars. toutes les références des opérations standards .... chaque recette doit avoir une automatisation du logging des valeurs des arguments à l'invocation, de l'env, le whoami, les réréfrences vers n commit, sur N repos git, correspondant à N répertoires versionnés dans l'env d'exécution du soft (un conteneur).



