# Principe

Ce repository Git vis à faire évoluer la recette du repo : 

https://github.com/RocketChat/Chat.Code.Ship

Afin:
* de faire en sorte qu'elle fonctionne dans n'importe quel hôte docker ayant accès au registry docker public officiel docker.io
* de faire en sorte qu'elle soit en version docker-compose 3, au lieu de la version 2.
* de la fair eévoluer, pour qu'elle peremette un calcul des SLA, et un déploiment Kubernetes, le service mpongo DB étant automatiquement "scalé" par le scale-up Kuibernetes, en cohérence avec le recplicaset créé pour rocketchat, mentionné dans la configuration du service rocketchat.

# Utilisation


```bash
export PROVISIONING_HOME=$(pwd)/coquelicot
mkdir -p $PROVISIONING_HOME
cd $PROVISIONING_HOME
git clone "https://github.com/Jean-Baptiste-Lasselle/coquelicot" . 
chmod +x ./operations.sh
./operations.sh
```
Ou en une seule ligne : 

```bash
export PROVISIONING_HOME=$(pwd)/coquelicot && mkdir -p $PROVISIONING_HOME && cd $PROVISIONING_HOME && git clone "https://github.com/Jean-Baptiste-Lasselle/coquelicot" . && chmod +x ./operations.sh && ./operations.sh
```
Lorsque vous exécuterez ces commandes, vous serez guidé, dans la provision, interactivement : 
* La recette s'exécutera
* Il vous sera demandé de crééer un utilisateur rocketchat, qui devra correspondre à celui spécifié dans le `./docker-compose.yml`, avec les deux variables d'environnement `ROCKETCHAT_USER` et `ROCKETCHAT_PASSWORD` (cf. définition du conteneur `hubot`)
* Vous presserez la touche entrée
* La recette se terminera, et vous pourrez constater la sortie log suivante, et attestant du succès de la connexion du HUBOT dans le serveur RocketChat : 

```bash
npm info install hubot-rocketchat@1.0.11
npm info postinstall hubot-rocketchat@1.0.11
npm info install rocketbot@0.0.0
npm info postinstall rocketbot@0.0.0
npm info prepublish rocketbot@0.0.0
npm info ok 
[Fri Aug 17 2018 12:10:56 GMT+0000 (UTC)] INFO Starting Rocketchat adapter version 1.0.11...
[Fri Aug 17 2018 12:10:56 GMT+0000 (UTC)] INFO Once connected to rooms I will respond to the name: jblrocks
[Fri Aug 17 2018 12:10:56 GMT+0000 (UTC)] INFO I will also respond to my Rocket.Chat username as an alias: jbl
[Fri Aug 17 2018 12:10:56 GMT+0000 (UTC)] INFO Connecting To: rocketchat:3000
[Fri Aug 17 2018 12:10:56 GMT+0000 (UTC)] INFO Successfully connected!
[Fri Aug 17 2018 12:10:56 GMT+0000 (UTC)] INFO 
[Fri Aug 17 2018 12:10:56 GMT+0000 (UTC)] INFO Logging In
[Fri Aug 17 2018 12:10:56 GMT+0000 (UTC)] INFO Successfully Logged In
[Fri Aug 17 2018 12:10:56 GMT+0000 (UTC)] INFO rid:  []
[Fri Aug 17 2018 12:10:56 GMT+0000 (UTC)] INFO All rooms joined.
[Fri Aug 17 2018 12:10:56 GMT+0000 (UTC)] INFO Preparing Meteor Subscriptions..
[Fri Aug 17 2018 12:10:56 GMT+0000 (UTC)] INFO Subscribing to Room: __my_messages__
[Fri Aug 17 2018 12:10:56 GMT+0000 (UTC)] INFO Successfully subscribed to messages
[Fri Aug 17 2018 12:10:56 GMT+0000 (UTC)] INFO Setting up reactive message list...
[Fri Aug 17 2018 12:10:56 GMT+0000 (UTC)] WARNING Expected /home/hubot/scripts/package to assign a function to module.exports, got object
[Fri Aug 17 2018 12:10:56 GMT+0000 (UTC)] WARNING Loading scripts from hubot-scripts.json is deprecated and will be removed in 3.0 (https://github.com/github/hubot-scripts/issues/1113) in favor of packages for each script.

Your hubot-scripts.json is empty, so you just need to remove it.
```

Seul manque de ce repo Git : 

*  Il reste à appliquer les instructions en fin de cette page, pour customiser les webhooks Gitlab. Pour ce faire, je vais donc utiliser l'inteface graphique web de rocketchat, pour aller à l'admin et créer un "incoming webhook", et ce en utilisant le script suivant : 
```javascript
/* eslint no-console:0, max-len:0 */
// see https://gitlab.com/help/web_hooks/web_hooks for full json posted by GitLab
const NOTIF_COLOR = '#6498CC';
const refParser = (ref) => ref.replace(/^refs\/(?:tags|heads)\/(.+)$/, '$1');
const displayName = (name) => name.toLowerCase().replace(/\s+/g, '.');
const atName = (user) => (user && user.name ? '@' + displayName(user.name) : '');
const makeAttachment = (author, text) => {
	return {
		author_name: author ? displayName(author.name) : '',
		author_icon: author ? author.avatar_url : '',
		text,
		color: NOTIF_COLOR
	};
};
const pushUniq = (array, val) => ~array.indexOf(val) || array.push(val); // eslint-disable-line

class Script { // eslint-disable-line
	process_incoming_request({ request }) {
		try {
			let result = null;
			const channel = request.url.query.channel;
			switch (request.headers['x-gitlab-event']) {
				case 'Push Hook':
					result = this.pushEvent(request.content);
					break;
				case 'Merge Request Hook':
					result = this.mergeRequestEvent(request.content);
					break;
				case 'Note Hook':
					result = this.commentEvent(request.content);
					break;
				case 'Issue Hook':
					result = this.issueEvent(request.content);
					break;
				case 'Tag Push Hook':
					result = this.tagEvent(request.content);
					break;
        case 'Pipeline Hook':
					result = this.pipelineEvent(request.content);
					break;
			}
			if (result && result.content && channel) {
				result.content.channel = '#' + channel;
			}
			return result;
		} catch (e) {
			console.log('gitlabevent error', e);
			return {
				error: {
					success: false,
					message: e.message || e
				}
			};
		}
	}

	issueEvent(data) {
		return {
			content: {
				username: 'gitlab/' + data.project.name,
				icon_url: data.project.avatar_url || data.user.avatar_url || '',
				text: (data.assignee && data.assignee.name !== data.user.name) ? atName(data.assignee) : '',
				attachments: [
					makeAttachment(
						data.user,
						`, selon coquelicot-jbl, ${data.object_attributes.state} an issue _${data.object_attributes.title}_ on ${data.project.name}.
