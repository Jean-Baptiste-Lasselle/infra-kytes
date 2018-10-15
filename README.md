# TODO du mataîng

https://github.com/Jean-Baptiste-Lasselle/infra-kytes/issues/4


# RUN: journal de bord

* à noter : 

Dans le run, j'ai constaté que la seule manière de tout relancer correctement étaient de tout détruire et re-construire, jusqu'au build des images, et ce avec sudo, pour pouvoir reprendre en main les répertoires mappés en tant que docker volumes : 
```bash
sudo docker-compose down --rmi all && docker-compose up -d --force-recreate
```

ceci n'est pas satisfaisant. Ceci st du au plongeur soudeur,  et il y a quelque chose de très intéressant à faire en terme de disnction entre la recette de provision, et les opérations standards de déploiemùent, ainsi que leur tests. C'est RocketChat et le healthcheck de mongoDB qui ont posé problème. repo historique des ops. repos des operatiosn standars. toutes les références des opérations standards .... chaque recette doit avoir une automatisation du logging des valeurs des arguments à l'invocation, de l'env, le whoami, les réréfrences vers n commit, sur N repos git, correspondant à N répertoires versionnés dans l'env d'exécution du soft (un conteneur).


# Garde manger pour backup restore


### Petit principe

Pour chaque nouvelle version `N+1` de logiciel, on doit faire : 
* une nouvelle version de la recette de backup
* une nouvelle version de la recette de restauration
* une recette de transformation des données, d'un backup valide version `N`, vers un backup valide version `N+1`. Un backup est valide pour une version  `K`, ssi la procédure de restauration de la version  `K` du logiciel, se déroule sans erreur, et sans perte de données ou de leur intégrité, sur la base de ce backup.
* une recette de transformation des données, d'un backup valide version `N+1`, vers un backup valide version `N`.
* toutes les recettes précédentes doivent êtrer idemtpotentes, et backup restore doivent être réciproques: exécutées successivement dasn n'importe quel ordre, elles constituent une opération idemtpotente.


Le fait d'écrire les recettes de transformation, à double sens, permet de versionner absoluement tout l'historique des opératiosn d'exploitation d'un `RUN`, et peremt de rendre possible le passage d'un état d'exploitation à un autre, quels qu'ils soient.




Fabrication du zip, dans l'hôte Docker (`./backup.sh`) : 
(ce script retourne le nom du fichier zip généré)

```bash
# export NOM_FICHIER_ZIP_PRODUIT=kytes-bckup-$(date --iso-8601=seconds).zip
export NOM_FICHIER_ZIP_PRODUIT=kytes-bckup-$(date '+%Y-%m-%dday_%Hh-%Mmin-%Ssec').zip
sudo yum install -y zip unzip
sudo zip -r $NOM_FICHIER_ZIP_PRODUIT ./gitlab ./db ./volumes && echo "$NOM_FICHIER_ZIP_PRODUIT" 
```

Pour exécuter depuis pmon poste de travail, le script distant : 
```bash
export MAISON_OPS=$HOME/running-kytes-backup-restore-ops
export URI_DE_CETTE_RECETTE=https://github.com/Jean-Baptiste-Lasselle/infra-kytes
export USER_LX_OPERATEUR_SERVEUR_DISTANT=jibl
export NOM_HOTE_RESEAU_SERVEUR_DISTANT=production-docker-host-1.kytes.io
export CHEMIN_MAISON_KYTES_DRP='/media/jibl/Seagate\ Slim\ Drive'
export CHEMIN_MAISON_KYTES_DRP="$CHEMIN_MAISON_KYTES_DRP/kytes-production-drp"

cd MAISON_OPS

git clone "$URI_DE_CETTE_RECETTE" . 
# attention, pour exécuter silencieusement la recette, il sera encore mieux de 
# coller, surle serveur distant, ma clé publique RSA dans les $HOME/jibl/.ssh/authorized_keys
# ssh $USER_LX_OPERATEUR_SERVEUR_DISTANT@$NOM_HOTE_RESEAU_SERVEUR_DISTANT "bash -s" -- < ./ex.bash "--time" "bye"
export NOM_FICHIER_ZIP_PRODUIT=$(ssh $USER_LX_OPERATEUR_SERVEUR_DISTANT@$NOM_HOTE_RESEAU_SERVEUR_DISTANT "bash -s" -- < ./backup.sh)

scp $USER_LX_OPERATEUR_SERVEUR_DISTANT@$NOM_HOTE_RESEAU_SERVEUR_DISTANT:/home/jibl/infra-kytes/$NOM_FICHIER_ZIP_PRODUIT ./$NOM_FICHIER_ZIP_PRODUIT

# Et il ne reste plus qu'à copier le zip obtenu dans le stockage physiquement distinct: backup restore de type (1,2)
echo "Je suis $(whoami), et je backup l'infra kytes vers "
cp -rf  /media/jibl/Seagate\ Slim\ Drive/kytes-production-drp

```


```bash
[jibl@pc-100 infra-kytes]$ pwd
/home/jibl/infra-kytes
[jibl@pc-100 infra-kytes]$ ls -all
total 170960
drwxrwxr-x. 12 jibl jibl      4096 Oct 15 21:37 .
drwx------.  7 jibl jibl      4096 Oct 15 21:54 ..
-rw-rw-r--.  1 jibl jibl       369 Oct  8 00:30 boot-repo.sh
drwxr-xr-x.  4 root root        30 Oct 13 12:48 db
-rw-rw-r--.  1 jibl jibl     10237 Oct 15 21:21 docker-compose.yml
drwxrwxr-x.  3 jibl jibl        20 Oct  8 00:30 documentation
-rw-rw-r--.  1 jibl jibl      3855 Oct  8 00:30 .env
drwxr-xr-x.  8 jibl jibl       220 Oct 15 21:25 .git
-rw-rw-r--.  1 jibl jibl       145 Oct  8 00:30 .gitignore
drwxrwxr-x.  6 jibl jibl        76 Oct 15 21:30 gitlab
-rwxrwxr-x.  1 jibl jibl      2328 Oct  8 00:30 initialisation-iaac-cible-deploiement.sh
-rw-r--r--.  1 root root 174957914 Oct 15 21:37 kytes-bckup-zero.zip
-rw-rw-r--.  1 jibl jibl     35141 Oct  8 00:30 LICENSE
drwxrwxr-x.  3 jibl jibl        26 Oct  8 00:30 mongodb
drwxrwxr-x.  3 jibl jibl        26 Oct  8 00:30 mongo-init-replica
drwxrwxr-x.  3 jibl jibl        60 Oct 14 20:00 nginx
-rwxrwxr-x.  1 jibl jibl      6511 Oct  8 00:30 operations.sh
-rwxrwxr-x.  1 jibl jibl      6534 Oct  8 00:30 operations-verbose.sh
-rw-rw-r--.  1 jibl jibl      9550 Oct 14 21:50 README.md
drwxrwxr-x.  4 jibl jibl        70 Oct 13 12:48 rocketchat
drwxrwxr-x.  3 jibl jibl        25 Oct  8 00:30 tests
drwxr-xr-x.  4 root root        35 Oct 13 12:48 volumes
[jibl@pc-100 infra-kytes]$ zip -T ./kytes-bckup-zero.zip 
test of ./kytes-bckup-zero.zip OK
[jibl@pc-100 infra-kytes]$ exit
logout
Connection to production-docker-host-1.kytes.io closed.
jibl@pc-alienware-jib:/media/jibl$ cd Seagate\ Slim\ Drive/
jibl@pc-alienware-jib:/media/jibl/Seagate Slim Drive$ cd kytes-production-drp/
jibl@pc-alienware-jib:/media/jibl/Seagate Slim Drive/kytes-production-drp$ scp jibl@production-docker-host-1.kytes.io:/home/jibl/infra-kytes/kytes-bckup-zero.zip ./kytes-bckup-zero.zip
jibl@production-docker-host-1.kytes.io's password: 
kytes-bckup-zero.zip                                                                                                                                                             100%  167MB  64.1MB/s   00:02    
jibl@pc-alienware-jib:/media/jibl/Seagate Slim Drive/kytes-production-drp$ ls -all
total 170872
drwxrwxrwx 1 jibl jibl       176 Oct 15 22:31 .
drwxrwxrwx 1 jibl jibl     12288 Oct 15 21:59 ..
-rwxrwxrwx 1 jibl jibl 174957914 Oct 15 22:31 kytes-bckup-zero.zip
jibl@pc-alienware-jib:/media/jibl/Seagate Slim Drive/kytes-production-drp$ zip -T ./kytes-bckup-zero.zip
test of ./kytes-bckup-zero.zip OK
jibl@pc-alienware-jib:/media/jibl/Seagate Slim Drive/kytes-production-drp$ 
```
Le test du résultat de la décompression : 