*Description:* ${data.object_attributes.description}.
See: ${data.object_attributes.url}`
					)
				]
			}
		};
	}

	commentEvent(data) {
		const comment = data.object_attributes;
		const user = data.user;
		const at = [];
		let text;
		if (data.merge_request) {
			const mr = data.merge_request;
			const lastCommitAuthor = mr.last_commit && mr.last_commit.author;
			if (mr.assignee && mr.assignee.name !== user.name) {
				at.push(atName(mr.assignee));
			}
			if (lastCommitAuthor && lastCommitAuthor.name !== user.name) {
				pushUniq(at, atName(lastCommitAuthor));
			}
			text = `coquelicot-jbl: commented on MR [#${mr.id} ${mr.title}](${comment.url})`;
		} else if (data.commit) {
			const commit = data.commit;
			const message = commit.message.replace(/\n[^\s\S]+/, '...').replace(/\n$/, '');
			if (commit.author && commit.author.name !== user.name) {
				at.push(atName(commit.author));
			}
			text = `coquelicot-jbl: commented on commit [${commit.id.slice(0, 8)} ${message}](${comment.url})`;
		} else if (data.issue) {
			const issue = data.issue;
			text = `coquelicot-jbl: commented on issue [#${issue.id} ${issue.title}](${comment.url})`;
		} else if (data.snippet) {
			const snippet = data.snippet;
			text = `coquelicot-jbl: commented on code snippet [#${snippet.id} ${snippet.title}](${comment.url})`;
		}
		return {
			content: {
				username: 'gitlab/' + data.project.name,
				icon_url: data.project.avatar_url || user.avatar_url || '',
				text: at.join(' '),
				attachments: [
					makeAttachment(user, `${text}\n${comment.note}`)
				]
			}
		};
	}

	mergeRequestEvent(data) {
		const user = data.user;
		const mr = data.object_attributes;
		const assignee = mr.assignee;
		let at = [];

		if (mr.action === 'open' && assignee) {
			at = '\n' + atName(assignee);
		} else if (mr.action === 'merge') {
			const lastCommitAuthor = mr.last_commit && mr.last_commit.author;
			if (assignee && assignee.name !== user.name) {
				at.push(atName(assignee));
			}
			if (lastCommitAuthor && lastCommitAuthor.name !== user.name) {
				pushUniq(at, atName(lastCommitAuthor));
			}
		}
		return {
			content: {
				username: `gitlab/${mr.target.name}`,
				icon_url: mr.target.avatar_url || mr.source.avatar_url || user.avatar_url || '',
				text: at.join(' '),
				attachments: [
					makeAttachment(user, `${mr.action} MR [#${mr.iid} ${mr.title}](${mr.url})\n${mr.source_branch} into ${mr.target_branch}`)
				]
			}
		};
	}

	pushEvent(data) {
		const project = data.project;
		const user = {
			name: data.user_name,
			avatar_url: data.user_avatar
		};
		// branch removal
		if (data.checkout_sha === null && !data.commits.length) {
			return {
				content: {
					username: `gitlab/${project.name}`,
					icon_url: project.avatar_url || data.user_avatar || '',
					attachments: [
						makeAttachment(user, `removed branch ${refParser(data.ref)} from [${project.name}](${project.web_url})`)
					]
				}
			};
		}
		// new branch
		if (data.before == 0) { // eslint-disable-line
			return {
				content: {
					username: `gitlab/${project.name}`,
					icon_url: project.avatar_url || data.user_avatar || '',
					attachments: [
						makeAttachment(user, `pushed new branch [${refParser(data.ref)}](${project.web_url}/commits/${refParser(data.ref)}) to [${project.name}](${project.web_url}), which is ${data.total_commits_count} commits ahead of master`)
					]
				}
			};
		}
		return {
			content: {
				username: `gitlab/${project.name}`,
				icon_url: project.avatar_url || data.user_avatar || '',
				attachments: [
					makeAttachment(user, `, selon coquelicot-jbl,  a poussé (pushed) ${data.total_commits_count} commits to branch [${refParser(data.ref)}](${project.web_url}/commits/${refParser(data.ref)}) in [${project.name}](${project.web_url})`),
					{
						text: data.commits.map((commit) => `  - ${new Date(commit.timestamp).toUTCString()} [${commit.id.slice(0, 8)}](${commit.url}) by ${commit.author.name}: ${commit.message.replace(/\s*$/, '')}`).join('\n'),
						color: NOTIF_COLOR
					}
				]
			}
		};
	}

	tagEvent(data) {
		const tag = refParser(data.ref);
		return {
			content: {
				username: `gitlab/${data.project.name}`,
				icon_url: data.project.avatar_url || data.user_avatar || '',
				text: '@all',
				attachments: [
					makeAttachment(
						{ name: data.user_name, avatar_url: data.user_avatar },
						`push tag [${tag} ${data.checkout_sha.slice(0, 8)}](${data.project.web_url}/tags/${tag})`
					)
				]
			}
		};
	}

  pipelineEvent(data) {
		const status = data.object_attributes.status;
		const link = data.project.web_url

		return {
			content: {
				username: `gitlab/${data.project.name}`,
				icon_url: data.project.avatar_url || data.user.avatar_url || '',
				text: 'Pipeline Active:',
				attachments: [
					makeAttachment(
						{ name: data.user.name, avatar_url: data.user.avatar_url },
						`, selon coquelicot-jb, Runned a Pipeline with status: ${data.object_attributes.status} [${data.object_attributes.duration}s] (${data.project.web_url}/pipelines)`
					)
				]
			}
		};
	}
}
```
Qui est une simple petite modification du script donné en fin de cette docuementation. Cette modification permet de définir des messages particuliers qui seront rapidement reconnaissables, quand postés par le `hubot`. La création du webhook entrant, devra être configurée par rapport à un canal rocketchat qui doit avoir été préalablement créé (par n'importe quel autre utilisateur, par forcément l'adminsitrateur qui créée le webhook). Enfin, Gitlab devra marcher, et un repo git devra y être créé, pour être ensuite utilsié, et arrvier à déclencher mon hubot sur le raocketchat.

Finalement, LEs Jenkins pipelines utiliseront aussi leur propre HUBOT pour poster des messages aux dévelopepurs par exemple.


Améliorations : 
* Utiliser un HEALTHCHECK RocketChat, pour faire patienter le processus bash qui terminera ensuite en re-démarrant le service
* Trouver le moyent de faire focntionner les depends_on avec les HEALTHCHECK de chaque conteneur. Y compris le contneur qui initialise le replicaset : Quand il a terminé son travail, alors seulement l'instance applicative RocketChat peut démarrer.



### Plus en détails

Pour tout détruire et nettoyer : 

```bash
docker-compose down --rmi all && docker system prune -f
```

Pour débogguer cette recette :

```bash
export PROVISIONING_HOME=$(pwd)/coquelicot && mkdir -p $PROVISIONING_HOME && cd $PROVISIONING_HOME && git clone "https://github.com/Jean-Baptiste-Lasselle/coquelicot" . && chmod +x ./operations-verbose.sh && ./operations-verbose.sh
```
Ou : 
```bash
docker-compose down --rmi all && docker system prune -f && docker-compose --verbose build && docker-compose --verbose up -d && sleep 10 && docker ps -a
```

Pour inspecter les logs d'exécution de chaque conteneur : 
```bash
export NOM_DU_CONTENEUR=gitlab
export NOM_DU_CONTENEUR=mongo
export NOM_DU_CONTENEUR=mongo-init-replica
export NOM_DU_CONTENEUR=rocketchat
export NOM_DU_CONTENEUR=hubot


docker logs $NOM_DU_CONTENEUR
```
Pour testerla connectivité entre deux conteneurs, cette recette met à disposition un service 'sondereseau', que l'on peut utiliser de la manière suivante :
```bash
# - lien entre les conteneurs 'gitlab' et 'rocketchat'
export NOM_DU_CONTENEUR1=gitlab
export NOM_DU_CONTENEUR2=rocketchat
# - lien entre les conteneurs 'mongo-init-replica' et 'mongo'
export NOM_DU_CONTENEUR1=mongo-init-replica
export NOM_DU_CONTENEUR2=mongo
# - lien entre les conteneurs 'rocketchat' et 'mongo'
export NOM_DU_CONTENEUR1=rocketchat
export NOM_DU_CONTENEUR2=mongo
# - lien entre les conteneurs 'rocketchat' et 'hubot'
export NOM_DU_CONTENEUR2=rocketchat
export NOM_DU_CONTENEUR1=hubot

# - on installe l'utilitaire linux 'ping' dans les conteneurs à tester : 

# - Vérifier les OS dans chaque conteneur ... :  
docker exec -it $NOM_DU_CONTENEUR1 bash -c "apt-get update -y && apt-get install -y iputils-ping && ping -c 4 localhost"
docker exec -it $NOM_DU_CONTENEUR1 bash -c "yum update -y && yum install -y iputils && ping -c 4 localhost"
docker exec -it $NOM_DU_CONTENEUR1 bash -c "apk update -y && apk add -y iputils-ping && ping -c 4 localhost"

docker exec -it $NOM_DU_CONTENEUR2 bash -c "apt-get update -y && apt-get install -y iputils-ping && ping -c 4 localhost"
docker exec -it $NOM_DU_CONTENEUR2 bash -c "yum update -y && yum install -y iputils && ping -c 4 localhost"
docker exec -it $NOM_DU_CONTENEUR2 bash -c "apk update -y && apk add -y iputils-ping && ping -c 4 localhost"


# -- on utilise la propriété de transitivité du ping réseau, vu en tant que morphisme (le morphisme exsite, si le ping est positif)
export COMMANDE="ping -c 4 $NOM_DU_CONTENEUR1"


echo " sonde réseau : ping du coteneur [NOM_DU_CONTENEUR1] vers le contenur [sondereseau] : "
docker exec -it $NOM_DU_CONTENEUR1 bash -c "ping -c 4 sondereseau"
echo " sonde réseau : ping du coteneur [sondereseau] vers le contenur [NOM_DU_CONTENEUR2] : "
docker exec -it sondereseau bash -c "ping -c 4 $NOM_DU_CONTENEUR2"
# - composée : 
echo " sonde réseau : ping du coteneur [NOM_DU_CONTENEUR1] vers le contenur [NOM_DU_CONTENEUR2] : "
docker exec -it $NOM_DU_CONTENEUR1 bash -c "ping -c 4 $NOM_DU_CONTENEUR2"

```



Ok, les tests préliminaires m'amènent à conclure, qu'il faut "réparer" la configuration réseau docker-compose, afin de pouvoir utiliser la recette. Une configuration plus fine, devrait pêtre orchestrée par un Ansible / Terraform.

Il faudra corriger pour que les conteneurs ne fasse mention réciproque que de leur nom de domaine nginx, dans leurs configurations respectives. Et l'ensemble de l'intégratio n dépendra de la configurration de la résolution de noms de domaines, dans la pile réseau docker.


### Les fichiers qui mentionnent des noms de domaine

Ces fichiers devront donc faire l'objet d'une "templatisation Ansible Role".

```bash
./gitlab/runner/config.toml 
./gitlab/runner/servers.conf
./nginx/chatops.conf
./nginx/hosts

```
Pour Hubot et Rocketcat, je n'ai trouvé aucune mention notable de nom de domaine ou adresse IP pour désigner un hôte réseau, dans une configuration.

### Tests réseaux

```bash
rm -rf ./fichier-temp-marguerite
echo "$(pwd)" >>  ./fichier-temp-marguerite
cat ./fichier-temp-marguerite
export NOM_REPERTOIRE_COURANT=$(awk -F / '{print $4}' ./fichier-temp-marguerite)
echo " NOM_REPERTOIRE_COURANT=$NOM_REPERTOIRE_COURANT"
echo "------------------------------------------------------"

export NOM_DU_RESEAU_A_ANALYSER="$NOM_REPERTOIRE_COURANT"_devops
echo " NOM_DU_RESEAU_A_ANALYSER=$NOM_DU_RESEAU_A_ANALYSER"
echo "------------------------------------------------------"

export NOM_CONTENEUR_SONDE_RESEAU=sonde-reseau-marguerite

docker run -it --name $NOM_CONTENEUR_SONDE_RESEAU --network='$NOM_DU_RESEAU_A_ANALYSER"  -d centos:7
docker exec -it conteneur-sonde-reseau bash -c "yum update -y && yum install -y iputils" 
```
Puis, pour exécuter un test de connexion réseau IP :

```bash
export NOM_DU_CONTENEUR=rocketchat
export NOM_DHOTE_RESEAU_IP=$NOM_CONTENEUR
export NOM_CONTENEUR_SONDE_RESEAU=sonde-reseau-marguerite
docker exec -it $NOM_CONTENEUR_SONDE_RESEAU bash -c "ping -c 4 $NOM_DHOTE_RESEAU_IP"
```
#### sondereseau

La pésente recette provisionne (cf. `./docker-compose.yml`) un conteneur dont le nom est `sondereseau`, qui peut être utilisé poru réaliser des tests réseaux, notamment pour tester les réseaux par lesquels les conteneurs échangent entre eux.

#### Nota Bene
Le petit script : 

```bash
rm -rf ./fichier-temp-marguerite 
echo "$(pwd)" >>  ./fichier-temp-marguerite 
cat ./fichier-temp-marguerite 
export NOM_REPERTOIRE_COURANT=$(awk -F / '{print $4}' ./fichier-temp-marguerite)
echo " NOM_REPERTOIRE_COURANT=$NOM_REPERTOIRE_COURANT"
echo "------------------------------------------------------"

```
N'est qu'une astuce Bash, pour permettre de "calculer" le nom du réseau créé par la configuration docker-compose.yml.
J'y ait eut recours, parce que je n'ai pas encorte trouvé de manière de forcer le nommage du réseau ainsi créé.

## Dernières erreurs

Tous les conteneurs démarrent correctement, sauf le conteneur rocketchat.
En examinant les logs du conteneur, je constate que c'est la connexion, du conteneur
`rocketchat`, vers le conteneur `mongo`, qui pose problème, mais que l'hôte réseau IP est joignable : 

```bash
$ docker ps -a
CONTAINER ID        IMAGE                                COMMAND                  CREATED             STATUS                     PORTS                                                                                                                          NAMES
56ed881530b9        mongo:latest                         "docker-entrypoint.s…"   5 minutes ago       Exited (1) 5 minutes ago                                                                                                                                  mongo-init-replica
2b867f1182de        rocketchat/rocket.chat:latest        "node main.js"           5 minutes ago       Exited (1) 4 minutes ago                                                                                                                                  rocketchat
945fb625f1f3        marguerite/sonde-reseau:0.0.1        "/bin/bash"              5 minutes ago       Up 5 minutes                                                                                                                                              sondereseau
fc6a83c17edc        marguerite/mongo:1.0.0               "docker-entrypoint.s…"   5 minutes ago       Up 5 minutes (unhealthy)   0.0.0.0:27017->27017/tcp                                                                                                       mongo
8430360cda16        jbl/gitlab-runner:latest             "/usr/bin/dumb-init …"   5 minutes ago       Up 5 minutes               0.0.0.0:8000->8000/tcp                                                                                                         runner
13cc988fa8e0        nginx                                "nginx -g 'daemon of…"   5 minutes ago       Exited (1) 5 minutes ago                                                                                                                                  proxy
8f7f30b60402        gitlab/gitlab-ce:latest              "/assets/wrapper"        5 minutes ago       Up 5 minutes (healthy)     22/tcp, 80/tcp, 2222/tcp, 3000/tcp, 4443/tcp, 8080/tcp, 0.0.0.0:8081->8081/tcp, 0.0.0.0:2222->222/tcp, 0.0.0.0:4443->443/tcp   marguerite_gitlab
7fb1baeac47f        rocketchat/hubot-rocketchat:latest   "/bin/sh -c 'node -e…"   5 minutes ago       Up 5 minutes               0.0.0.0:3001->3001/tcp                                                                                                         hubot
520a7b41e9a6        nginx:latest                         "nginx -g 'daemon of…"   12 hours ago        Up 12 hours                0.0.0.0:80->80/tcp                                                                                                             reverse-proxy-marguerite
f6abad0ffcbd        jenkins:2.60.3                       "/bin/tini -- /usr/l…"   12 hours ago        Up 12 hours                0.0.0.0:8080->8080/tcp, 0.0.0.0:50000->50000/tcp                                                                               jenkins-marguerite
b8546132b2be        centos:7                             "/bin/bash"              13 hours ago        Up 13 hours                                                                                                                                               machin
$ docker exec -it sondereseau bash -c "ping -c 4 mongo"
PING mongo (172.28.0.7) 56(84) bytes of data.
64 bytes from mongo.gitlab-rocketeer_devops (172.28.0.7): icmp_seq=1 ttl=64 time=0.196 ms
64 bytes from mongo.gitlab-rocketeer_devops (172.28.0.7): icmp_seq=2 ttl=64 time=0.127 ms
^C
--- mongo ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.127/0.161/0.196/0.036 ms
$ docker logs rocketchat