```bash
[jibl@pc-100 TESTunzip]$ pwd
/home/jibl/TESTunzip
[jibl@pc-100 TESTunzip]$ unzip ./kytes-bckup-zero.zip 
# [...]: J'ai retiré la sortie console du processus d'exécution de l'exécutable unzip
jibl@pc-100 TESTunzip]$ ls -all
total 170864
drwxrwxr-x. 5 jibl jibl        73 Oct 15 22:46 .
drwx------. 8 jibl jibl      4096 Oct 15 22:45 ..
drwxr-xr-x. 4 jibl jibl        30 Oct 13 12:48 db
drwxrwxr-x. 6 jibl jibl        76 Oct 15 21:30 gitlab
-rw-r--r--. 1 jibl jibl 174957914 Oct 15 22:45 kytes-bckup-zero.zip
drwxr-xr-x. 4 jibl jibl        35 Oct 13 12:48 volumes
[jibl@pc-100 TESTunzip]$ 
```
bckup côté poste de travail : 
```bash
jibl@pc-alienware-jib:/media/jibl/Seagate Slim Drive/kytes-production-drp$ pwd
/media/jibl/Seagate Slim Drive/kytes-production-drp
jibl@pc-alienware-jib:/media/jibl/Seagate Slim Drive/kytes-production-drp$ ls -all /media/jibl/Seagate\ Slim\ Drive/kytes-production-drp
total 352760
drwxrwxrwx 1 jibl jibl       344 Oct 15 23:54 .
drwxrwxrwx 1 jibl jibl     12288 Oct 15 21:59 ..
-rwxrwxrwx 1 jibl jibl 186249884 Oct 15 23:54 kytes-bckup-2018-10-15T23:49:19+0200.zip
-rwxrwxrwx 1 jibl jibl 174957914 Oct 15 22:31 kytes-bckup-zero.zip
jibl@pc-alienware-jib:/media/jibl/Seagate Slim Drive/kytes-production-drp$ 

jibl@pc-alienware-jib:/media/jibl/Seagate Slim Drive/kytes-production-drp$ scp jibl@production-docker-host-1.kytes.io:/home/jibl/maison-temp-kytes-bckup/*.zip ./
jibl@production-docker-host-1.kytes.io's password: 
kytes-bckup-2018-10-15T23:49:19+0200.zip                                                                                                                                         100%  178MB  46.4MB/s   00:03    
jibl@pc-alienware-jib:/media/jibl/Seagate Slim Drive/kytes-production-drp$ zip -T ./kytes-bckup-2018-10-15T23\:49\:19+0200.zip 
test of ./kytes-bckup-2018-10-15T23:49:19+0200.zip OK
jibl@pc-alienware-jib:/media/jibl/Seagate Slim Drive/kytes-production-drp$ ls -all
total 352760
drwxrwxrwx 1 jibl jibl       344 Oct 15 23:54 .
drwxrwxrwx 1 jibl jibl     12288 Oct 15 21:59 ..
-rwxrwxrwx 1 jibl jibl 186249884 Oct 15 23:54 kytes-bckup-2018-10-15T23:49:19+0200.zip
-rwxrwxrwx 1 jibl jibl 174957914 Oct 15 22:31 kytes-bckup-zero.zip
jibl@pc-alienware-jib:/media/jibl/Seagate Slim Drive/kytes-production-drp$ 
```

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