/app/bundle/programs/server/node_modules/fibers/future.js:313
						throw(ex);
						^
MongoError: failed to connect to server [mongo:27017] on first connect [MongoError: connect ECONNREFUSED 172.28.0.7:27017]
    at Pool.<anonymous> (/app/bundle/programs/server/npm/node_modules/meteor/npm-mongo/node_modules/mongodb-core/lib/topologies/server.js:336:35)
    at emitOne (events.js:116:13)
    at Pool.emit (events.js:211:7)
    at Connection.<anonymous> (/app/bundle/programs/server/npm/node_modules/meteor/npm-mongo/node_modules/mongodb-core/lib/connection/pool.js:280:12)
    at Object.onceWrapper (events.js:317:30)
    at emitTwo (events.js:126:13)
    at Connection.emit (events.js:214:7)
    at Socket.<anonymous> (/app/bundle/programs/server/npm/node_modules/meteor/npm-mongo/node_modules/mongodb-core/lib/connection/connection.js:189:49)
    at Object.onceWrapper (events.js:315:30)
    at emitOne (events.js:116:13)
    at Socket.emit (events.js:211:7)
    at emitErrorNT (internal/streams/destroy.js:64:8)
    at _combinedTickCallback (internal/process/next_tick.js:138:11)
    at process._tickCallback (internal/process/next_tick.js:180:9)
```
Avec plus de tests réseaux, j'ai déterminé que le contneur ROPcketchat cessait son exécution, car il n'arrivait pas à se connecter à la base de données dans le conteneur `mongo` : 
Le temps que la base de données MongoDB soit "Up n running", le conteneur rocketchat a déjà échoué à la connexion BDD. 

J'ai d'abord ajouté un Healthcheck à ma définition de service mongodb, avec un dockerfile, cf. `mongodb/construction/Dockerfile` : 
Aucun effet, malgré la directive `depends_on` (`./docker-compose.yml`) qui déclare une dépendance explicite du conteneur `rocketchat`, pour le conteneur `mongo`.

J'ai ensuite ajouté une directive  `restart: always`, pour que le conteneur rocketcaht, re-démarre à cahque fois qu'il stoppe son exécution: ainsi, il re-démarre, jsuqu'à ce qu ela BDD MongoDB soit disponible.

Cette solution ne me satisfait pas à terme, car elle ne tire pas profit de la définition des HEALTHCHEK, et de leur  implication dans la définition e tle parmétrage des SLAs.

Pour terminer, J'en arrive à un point où une seule erreur subsiste, et c'est une nouvelle erreur pour le conteneur rocketchat : 

```bash
$ docker logs rocketchat
/app/bundle/programs/server/node_modules/fibers/future.js:280
						throw(ex);
						^

Error: $MONGO_OPLOG_URL must be set to the 'local' database of a Mongo replica set
    at OplogHandle._startTailing (packages/mongo/oplog_tailing.js:218:13)
    at new OplogHandle (packages/mongo/oplog_tailing.js:76:8)
    at new MongoConnection (packages/mongo/mongo_driver.js:214:25)
    at new MongoInternals.RemoteCollectionDriver (packages/mongo/remote_collection_driver.js:4:16)
    at Object.<anonymous> (packages/mongo/remote_collection_driver.js:38:10)
    at Object.defaultRemoteCollectionDriver (packages/underscore.js:784:19)
    at new Collection (packages/mongo/collection.js:97:40)
    at new AccountsCommon (packages/accounts-base/accounts_common.js:23:18)
    at new AccountsServer (packages/accounts-base/accounts_server.js:18:5)
    at server_main.js (packages/accounts-base/server_main.js:9:12)
    at fileEvaluate (packages/modules-runtime.js:343:9)
    at require (packages/modules-runtime.js:238:16)
    at /app/bundle/programs/server/packages/accounts-base.js:2012:15
    at /app/bundle/programs/server/packages/accounts-base.js:2019:3
    at /app/bundle/programs/server/boot.js:411:36
    at Array.forEach (<anonymous>)
``` 

J'ai encore creusé mon investigation, et cette fois il apparaît, que la valeur de configuration de la variable `MONGO_OPLOG_URL`  , est bien correte.
Si cette variable d'environnement est précisée pour la configuration du conteneur `rocketchat`, c'est parce que le conteneur `rocketchat` doit pouvoir communiquer avec l'instance MongoDB, par un canal particulier. On trouvera rapidement avec une recehrceh google, que ce canal est mis à disposition par MongoDB, etles applicatons peuvent l'utiliser pour écouter les évènements sur l'histroique mongodb (celui lié à la notion "mongo replay").
D'autre part, si on fait un :
```bash
docker logs mongo-init-replica
```
On constate que ce conteneur a échoué dans sa tâche, et ce parceque la connexion lui a été refusée. La tâche accomplie par ce conteneur est d'initialiser  le "replicaSet" MongoDB, donc le "replicaSet" n'est pas initialisé correctement, et la connexion  utilisée par `rocketchat`, configurée avec la variable `MONGO_OPLOG_URL`, échoue, parce qu'elle nécessite l'initialisation du replicaSet.

J'ai encorea pprofondi l'étude, et ai découvert que la valeur de `MONGO_OPLOG_URL`, doit préciser le nom du repilicaSet mongoDb, avec un paramètre HTTP/get : 

```bash
version: '3'

services:
  gitlab:
# - [... etc... J'ai abrégé la confioguration]
  mongo-init-replica:
    # image: mongo:3.2
    image: mongo:latest
    container_name: 'mongo-init-replica'
    command: 'mongo mongo/rocketchat --eval "rs.initiate({ _id: ''rs0'', members: [ { _id: 0, host: ''mongo:27017'' } ]})"'
    networks:
      - devops
    depends_on:
      - mongo
  rocketchat:
    image: rocketchat/rocket.chat:latest
    container_name: 'rocketchat'
    volumes:
      - ./rocketchat/uploads:/app/uploads
    environment:
      - PORT=3000
      - ROOT_URL=http://rocketchat.marguerite.io:3000
      - MONGO_URL=mongodb://mongo:27017/rocketchat
      - MONGO_OPLOG_URL=mongodb://mongo:27017/local?replicaSet=rs0
      - MAIL_URL="smtp://smtp.google.com"
    ports:
      - 3000:3000
    expose:
      - "3000"
    depends_on:
      - mongo
    networks:
      - devops
    restart: always

```
On remarquera aussi que le nom du replica Set, créé avec le conteneur `mongo-init-replica`, doit être le nom du replicaSet mentionné par `MONGO_OPLOG_URL` (ci-dessus, `rs0`).

Une fois relancé l'emsble du docker-compose, on constate que de nouveaux problèmes se manifestent : 
* D'abord, le conteneur `mongo-init-replica` échoue toujours à sa première tntative de création du replicaSet, parce que le conteneur `mongodb` n'est pas prêt. On peut donc relancer l'exécution du conteneur `mongo-init-replica`, afin de crééer le replicaSet : `docker start mongo-ibit-replica`
* Une fois cela fait, on peut alors suivre les logs du conteneur rocketchat, qui démarre effectivmeent, mais tout en émettant des avertissements qu'il faudra traiter comme des erreurs. Sortie standard de ces erreurs : 
```bash
/app/bundle/programs/server/node_modules/fibers/future.js:313
						throw(ex);
						^
MongoError: no primary found in replicaset or invalid replica set name
    at /app/bundle/programs/server/npm/node_modules/meteor/npm-mongo/node_modules/mongodb-core/lib/topologies/replset.js:560:28
    at Server.<anonymous> (/app/bundle/programs/server/npm/node_modules/meteor/npm-mongo/node_modules/mongodb-core/lib/topologies/replset.js:312:24)
    at Object.onceWrapper (events.js:315:30)
    at emitOne (events.js:116:13)
    at Server.emit (events.js:211:7)
    at /app/bundle/programs/server/npm/node_modules/meteor/npm-mongo/node_modules/mongodb-core/lib/topologies/server.js:300:14
    at /app/bundle/programs/server/npm/node_modules/meteor/npm-mongo/node_modules/mongodb-core/lib/connection/pool.js:469:18
    at _combinedTickCallback (internal/process/next_tick.js:131:7)
    at process._tickCallback (internal/process/next_tick.js:180:9)
Updating process.env.MAIL_URL
Starting Email Intercepter...
Warning: connect.session() MemoryStore is not
designed for a production environment, as it will leak
memory, and will not scale past a single process.
Setting default file store to GridFS
LocalStore: store created at 
LocalStore: store created at 
LocalStore: store created at 
Fri, 17 Aug 2018 10:52:39 GMT connect deprecated multipart: use parser (multiparty, busboy, formidable) npm module instead at npm/node_modules/connect/lib/middleware/bodyParser.js:56:20
Fri, 17 Aug 2018 10:52:39 GMT connect deprecated limit: Restrict request size at location of read at npm/node_modules/connect/lib/middleware/multipart.js:86:15
Updating process.env.MAIL_URL
Using GridFS for custom sounds storage
Using GridFS for custom emoji storage
ufs: temp directory created at "/tmp/ufs"
➔ System ➔ startup
➔ +-------------------------------------------------------------+
➔ |                        SERVER RUNNING                       |
➔ +-------------------------------------------------------------+
➔ |                                                             |
➔ |  Rocket.Chat Version: 0.69.2                                |
➔ |       NodeJS Version: 8.11.3 - x64                          |
➔ |             Platform: linux                                 |
➔ |         Process Port: 3000                                  |
➔ |             Site URL: http://rocketchat.marguerite.io:3000  |
➔ |     ReplicaSet OpLog: Enabled                               |
➔ |          Commit Hash: 7df9818105                            |
➔ |        Commit Branch: HEAD                                  |
➔ |                                                             |
➔ +-------------------------------------------------------------+

```
* Ensuite, on voit que le conteneur `hubot`, a arrêté son exécution. Si on le re-démarre, avec un `docker start hubot`, et que l'on inspecte les logs de son exécution, on voit que le hubot démarre correctement, puis stoppe, en logguant l'erreur suivante: 
 ```
 [Fri Aug 17 2018 10:55:37 GMT+0000 (UTC)] INFO Starting Rocketchat adapter version 1.0.11...
[Fri Aug 17 2018 10:55:37 GMT+0000 (UTC)] INFO Once connected to rooms I will respond to the name: Rocket.Cat
[Fri Aug 17 2018 10:55:37 GMT+0000 (UTC)] INFO I will also respond to my Rocket.Chat username as an alias: rocket.cat
[Fri Aug 17 2018 10:55:37 GMT+0000 (UTC)] INFO Connecting To: rocketchat:3000
[Fri Aug 17 2018 10:55:37 GMT+0000 (UTC)] INFO Successfully connected!
[Fri Aug 17 2018 10:55:37 GMT+0000 (UTC)] INFO 
[Fri Aug 17 2018 10:55:37 GMT+0000 (UTC)] INFO Logging In
[Fri Aug 17 2018 10:55:37 GMT+0000 (UTC)] ERROR Unable to Login: {"isClientSafe":true,"error":403,"reason":"User has no password set","message":"User has no password set [403]","errorType":"Meteor.Error"} Reason: User has no password set
[Fri Aug 17 2018 10:55:37 GMT+0000 (UTC)] ERROR If joining GENERAL please make sure its using all caps.
[Fri Aug 17 2018 10:55:37 GMT+0000 (UTC)] ERROR If using LDAP, turn off LDAP, and turn on general user registration with email verification off.
```
* Il faut donc maitenant créer l'utilisateur que le HUBOT réclame !

# REPRISE
* Il faut donc maitenant créer l'utilisateur que le HUBOT réclame !


# ChatOps with Rocket.Chat
## Inspired in Gitlab: "From Idea to Production"

We've all got pretty amazed with the Gitlabs Idea to Production demonstration, and we felt inspired by doing the same, so we took the challenge and prepared this tutorial, with a different stack, to take your ideas to production, with Gitlab, Rocket.Chat and Hubot, all packed in a nice Docker containers stack.

Maybe we can call it...

##Chat, code and ship ideas to production

Let's take a look to this stack first, so you understand what we will be running in the following services containers:

- Gitlab CE (latest)  
- Rocket.Chat (latest)  
- MongoDB (3.2)
- Hubot-RocketChat (latest)
- Gitlab-Runner (latest with Dockerfile modifications)
- Nginx (latest as a reverse proxy)

## How does it work?

First we need to setup our environments, and if it's your first time running it, you should follow this instructions carefully, so we can get everything connected.

I you've already done these steps, just go inside your directory, in terminal, and type:

```
docker-compose up -d
```

To stop all services:

```
docker-compose stop
```

### GITLAB CE

In our docker-compose.yml, adjust the following variables:

```yaml
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://git.dorgam.it/'
        gitlab_rails['gitlab_shell_ssh_port'] = 22
        gitlab_rails['lfs_enabled'] = true
        nginx['listen_port'] = 8081

```
You should set your external domain url, and leave the others.

>INFO: because we can't have more than one container lintening in the same port number, our services will be all listening in different ports, and we will let a NGINX reverse proxy take care of the rest.

Then set your volumes to make sure your data will be persisted:

```yaml
    volumes:
      - ./gitlab/config:/etc/gitlab
      - ./gitlab/logs:/var/log/gitlab
      - ./gitlab/data:/var/opt/gitlab
```

If your docker installation accepts your working directory as a volume, you can use the relative path.

And then we create a common shared network so the containers can communicate to each other. We will set a static ipv4 address, so we can use in others containers hosts files:  

```yaml
    networks:
      devops:
        ipv4_address: 172.20.0.4
```

Now, you should just enter in terminal, and type inside this directory:

```
docker-compose up -d gitlab

docker logs -f chatops_gitlab_1
```

Now you will see the containers logs, it takes a while, but you can make sure that gitlabs is running accessing http://git.dorgam.it:8081 in your browser.

### Gitlab Runner

You will need a registered runner to work with your pipeline, so we got the gitlab/gitlab-runner docker image and created a Dockerfile in ./gitlab/runner to install a nginx http server inside it and register it in your gitlab.
This is actually the most trick part, we know we shoudn't put two services inside the same container, but remember this is just an example, in real life, you will have your own server with your own runners.

So, you will find in docker-compose.yml:

```yaml
  runner:
    build: ./gitlab/runner/
    hostname: "runner"
    restart: "always"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    links:
      - gitlab
    environment:
      - GITLAB_HOST=gitlab:8081
    ports:
      - "8000:8000"
    expose:
      - "8000"
    networks:
      devops:
        ipv4_address: 172.20.0.5

```

We've set a env variable `GITLAB_HOST=gitlab:8081`, using the service name as url address, that only will work inside docker network, where containers can find each other by the service name.

Let's go to the terminal and build our runner:

```shell
docker-compose build runner

```

If everything goes well, just put it up:

```shell
docker-compose up -d runner
```

Once the runner's container is up, you need to register it in your gitlab. Go at the runners page of your gitlab project and copy the token to the `-r` option, then we will put your external url domain inside the `/etc/hosts` file so the runner knows where your git repository is, and then register your runner:

```shell
docker exec -it chatops_runner_1 /bin/bash -c "echo '172.20.0.10     git.dorgam.it' >> /etc/hosts"

docker exec -it chatops_runner_1 /usr/bin/gitlab-runner register -u http://gitlab:8081/ci -r BwU14yBJTbnJjX8 --name "server runner" --executor shell --tag-list homolog,production --non-interactive
```

> TIP: You can also set a volume for the /etc/hosts file, so it will be persisted in your host machine.


> EXPLAIN: docker exec -it [name-of-container] [command]  
> You can get the name of your container using `docker ps`

A message like this should appear:

```
Registering runner... succeeded                     runner=8e641b0b    
Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
```

You can check if your runner is communicating by going to the Gitalabs Runner's page.
![Runner Registered](./img/runner-register.jpg)

### MongoDB

First start mongodb container, then we need to start mongo-init-replica, so mongodb turns into a replica set primary server. In the terminal:

```shell
docker-compose up -d mongo
```

> TIP: You can check the logs by using `docker logs -f [container_name]`, it's better than being attached to the container.

When it's done, run:

```shell
docker-compose up -d mongo-init-replica
```

This will initiate the replicaset configuration, and exit the container.

### Rocket.Chat

To put Rocket.Chat up you just need to set the environment variables `PORT` and `ROOT_URL` and run it:

```yaml
  rocketchat:
    image: rocketchat/rocket.chat:latest
    hostname: 'rocketchat'
    volumes:
      - ./rocketchat/uploads:/app/uploads
    environment:
      - PORT=3000
      - ROOT_URL=http://chat.dorgam.it:3000
      - MONGO_URL=mongodb://mongo:27017/rocketchat
      - MONGO_OPLOG_URL=mongodb://mongo:27017/local
      - MAIL_URL="smtp://smtp.google.com"
    links:
      - mongo:mongo
      - gitlab:gitlab
    ports:
      - 3000:3000
    expose:
      - "3000"
    depends_on:
      - mongo
    networks:
      devops:
        ipv4_address: 172.20.0.8
```

You can set MongoDB address, if you're using another service, and `MAIL_URL` in case you have a internal smtp server.

Run:
```
docker-compose up -d rocketchat
```

Now go register your Rocket.Chat Admin user, by http://chat.dorgam.it:3000/, and **create a user and a channel for the bot.**

### Hubot

Hubot is our framework for building bots, my favorite actually, here you can set a lot of params, just keep in mind that most of hubots scripts crashes if they don't find their environment variables, so be carefull when configuring these:

```yaml

  hubot:
    image: rocketchat/hubot-rocketchat:latest
    hostname: "hubot"
    environment:
      - ROCKETCHAT_URL=rocketchat:3000
      - ROCKETCHAT_ROOM=devops
      - ROCKETCHAT_USER=rocket.cat
      - ROCKETCHAT_PASSWORD=bot
      - ROCKETCHAT_AUTH=password
      - BOT_NAME=Rocket.Cat
      - LISTEN_ON_ALL_PUBLIC=true
      - EXTERNAL_SCRIPTS=hubot-help,hubot-seen,hubot-links,hubot-diagnostics,hubot-gitsy,hubot-gitlab-agile
      - GITLAB_URL=http://gitlab/api/v3/
      - GITLAB_API_KEY="cNhsKKLDNslKDkiS"
      - GITLAB_TOKEN=cNhsKKLDNslKDkiS
      - GITLAB_RECORD_LIMIT=100

    links:
      - rocketchat:rocketchat
      - gitlab:gitlab
    volumes:
      - ./hubot/scripts:/home/hubot/scripts
  # this is used to expose the hubot port for notifications on the host on port 3001, e.g. for hubot-jenkins-notifier
    ports:
      - 3001:3001
    networks:
      devops:
        ipv4_address: 172.20.0.9
```

First you need to change `ROCKETCHAT_ROOM`, `ROCKETCHAT_USER`, that will be the username that you created in rocket.chat, and `ROCKETCHAT_PASSWORD` in plain text. As you can see I'm using Rocket.Cat, a natural rocket.chat bot, that comes with the installation, but you can create another one at your own image.

In the `./hubot/scripts` folder we can persist hubots scripts, there is a lot of then in github, you will be amazed.

Save your changes and run:

```shell
docker-compose up -d hubot
```

Check the logs to see if everything went well and then go to your channel and ask for a "yoda quote", just for fun.

### NGINX Reverse Proxy

So as we've said before, docker containers can't connect to the same port simultanesly, that's why each service has it's own port, but that's not cool for the a user friendly experience, so what we've done here is putting a NGINX Reverse Proxy in front of every service, listening to port 80 (and 443 if you like) and proxy_passing the connections to the services on their own port.

The NGINX configuration file is persisted in `./nginx/chatops.conf`, and you should change the domain names if you want.

```nginx
upstream chat{
  ip_hash;
  server rocketchat:3000;
}

server {
  listen 80;
  server_name chat.dorgam.it;
  error_log /var/log/nginx/rocketchat.error.log;

  location / {
    proxy_pass http://chat;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $http_host;

    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forward-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forward-Proto http;
    proxy_set_header X-Nginx-Proxy true;

    proxy_redirect off;
  }
}

server {
  listen 80;
  server_name git.dorgam.it;
  error_log /var/log/nginx/gitlab.error.log;


  location / {
    proxy_pass http://gitlab:8081;
    proxy_redirect off;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Protocol $scheme;
    proxy_set_header X-Url-Scheme $scheme;
  }
}

server {
  listen 80;
	server_name www.dorgam.it;

	location / {
		proxy_pass http://runner:8000;
    proxy_redirect off;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Protocol $scheme;
    proxy_set_header X-Url-Scheme $scheme;
	}
}

server {
  listen 80;
	server_name hom.dorgam.it;

	location / {
		proxy_pass http://runner:8000;
    proxy_redirect off;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Protocol $scheme;
    proxy_set_header X-Url-Scheme $scheme;
	}
}

```

Just save your changes and:

```shell
docker-compose up -d nginx
```

When you change these confs, remember to reload then into NGINX:

```shell
docker exec -it chatops_nginx_1 /bin/bash -c "service nginx reload"
```

Hosts file is also persisted, so you can add or remove anything.

## Rocket.Chat Webhook Integration Script

Althougth Hubot is a very powerfull tool for bot scripting, you might wanna add some webhooks integration to our channels in Rocket.Chat.

For that, there is a pretty simple script that you can change as you like, to read the gitlabs webhooks and throw some messages inside your project channel.



Here is what you gonna do:
#### ajout jbl :

la méthode décrite cidessous implique un ficher de script à modifier. Je veux voir si je peux psécifier ce script au boot du conteneur, avec la variable d'environnement ̀`EXTERNAL_SCRIPTS` ci dessous :

```bash
docker run -it -e ROCKETCHAT_URL=<your rocketchat instance>:<port> \
    -e ROCKETCHAT_ROOM='' \
    -e LISTEN_ON_ALL_PUBLIC=true \
    -e ROCKETCHAT_USER=bot \
    -e ROCKETCHAT_PASSWORD=bot \
    -e ROCKETCHAT_AUTH=password \
    -e BOT_NAME=bot \
    -e EXTERNAL_SCRIPTS=hubot-pugme,hubot-help \
    rocketchat/hubot-rocketchat
```
### Create Rocket.Chat Incoming WebHook

Access your rocket.chat from your browser (http://chat.dorgam.it) and go to the top menu (the little arrow besides your name) and click in Administration > Integrations > New Integration > Incoming WebHook.

Fill the form with the name of the script, the #channel (with sharp signal) where the messages will appear, and on until script. You activate script, and paste this script inside the script box:

```javascript
/* eslint no-console:0, max-len:0 */
// see https://gitlab.com/help/web_hooks/web_hooks for full json posted by GitLab
const NOTIF_COLOR = '#6498CC';
const refParser = (ref) => ref.replace(/^refs\/(?:tags|heads)\/(.+)$/, '$1');
const displayName = (name) => name.toLowerCase().replace(/\s+/g, '.');
const atName = (user) => (user && user.name ? '@' + displayName(user.name) : '');
const makeAttachment = (author, text) => {
	return {
		author_name: author ? displayName(author.name) : '',
		author_icon: author ? author.avatar_url : '',
		text,
		color: NOTIF_COLOR
	};
};
const pushUniq = (array, val) => ~array.indexOf(val) || array.push(val); // eslint-disable-line

class Script { // eslint-disable-line
	process_incoming_request({ request }) {
		try {
			let result = null;
			const channel = request.url.query.channel;
			switch (request.headers['x-gitlab-event']) {
				case 'Push Hook':
					result = this.pushEvent(request.content);
					break;
				case 'Merge Request Hook':
					result = this.mergeRequestEvent(request.content);
					break;
				case 'Note Hook':
					result = this.commentEvent(request.content);
					break;
				case 'Issue Hook':
					result = this.issueEvent(request.content);
					break;
				case 'Tag Push Hook':
					result = this.tagEvent(request.content);
					break;
        case 'Pipeline Hook':
					result = this.pipelineEvent(request.content);
					break;
			}
			if (result && result.content && channel) {
				result.content.channel = '#' + channel;
			}
			return result;
		} catch (e) {
			console.log('gitlabevent error', e);
			return {
				error: {
					success: false,
					message: e.message || e
				}
			};
		}
	}

	issueEvent(data) {
		return {
			content: {
				username: 'gitlab/' + data.project.name,
				icon_url: data.project.avatar_url || data.user.avatar_url || '',
				text: (data.assignee && data.assignee.name !== data.user.name) ? atName(data.assignee) : '',
				attachments: [
					makeAttachment(
						data.user,
						`${data.object_attributes.state} an issue _${data.object_attributes.title}_ on ${data.project.name}.
*Description:* ${data.object_attributes.description}.
See: ${data.object_attributes.url}`
					)
				]
			}
		};
	}

	commentEvent(data) {
		const comment = data.object_attributes;
		const user = data.user;
		const at = [];
		let text;
		if (data.merge_request) {
			const mr = data.merge_request;
			const lastCommitAuthor = mr.last_commit && mr.last_commit.author;
			if (mr.assignee && mr.assignee.name !== user.name) {
				at.push(atName(mr.assignee));
			}
			if (lastCommitAuthor && lastCommitAuthor.name !== user.name) {
				pushUniq(at, atName(lastCommitAuthor));
			}
			text = `commented on MR [#${mr.id} ${mr.title}](${comment.url})`;
		} else if (data.commit) {
			const commit = data.commit;
			const message = commit.message.replace(/\n[^\s\S]+/, '...').replace(/\n$/, '');
			if (commit.author && commit.author.name !== user.name) {
				at.push(atName(commit.author));
			}
			text = `commented on commit [${commit.id.slice(0, 8)} ${message}](${comment.url})`;
		} else if (data.issue) {
			const issue = data.issue;
			text = `commented on issue [#${issue.id} ${issue.title}](${comment.url})`;
		} else if (data.snippet) {
			const snippet = data.snippet;
			text = `commented on code snippet [#${snippet.id} ${snippet.title}](${comment.url})`;
		}
		return {
			content: {
				username: 'gitlab/' + data.project.name,
				icon_url: data.project.avatar_url || user.avatar_url || '',
				text: at.join(' '),
				attachments: [
					makeAttachment(user, `${text}\n${comment.note}`)
				]
			}
		};
	}

	mergeRequestEvent(data) {
		const user = data.user;
		const mr = data.object_attributes;
		const assignee = mr.assignee;
		let at = [];

		if (mr.action === 'open' && assignee) {
			at = '\n' + atName(assignee);
		} else if (mr.action === 'merge') {
			const lastCommitAuthor = mr.last_commit && mr.last_commit.author;
			if (assignee && assignee.name !== user.name) {
				at.push(atName(assignee));
			}
			if (lastCommitAuthor && lastCommitAuthor.name !== user.name) {
				pushUniq(at, atName(lastCommitAuthor));
			}
		}
		return {
			content: {
				username: `gitlab/${mr.target.name}`,
				icon_url: mr.target.avatar_url || mr.source.avatar_url || user.avatar_url || '',
				text: at.join(' '),
				attachments: [
					makeAttachment(user, `${mr.action} MR [#${mr.iid} ${mr.title}](${mr.url})\n${mr.source_branch} into ${mr.target_branch}`)
				]
			}
		};
	}

	pushEvent(data) {
		const project = data.project;
		const user = {
			name: data.user_name,
			avatar_url: data.user_avatar
		};
		// branch removal
		if (data.checkout_sha === null && !data.commits.length) {
			return {
				content: {
					username: `gitlab/${project.name}`,
					icon_url: project.avatar_url || data.user_avatar || '',
					attachments: [
						makeAttachment(user, `removed branch ${refParser(data.ref)} from [${project.name}](${project.web_url})`)
					]
				}
			};
		}
		// new branch
		if (data.before == 0) { // eslint-disable-line
			return {
				content: {
					username: `gitlab/${project.name}`,
					icon_url: project.avatar_url || data.user_avatar || '',
					attachments: [
						makeAttachment(user, `pushed new branch [${refParser(data.ref)}](${project.web_url}/commits/${refParser(data.ref)}) to [${project.name}](${project.web_url}), which is ${data.total_commits_count} commits ahead of master`)
					]
				}
			};
		}
		return {
			content: {
				username: `gitlab/${project.name}`,
				icon_url: project.avatar_url || data.user_avatar || '',
				attachments: [
					makeAttachment(user, `pushed ${data.total_commits_count} commits to branch [${refParser(data.ref)}](${project.web_url}/commits/${refParser(data.ref)}) in [${project.name}](${project.web_url})`),
					{
						text: data.commits.map((commit) => `  - ${new Date(commit.timestamp).toUTCString()} [${commit.id.slice(0, 8)}](${commit.url}) by ${commit.author.name}: ${commit.message.replace(/\s*$/, '')}`).join('\n'),
						color: NOTIF_COLOR
					}
				]
			}
		};
	}

	tagEvent(data) {
		const tag = refParser(data.ref);
		return {
			content: {
				username: `gitlab/${data.project.name}`,
				icon_url: data.project.avatar_url || data.user_avatar || '',
				text: '@all',
				attachments: [
					makeAttachment(
						{ name: data.user_name, avatar_url: data.user_avatar },
						`push tag [${tag} ${data.checkout_sha.slice(0, 8)}](${data.project.web_url}/tags/${tag})`
					)
				]
			}
		};
	}

  pipelineEvent(data) {
		const status = data.object_attributes.status;
		const link = data.project.web_url

		return {
			content: {
				username: `gitlab/${data.project.name}`,
				icon_url: data.project.avatar_url || data.user.avatar_url || '',
				text: 'Pipeline Active:',
				attachments: [
					makeAttachment(
						{ name: data.user.name, avatar_url: data.user.avatar_url },
						`Runned a Pipeline with status: ${data.object_attributes.status} [${data.object_attributes.duration}s] (${data.project.web_url}/pipelines)`
					)
				]
			}
		};
	}
}

```

As you can see, in Rocket.Chat even the integrations are full open sourced, you can change the messages inside the script if you like, by just changing the content prepared inside the event functions.

Save your integration and test it with curl, using some gitlab webhook json, like this:

```shell
curl -X POST -H "x-gitlab-event: Pipeline Hook" --data-urlencode 'payload={   "object_kind": "pipeline",   "object_attributes":{      "id": 31,      "ref": "master",      "tag": false,      "sha": "bcbb5ec396a2c0f828686f14fac9b80b780504f2",      "before_sha": "bcbb5ec396a2c0f828686f14fac9b80b780504f2",      "status": "success",      "stages":[         "build",         "test",         "deploy"      ],      "created_at": "2016-08-12 15:23:28 UTC",      "finished_at": "2016-08-12 15:26:29 UTC",      "duration": 63   },   "user":{      "name": "Administrator",      "username": "root",      "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon"   },   "project":{      "name": "Gitlab Test",      "description": "Atque in sunt eos similique dolores voluptatem.",      "web_url": "http://192.168.64.1:3005/gitlab-org/gitlab-test",      "avatar_url": null,      "git_ssh_url": "git@192.168.64.1:gitlab-org/gitlab-test.git",      "git_http_url": "http://192.168.64.1:3005/gitlab-org/gitlab-test.git",      "namespace": "Gitlab Org",      "visibility_level": 20,      "path_with_namespace": "gitlab-org/gitlab-test",      "default_branch": "master"   },   "commit":{      "id": "bcbb5ec396a2c0f828686f14fac9b80b780504f2",      "message": "test",      "timestamp": "2016-08-12T17:23:21+02:00",      "url": "http://example.com/gitlab-org/gitlab-test/commit/bcbb5ec396a2c0f828686f14fac9b80b780504f2",      "author":{         "name": "User",         "email": "user@gitlab.com"      }   },   "builds":[      {         "id": 380,         "stage": "deploy",         "name": "production",         "status": "skipped",         "created_at": "2016-08-12 15:23:28 UTC",         "started_at": null,         "finished_at": null,         "when": "manual",         "manual": true,         "user":{            "name": "Administrator",            "username": "root",            "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon"         },         "runner": null,         "artifacts_file":{            "filename": null,            "size": null         }      },      {         "id": 377,         "stage": "test",         "name": "test-image",         "status": "success",         "created_at": "2016-08-12 15:23:28 UTC",         "started_at": "2016-08-12 15:26:12 UTC",         "finished_at": null,         "when": "on_success",         "manual": false,         "user":{            "name": "Administrator",            "username": "root",            "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon"         },         "runner": null,         "artifacts_file":{            "filename": null,            "size": null         }      },      {         "id": 378,         "stage": "test",         "name": "test-build",         "status": "success",         "created_at": "2016-08-12 15:23:28 UTC",         "started_at": "2016-08-12 15:26:12 UTC",         "finished_at": "2016-08-12 15:26:29 UTC",         "when": "on_success",         "manual": false,         "user":{            "name": "Administrator",            "username": "root",            "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon"         },         "runner": null,         "artifacts_file":{            "filename": null,            "size": null         }      },      {         "id": 376,         "stage": "build",         "name": "build-image",         "status": "success",         "created_at": "2016-08-12 15:23:28 UTC",         "started_at": "2016-08-12 15:24:56 UTC",         "finished_at": "2016-08-12 15:25:26 UTC",         "when": "on_success",         "manual": false,         "user":{            "name": "Administrator",            "username": "root",            "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon"         },         "runner": null,         "artifacts_file":{            "filename": null,            "size": null         }      },      {         "id": 379,         "stage": "deploy",         "name": "staging",         "status": "created",         "created_at": "2016-08-12 15:23:28 UTC",         "started_at": null,         "finished_at": null,         "when": "on_success",         "manual": false,         "user":{            "name": "Administrator",            "username": "root",            "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon"         },         "runner": null,         "artifacts_file":{            "filename": null,            "size": null         }      }   ]}' http://chat.dorgam.it/hooks/7H6ridRv6n8wgfNvb/yPfDX488gXTstQCWN3BQYjjLEyN3BQYjjLEyAN3BQYjjLEyZoj
```

> TIP: With outgoing and incoming webhooks you can **connect Rocket.Chat to whatever you want**. You can be monitoring all of your services with Zabbix, Rancher, Puppet, or even CloudStack, Heroku, Azure, and basically everything that has a API to alert you.

That is what makes Rocket.Chat the most powerfull ChatOps opensource tool in the world!


## That's All Folks!

Now you have your own chatops environment set with Gitlab, Rocket.Chat and Hubot!

You can try to make your own CI Pipeline and get started with your interactions.

Please, feel free to contribute to this tutorial, and also take a look to our links below.

Thanks to all the guys that made it possible:  

- [https://hub.docker.com/r/rocketchat/hubot-rocketchat](https://hub.docker.com/r/rocketchat/hubot-rocketchat)  
- [https://github.com/github/hubot-scripts](https://github.com/github/hubot-scripts)  
- [https://gitlab.com/gitlab-org/omnibus-gitlab/](https://gitlab.com/gitlab-org/omnibus-gitlab/)  
- [Rocket.Chat Team](https://github.com/RocketChat/Rocket.Chat.Docs/blob/master/3.%20Installation/3.%20Docker%20Containers/Docker%20Compose.md)
