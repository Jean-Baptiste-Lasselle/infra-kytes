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
Voici un exemple de résultat de test que j'ai mené, après avoir ainsi manuellement créé un canal RocketChat, et un webhook entrant, pour ensuite envoyer la requête CURL suivante (qui simule une émission d'évènement d'une instance GITLAB ) : 

```bash
curl -X POST -H "x-gitlab-event: Pipeline Hook" --data-urlencode 'payload={   "object_kind": "pipeline",   "object_attributes":{      "id": 31,      "ref": "master",      "tag": false,      "sha": "bcbb5ec396a2c0f828686f14fac9b80b780504f2",      "before_sha": "bcbb5ec396a2c0f828686f14fac9b80b780504f2",      "status": "success",      "stages":[         "build",         "test",         "deploy"      ],      "created_at": "2016-08-12 15:23:28 UTC",      "finished_at": "2016-08-12 15:26:29 UTC",      "duration": 63   },   "user":{      "name": "Administrator",      "username": "root",      "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon"   },   "project":{      "name": "Gitlab Test",      "description": "Atque in sunt eos similique dolores voluptatem.",      "web_url": "http://192.168.64.1:3005/gitlab-org/gitlab-test",      "avatar_url": null,      "git_ssh_url": "git@192.168.64.1:gitlab-org/gitlab-test.git",      "git_http_url": "http://192.168.64.1:3005/gitlab-org/gitlab-test.git",      "namespace": "Gitlab Org",      "visibility_level": 20,      "path_with_namespace": "gitlab-org/gitlab-test",      "default_branch": "master"   },   "commit":{      "id": "bcbb5ec396a2c0f828686f14fac9b80b780504f2",      "message": "test",      "timestamp": "2016-08-12T17:23:21+02:00",      "url": "http://example.com/gitlab-org/gitlab-test/commit/bcbb5ec396a2c0f828686f14fac9b80b780504f2",      "author":{         "name": "User",         "email": "user@gitlab.com"      }   },   "builds":[      {         "id": 380,         "stage": "deploy",         "name": "production",         "status": "skipped",         "created_at": "2016-08-12 15:23:28 UTC",         "started_at": null,         "finished_at": null,         "when": "manual",         "manual": true,         "user":{            "name": "Administrator",            "username": "root",            "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon"         },         "runner": null,         "artifacts_file":{            "filename": null,            "size": null         }      },      {         "id": 377,         "stage": "test",         "name": "test-image",         "status": "success",         "created_at": "2016-08-12 15:23:28 UTC",         "started_at": "2016-08-12 15:26:12 UTC",         "finished_at": null,         "when": "on_success",         "manual": false,         "user":{            "name": "Administrator",            "username": "root",            "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon"         },         "runner": null,         "artifacts_file":{            "filename": null,            "size": null         }      },      {         "id": 378,         "stage": "test",         "name": "test-build",         "status": "success",         "created_at": "2016-08-12 15:23:28 UTC",         "started_at": "2016-08-12 15:26:12 UTC",         "finished_at": "2016-08-12 15:26:29 UTC",         "when": "on_success",         "manual": false,         "user":{            "name": "Administrator",            "username": "root",            "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon"         },         "runner": null,         "artifacts_file":{            "filename": null,            "size": null         }      },      {         "id": 376,         "stage": "build",         "name": "build-image",         "status": "success",         "created_at": "2016-08-12 15:23:28 UTC",         "started_at": "2016-08-12 15:24:56 UTC",         "finished_at": "2016-08-12 15:25:26 UTC",         "when": "on_success",         "manual": false,         "user":{            "name": "Administrator",            "username": "root",            "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon"         },         "runner": null,         "artifacts_file":{            "filename": null,            "size": null         }      },      {         "id": 379,         "stage": "deploy",         "name": "staging",         "status": "created",         "created_at": "2016-08-12 15:23:28 UTC",         "started_at": null,         "finished_at": null,         "when": "on_success",         "manual": false,         "user":{            "name": "Administrator",            "username": "root",            "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon"         },         "runner": null,         "artifacts_file":{            "filename": null,            "size": null         }      }   ]}' http://rocketchat.marguerite.io:8090/hooks/7H6ridRv6n8wgfNvb/yPfDX488gXTstQCWN3BQYjjLEyN3BQYjjLEyAN3BQYjjLEyZoj
{"success":false,"error":"Invalid integration id or token provided."}
```

étant donné l'erreur qui m'est donnée en retourpar le hubot, je cherche donc à modifier le token envoyé dans la requête. Je prends la valeur mentionnée dans le `./docker-compose.yml`, pour configurer le `hubot`, avec les variables d'environnement `GITLAB_TOKEN` / `GITLAB_API_KEY` , et j'exécute ma requête modifiée : 

```bash
curl -X POST -H "x-gitlab-event: Pipeline Hook" --data-urlencode 'payload={   "object_kind": "pipeline",   "object_attributes":{      "id": 31,      "ref": "master",      "tag": f    "sha": "bcbb5ec396a2c0f828686f14fac9b80b780504f2",      "before_sha": "bcbb5ec396a2c0f828686f14fac9b80b780504f2",      "status": "success",      "stages":[         "build",         "test",         "deploy"      ],      "created_at": "2016-08-12 15:23:28 UTC",      "finished_at": "2016-08-12 15:26:29 UTC",      "duration": 63   },   "user":{      "name": "Administrator",      "username": "root",      "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon"   },   "project":{      "name": "Gitlab Test",      "description": "Atque in sunt eos similique dolores voluptatem.",      "web_url": "http://192.168.64.1:3005/gitlab-org/gitlab-test",      "avatar_url": null,      "git_ssh_url": "git@192.168.64.1:gitlab-org/gitlab-test.git",      "git_http_url": "http://192.168.64.1:3005/gitlab-org/gitlab-test.git",      "namespace": "Gitlab Org",      "visibility_level": 20,      "path_with_namespace": "gitlab-org/gitlab-test",      "default_branch": "master"   },   "commit":{      "id": "bcbb5ec396a2c0f828686f14fac9b80b780504f2",      "message": "test",      "timestamp": "2016-08-12T17:23:21+02:00",      "url": "http://example.com/gitlab-org/gitlab-test/commit/bcbb5ec396a2c0f828686f14fac9b80b780504f2",      "author":{         "name": "User",         "email": "user@gitlab.com"      }   },   "builds":[      {         "id": 380,         "stage": "deploy",         "name": "production",         "status": "skipped",         "created_at": "2016-08-12 15:23:28 UTC",         "started_at": null,         "finished_at": null,         "when": "manual",         "manual": true,         "user":{            "name": "Administrator",            "username": "root",            "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon"         },         "runner": null,         "artifacts_file":{            "filename": null,            "size": null         }      },      {         "id": 377,         "stage": "test",         "name": "test-image",         "status": "success",         "created_at": "2016-08-12 15:23:28 UTC",         "started_at": "2016-08-12 15:26:12 UTC",         "finished_at": null,         "when": "on_success",         "manual": false,         "user":{            "name": "Administrator",            "username": "root",            "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon"         },         "runner": null,         "artifacts_file":{            "filename": null,            "size": null         }      },      {         "id": 378,         "stage": "test",         "name": "test-build",         "status": "success",         "created_at": "2016-08-12 15:23:28 UTC",         "started_at": "2016-08-12 15:26:12 UTC",         "finished_at": "2016-08-12 15:26:29 UTC",         "when": "on_success",         "manual": false,         "user":{            "name": "Administrator",            "username": "root",            "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon"         },         "runner": null,         "artifacts_file":{            "filename": null,            "size": null         }      },      {         "id": 376,         "stage": "build",         "name": "build-image",         "status": "success",         "created_at": "2016-08-12 15:23:28 UTC",         "started_at": "2016-08-12 15:24:56 UTC",         "finished_at": "2016-08-12 15:25:26 UTC",         "when": "on_success",         "manual": false,         "user":{            "name": "Administrator",            "username": "root",            "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon"         },         "runner": null,         "artifacts_file":{            "filename": null,            "size": null         }      },      {         "id": 379,         "stage": "deploy",         "name": "staging",         "status": "created",         "created_at": "2016-08-12 15:23:28 UTC",         "started_at": null,         "finished_at": null,         "when": "on_success",         "manual": false,         "user":{            "name": "Administrator",            "username": "root",            "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon"         },         "runner": null,         "artifacts_file":{            "filename": null,            "size": null         }      }   ]}' http://rocketchat.marguerite.io:8090/hooks/cNhsExCcNhsExicNhsExx
```
et là, j'obtiens une réponse tout à fait différente du serveur RoketChat, une page HTML ! : 

```html
<!DOCTYPE html>
<html>
<head>
<meta name="referrer" content="origin-when-crossorigin">
<script>/* eslint-disable */

'use strict';
(function() {
	var debounce = function debounce(func, wait, immediate) {
		var timeout = void 0;
		return function () {
			var _this = this;

			for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
				args[_key] = arguments[_key];
			}

			var later = function later() {
				timeout = null;
				!immediate && func.apply(_this, args);
			};

			var callNow = immediate && !timeout;
			clearTimeout(timeout);
			timeout = setTimeout(later, wait);
			callNow && func.apply(this, args);
		};
	};

	var cssVarPoly = {
		test: function test() {
			return window.CSS && window.CSS.supports && window.CSS.supports('(--foo: red)');
		},
		init: function init() {
			if (this.test()) {
				return;
			}

			console.time('cssVarPoly');
			cssVarPoly.ratifiedVars = {};
			cssVarPoly.varsByBlock = [];
			cssVarPoly.oldCSS = [];
			cssVarPoly.findCSS();
			cssVarPoly.updateCSS();
			console.timeEnd('cssVarPoly');
		},
		findCSS: function findCSS() {
			var styleBlocks = Array.prototype.concat.apply([], document.querySelectorAll('#css-variables, link[type="text/css"].__meteor-css__'));
			var counter = 1;
			styleBlocks.map(function (block) {
				if (block.nodeName === 'STYLE') {
					var theCSS = block.innerHTML;
					cssVarPoly.findSetters(theCSS, counter);
					cssVarPoly.oldCSS[counter++] = theCSS;
				} else if (block.nodeName === 'LINK') {
					var url = block.getAttribute('href');
					cssVarPoly.oldCSS[counter] = '';
					cssVarPoly.getLink(url, counter, function (counter, request) {
						cssVarPoly.findSetters(request.responseText, counter);
						cssVarPoly.oldCSS[counter++] = request.responseText;
						cssVarPoly.updateCSS();
					});
				}
			});
		},
		findSetters: function findSetters(theCSS, counter) {
			cssVarPoly.varsByBlock[counter] = theCSS.match(/(--[^:; ]+:..*?;)/g);
		},


		updateCSS: debounce(function () {
			cssVarPoly.ratifySetters(cssVarPoly.varsByBlock);
			cssVarPoly.oldCSS.filter(function (e) {
				return e;
			}).forEach(function (css, id) {
				var newCSS = cssVarPoly.replaceGetters(css, cssVarPoly.ratifiedVars);
				var el = document.querySelector('#inserted' + id);

				if (el) {
					el.innerHTML = newCSS;
				} else {
					var style = document.createElement('style');
					style.type = 'text/css';
					style.innerHTML = newCSS;
					style.classList.add('inserted');
					style.id = 'inserted' + id;
					document.getElementsByTagName('head')[0].appendChild(style);
				}
			});
		}, 100),

		replaceGetters: function replaceGetters(oldCSS, varList) {
			return oldCSS.replace(/var\((--.*?)\)/gm, function (all, variable) {
				return varList[variable];
			});
		},
		ratifySetters: function ratifySetters(varList) {
			varList.filter(function (curVars) {
				return curVars;
			}).forEach(function (curVars) {
				curVars.forEach(function (theVar) {
					var matches = theVar.split(/:\s*/);
					cssVarPoly.ratifiedVars[matches[0]] = matches[1].replace(/;/, '');
				});
			});
			Object.keys(cssVarPoly.ratifiedVars).filter(function (key) {
				return cssVarPoly.ratifiedVars[key].indexOf('var') > -1;
			}).forEach(function (key) {
				cssVarPoly.ratifiedVars[key] = cssVarPoly.ratifiedVars[key].replace(/var\((--.*?)\)/gm, function (all, variable) {
					return cssVarPoly.ratifiedVars[variable];
				});
			});
		},
		getLink: function getLink(url, counter, success) {
			var request = new XMLHttpRequest();
			request.open('GET', url, true);
			request.overrideMimeType('text/css;');

			request.onload = function () {
				if (request.status >= 200 && request.status < 400) {
					if (typeof success === 'function') {
						success(counter, request);
					}
				} else {
					console.warn('an error was returned from:', url);
				}
			};

			request.onerror = function () {
				console.warn('we could not get anything from:', url);
			};

			request.send();
		}
	};
	var stateCheck = setInterval(function () {
		if (document.readyState === 'complete' && typeof Meteor !== 'undefined') {
			clearInterval(stateCheck);
			cssVarPoly.init();
		}
	}, 100);

	var DynamicCss = {};

	DynamicCss.test = function () {
		return window.CSS && window.CSS.supports && window.CSS.supports('(--foo: red)');
	};

	DynamicCss.run = debounce(function () {
		var replace = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : false;

		if (replace) {
			var colors = RocketChat.settings.collection.find({
				_id: /theme-color-rc/i
			}, {
				fields: {
					value: 1,
					editor: 1
				}
			}).fetch().filter(function (color) {
				return color && color.value;
			});

			if (!colors) {
				return;
			}

			var css = colors.map(function (_ref) {
				var _id = _ref._id,
						value = _ref.value,
						editor = _ref.editor;

				if (editor === 'expression') {
					return '--' + _id.replace('theme-color-', '') + ': var(--' + value + ');';
				}

				return '--' + _id.replace('theme-color-', '') + ': ' + value + ';';
			}).join('\n');
			document.querySelector('#css-variables').innerHTML = ':root {' + css + '}';
		}

		cssVarPoly.init();
	}, 1000);
})();
</script>

		<link rel="icon" sizes="16x16" type="image/png" href="assets/favicon_16.png" />
		<link rel="icon" sizes="32x32" type="image/png" href="assets/favicon_32.png" />
			<link rel="icon" sizes="any" type="image/svg+xml" href="assets/favicon.svg" />
<title>YooRockit.io</title><meta name="application-name" content="YooRockit.io"><meta name="apple-mobile-web-app-title" content="YooRockit.io">
<meta http-equiv="content-language" content=""><meta name="language" content="">
<meta name="robots" content="INDEX,FOLLOW">
<meta name="msvalidate.01" content="">
<meta name="google-site-verification" content="">
<meta property="fb:app_id" content="">

<base href="/">

  <link rel="stylesheet" type="text/css" class="__meteor-css__" href="/9b704c621adc8a1dcae59307e0023894dbfd2413.css?meteor_css_resource=true">
  <link rel="stylesheet" type="text/css" class="__meteor-css__" href="/theme.css?1807b422d007328786a00d34e6c63ee6022dd2b3">
<meta charset="utf-8" />
	<meta http-equiv="content-type" content="text/html; charset=utf-8" />
	<meta http-equiv="expires" content="-1" />
	<meta http-equiv="X-UA-Compatible" content="IE=edge" />
	<meta name="fragment" content="!" />
	<meta name="distribution" content="global" />
	<meta name="rating" content="general" />
	<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
	<meta name="mobile-web-app-capable" content="yes" />
	<meta name="apple-mobile-web-app-capable" content="yes" />
	<meta name="msapplication-TileImage" content="assets/tile_144.png" />
	<meta name="msapplication-config" content="images/browserconfig.xml" />
	<meta property="og:image" content="assets/favicon_512.png">
	<meta property="twitter:image" content="assets/favicon_512.png">
	<link rel="manifest" href="images/manifest.json" />
	<link rel="chrome-webstore-item" href="https://chrome.google.com/webstore/detail/nocfbnnmjnndkbipkabodnheejiegccf" />
	<link rel="mask-icon" href="assets/safari_pinned.svg" color="#04436a">
	<link rel="apple-touch-icon" sizes="180x180" href="assets/touchicon_180.png" />
	<link rel="apple-touch-icon-precomposed" href="assets/touchicon_180_pre.png">

<script src="/packages/es5-shim/es5-shim-sham.min.js"></script>
</head>
<body>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" style="display: none">
    <symbol viewBox="0 0 20 20" id="icon-add-reaction">
        <g fill="none" fill-rule="evenodd">
            <g transform="translate(3 3)">
                <circle fill="currentColor" cx="9" cy="5" r="1" />
                <circle fill="currentColor" cx="5" cy="5" r="1" />
                <path d="M7 0a7 7 0 1 0 0 14 7 7 0 0 0 7-7M4.172 9.328a4 4 0 0 0 5.656 0" stroke="currentColor" stroke-width="1.5" />
            </g>
            <path d="M16.2 1.2v5.2m-2.6-2.6h5.2" stroke="currentColor" stroke-width="1.5" stroke-linecap="square" />
        </g>
    </symbol>
    <symbol viewBox="0 0 512 512" id="icon-at">
        <path d="M256 8C118.941 8 8 118.919 8 256c0 137.058 110.919 248 248 248 52.925 0 104.68-17.078 147.092-48.319 5.501-4.052 6.423-11.924 2.095-17.211l-5.074-6.198c-4.018-4.909-11.193-5.883-16.307-2.129C346.93 457.208 301.974 472 256 472c-119.373 0-216-96.607-216-216 0-119.375 96.607-216 216-216 118.445 0 216 80.024 216 200 0 72.873-52.819 108.241-116.065 108.241-19.734 0-23.695-10.816-19.503-33.868l32.07-164.071c1.449-7.411-4.226-14.302-11.777-14.302h-12.421a12 12 0 0 0-11.781 9.718c-2.294 11.846-2.86 13.464-3.861 25.647-11.729-27.078-38.639-43.023-73.375-43.023-68.044 0-133.176 62.95-133.176 157.027 0 61.587 33.915 98.354 90.723 98.354 39.729 0 70.601-24.278 86.633-46.982-1.211 27.786 17.455 42.213 45.975 42.213C453.089 378.954 504 321.729 504 240 504 103.814 393.863 8 256 8zm-37.92 342.627c-36.681 0-58.58-25.108-58.58-67.166 0-74.69 50.765-121.545 97.217-121.545 38.857 0 58.102 27.79 58.102 65.735 0 58.133-38.369 122.976-96.739 122.976z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-back">
        <g stroke-width="1.5" stroke="currentColor" fill="none" fill-rule="evenodd">
            <path d="M7.5 15.06L2.44 10 7.5 4.94" />
            <path d="M3.333 10h11.67c.918 0 1.664.74 1.664 1.667v2.916" />
        </g>
    </symbol>
    <symbol viewBox="0 0 448 512" id="icon-bell">
        <path d="M433.884 366.059C411.634 343.809 384 316.118 384 208c0-79.394-57.831-145.269-133.663-157.83A31.845 31.845 0 0 0 256 32c0-17.673-14.327-32-32-32s-32 14.327-32 32c0 6.75 2.095 13.008 5.663 18.17C121.831 62.731 64 128.606 64 208c0 108.118-27.643 135.809-49.893 158.059C-16.042 396.208 5.325 448 48.048 448H160c0 35.29 28.71 64 64 64s64-28.71 64-64h111.943c42.638 0 64.151-51.731 33.941-81.941zM224 480c-17.645 0-32-14.355-32-32h64c0 17.645-14.355 32-32 32zm175.943-64H48.048c-14.223 0-21.331-17.296-11.314-27.314C71.585 353.836 96 314.825 96 208c0-70.741 57.249-128 128-128 70.74 0 128 57.249 128 128 0 106.419 24.206 145.635 59.257 180.686C421.314 398.744 414.11 416 399.943 416z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-bold">
        <path d="M10.627 16.25H6.16V4.8h4.38c1.052 0 1.88.257 2.483.77.603.513.905 1.209.905 2.087a2.49 2.49 0 0 1-.576 1.603c-.383.476-.85.764-1.4.865v.126c.783.101 1.404.401 1.865.901.46.5.69 1.128.69 1.884 0 1.006-.343 1.792-1.028 2.361-.685.569-1.636.853-2.852.853zM7.587 6.062v3.674h2.286c.868 0 1.52-.154 1.956-.46.436-.307.655-.765.655-1.373 0-.582-.198-1.034-.592-1.357-.394-.323-.945-.484-1.654-.484h-2.65zm0 8.926h2.826c.862 0 1.515-.172 1.96-.515.444-.344.666-.847.666-1.508s-.231-1.16-.694-1.496c-.463-.335-1.152-.503-2.067-.503h-2.69v4.022z" fill-rule="evenodd" />
    </symbol>
    <symbol viewBox="0 0 28 28" id="icon-chat">
        <path d="M11 6c-4.875 0-9 2.75-9 6 0 1.719 1.156 3.375 3.156 4.531l1.516 0.875-0.547 1.313c0.328-0.187 0.656-0.391 0.969-0.609l0.688-0.484 0.828 0.156c0.781 0.141 1.578 0.219 2.391 0.219 4.875 0 9-2.75 9-6s-4.125-6-9-6zM11 4c6.078 0 11 3.578 11 8s-4.922 8-11 8c-0.953 0-1.875-0.094-2.75-0.25-1.297 0.922-2.766 1.594-4.344 2-0.422 0.109-0.875 0.187-1.344 0.25h-0.047c-0.234 0-0.453-0.187-0.5-0.453v0c-0.063-0.297 0.141-0.484 0.313-0.688 0.609-0.688 1.297-1.297 1.828-2.594-2.531-1.469-4.156-3.734-4.156-6.266 0-4.422 4.922-8 11-8zM23.844 22.266c0.531 1.297 1.219 1.906 1.828 2.594 0.172 0.203 0.375 0.391 0.313 0.688v0c-0.063 0.281-0.297 0.484-0.547 0.453-0.469-0.063-0.922-0.141-1.344-0.25-1.578-0.406-3.047-1.078-4.344-2-0.875 0.156-1.797 0.25-2.75 0.25-2.828 0-5.422-0.781-7.375-2.063 0.453 0.031 0.922 0.063 1.375 0.063 3.359 0 6.531-0.969 8.953-2.719 2.609-1.906 4.047-4.484 4.047-7.281 0-0.812-0.125-1.609-0.359-2.375 2.641 1.453 4.359 3.766 4.359 6.375 0 2.547-1.625 4.797-4.156 6.266z" />
    </symbol>
    <symbol viewBox="0 0 512 512" id="icon-clip">
        <path d="M149.106 512c-33.076 0-66.153-12.59-91.333-37.771-50.364-50.361-50.364-132.305-.002-182.665L319.842 29.498c39.331-39.331 103.328-39.331 142.66 0 39.331 39.332 39.331 103.327 0 142.657l-222.63 222.626c-28.297 28.301-74.347 28.303-102.65 0-28.3-28.301-28.3-74.349 0-102.649l170.301-170.298c4.686-4.686 12.284-4.686 16.97 0l5.661 5.661c4.686 4.686 4.686 12.284 0 16.971l-170.3 170.297c-15.821 15.821-15.821 41.563.001 57.385 15.821 15.82 41.564 15.82 57.385 0l222.63-222.626c26.851-26.851 26.851-70.541 0-97.394-26.855-26.851-70.544-26.849-97.395 0L80.404 314.196c-37.882 37.882-37.882 99.519 0 137.401 37.884 37.881 99.523 37.882 137.404.001l217.743-217.739c4.686-4.686 12.284-4.686 16.97 0l5.661 5.661c4.686 4.686 4.686 12.284 0 16.971L240.44 474.229C215.26 499.41 182.183 512 149.106 512z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-code">
        <g stroke-width="1.5" stroke="currentColor" fill="none" fill-rule="evenodd">
            <path d="M5.833 13.88L1.953 10l3.88-3.88" />
            <path d="M11.661 3.8l-3.37 12.576L11.662 3.8z" stroke-linecap="square" />
            <path d="M14.167 6.12l3.88 3.88-3.88 3.88" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-cog">
        <g transform="translate(1.667 2.5)" stroke-width="1.5" stroke="currentColor" fill="none" fill-rule="evenodd">
            <circle cx="8.333" cy="7.5" r="2.083" />
            <path d="M6.47 14.883l1.863-1.966 1.864 1.966a7.568 7.568 0 0 0 2.04-.845l-.074-2.708 2.708.073a7.568 7.568 0 0 0 .846-2.04L13.75 7.5l1.967-1.864a7.568 7.568 0 0 0-.846-2.04l-2.708.074.073-2.708a7.568 7.568 0 0 0-2.04-.845L8.334 2.083 6.47.117a7.568 7.568 0 0 0-2.04.845l.073 2.708-2.707-.073a7.568 7.568 0 0 0-.846 2.04L2.917 7.5.95 9.364a7.56 7.56 0 0 0 .846 2.04l2.707-.074-.073 2.708a7.568 7.568 0 0 0 2.04.845z" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-computer">
        <g stroke="currentColor" stroke-width="1.5" fill="none" fill-rule="evenodd">
            <path d="M3 4h14v9H3z" />
            <path d="M7.5 16h5" stroke-linecap="square" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-copy">
        <g fill="none" fill-rule="evenodd">
            <path d="M0 0h20v20H0z" />
            <path stroke="currentColor" stroke-width="1.5" d="M7 5h5l5 5v8H7z" />
            <path stroke="currentColor" stroke-width="1.5" d="M6.959 15H3V2h5l3.043 3.043M17 10h-5V5" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-customize">
        <g transform="translate(3 3)" stroke="currentColor" stroke-width="1.5" fill="none" fill-rule="evenodd">
            <path d="M0 7h8m4 0h2M0 2h2m3.996 0H14M0 12h3m4 0h7" stroke-linecap="square" />
            <circle cx="4" cy="2" r="2" />
            <circle cx="10" cy="7" r="2" />
            <circle cx="5" cy="12" r="2" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-edit">
        <g stroke-width="1.2" stroke="currentColor" fill="none" fill-rule="evenodd">
            <path d="M12.73 3.412c.78-.78 2.044-.78 2.83.006l.7.7c.783.783.788 2.047.005 2.83l-8.901 8.901-4.596 1.06 1.06-4.595 8.902-8.902z" />
            <path d="M11.24 5.609l2.829 2.828" stroke-linecap="square" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-emoji">
        <g fill="none" fill-rule="evenodd">
            <path d="M0 0h20v20H0z" />
            <circle fill="currentColor" cx="12" cy="8" r="1" />
            <circle fill="currentColor" cx="8" cy="8" r="1" />
            <circle stroke="currentColor" stroke-width="1.5" cx="10" cy="10" r="7" />
            <path d="M7.172 12.328a4 4 0 0 0 5.656 0" stroke="currentColor" stroke-width="1.5" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-facebook">
        <path d="M19 1.992v16.012c0 .55-.446.992-.992.992h-4.589v-6.967h2.339l.35-2.716h-2.693V7.577c0-.787.217-1.322 1.346-1.322H16.2v-2.43a19.082 19.082 0 0 0-2.098-.109c-2.073 0-3.495 1.266-3.495 3.592v2.005H8.26v2.716h2.347V19H1.992A.995.995 0 0 1 1 18.008V1.992C1 1.446 1.446 1 1.992 1h16.012c.55 0 .996.446.996.992z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-github">
        <path d="M7.019 15.128c0 .072-.083.13-.189.13-.12.011-.203-.047-.203-.13 0-.073.084-.13.189-.13.109-.012.203.046.203.13zm-1.128-.163c-.026.072.047.156.156.177.094.037.203 0 .225-.072.021-.073-.048-.156-.156-.189-.095-.025-.2.011-.225.084zm1.603-.062c-.105.025-.177.094-.167.178.011.072.106.12.214.094.106-.025.178-.094.167-.167-.01-.069-.108-.116-.214-.105zM9.882 1C4.849 1 1 4.82 1 9.853c0 4.023 2.532 7.466 6.15 8.678.464.083.627-.203.627-.439 0-.225-.01-1.466-.01-2.228 0 0-2.54.545-3.074-1.08 0 0-.413-1.057-1.008-1.329 0 0-.831-.57.058-.558 0 0 .903.072 1.4.936.795 1.4 2.126.997 2.645.758.084-.58.32-.983.58-1.223-2.027-.225-4.074-.519-4.074-4.009 0-.998.276-1.498.857-2.137-.095-.236-.403-1.208.094-2.463.758-.236 2.503.98 2.503.98a8.524 8.524 0 0 1 2.279-.31 8.49 8.49 0 0 1 2.278.31s1.745-1.22 2.504-.98c.497 1.259.188 2.227.094 2.463.58.642.936 1.143.936 2.137 0 3.501-2.137 3.78-4.165 4.01.334.286.617.83.617 1.683 0 1.222-.011 2.735-.011 3.033 0 .236.167.522.627.439 3.629-1.205 6.088-4.648 6.088-8.671C18.995 4.82 14.914 1 9.882 1zM4.527 13.513c-.048.037-.037.12.025.189.058.058.141.083.189.036.047-.036.036-.12-.026-.188-.058-.058-.141-.084-.188-.037zm-.392-.294c-.026.048.01.106.083.142.058.036.13.025.156-.025.026-.048-.01-.106-.083-.142-.073-.022-.13-.01-.156.025zm1.175 1.292c-.058.047-.036.156.047.225.084.083.189.094.236.036.047-.047.026-.156-.047-.225-.08-.083-.189-.094-.236-.036zm-.413-.533c-.058.036-.058.13 0 .214.058.083.156.12.203.083.058-.047.058-.141 0-.225-.051-.083-.145-.12-.203-.072z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-gitlab">
        <path d="M2.047 8.387l7.95 10.333-8.713-6.468a.701.701 0 0 1-.251-.773l1.014-3.092zm2.65-6.144a.352.352 0 0 0-.663 0L2.047 8.387h4.638L4.697 2.243zm1.988 6.144L9.998 18.72 13.31 8.387H6.685zm12.278 3.092l-1.014-3.092L9.998 18.72l8.714-6.468a.701.701 0 0 0 .25-.773zM15.96 2.243a.352.352 0 0 0-.663 0L13.31 8.387h4.638L15.96 2.243z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-google">
        <path d="M18.71 10.21c0 5.136-3.517 8.79-8.71 8.79a8.99 8.99 0 0 1-9-9c0-4.979 4.021-9 9-9 2.424 0 4.464.89 6.035 2.355l-2.45 2.355C10.381 2.62 4.422 4.941 4.422 10c0 3.14 2.508 5.683 5.578 5.683 3.564 0 4.9-2.555 5.11-3.88H10V8.709h8.568c.084.461.142.904.142 1.502z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-hashtag">
        <path d="M7.5 4.167v11.666m5-11.666v11.666M4.167 7.5h11.666m-11.666 5h11.666" stroke="currentColor" stroke-width="1.5" fill="none" stroke-linecap="square" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-help">
        <g stroke="currentColor" stroke-width="1.5" fill="none" fill-rule="evenodd">
            <circle cx="10" cy="10" r="8.333" />
            <circle cx="10" cy="10" r="4.167" />
            <path d="M10 2.083v3.434m0 9.066v3.434m3.958-14.873l-1.716 2.973M7.708 13.97l-1.716 2.973M17.912 10.276l-3.431-.12M5.42 9.84l-3.432-.12m14.726 4.475l-2.912-1.82M6.113 7.571l-2.912-1.82" stroke-linecap="square" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-hubot">
        <path d="M4.858 7.143A1.29 1.29 0 0 0 3.572 8.43v2.572a1.29 1.29 0 0 0 1.286 1.286h10.286A1.29 1.29 0 0 0 16.43 11V8.429a1.29 1.29 0 0 0-1.286-1.286H4.858zm10.286 2.25l-1.607 1.608h-1.929l-1.607-1.607L8.394 11h-1.93L4.859 9.394v-.965h.964l1.607 1.607L9.036 8.43h1.93l1.607 1.607L14.18 8.43h.964v.965zm-7.715 4.18h5.144v1.285H7.429v-1.285zM10.001 2C5.038 2 1 5.742 1 10.358v5.786a1.29 1.29 0 0 0 1.286 1.286h15.43a1.29 1.29 0 0 0 1.286-1.286v-5.786C19.002 5.742 14.964 2 10 2zm7.715 14.144H2.286v-5.786C2.286 6.385 5.68 3.17 10 3.17s7.715 3.215 7.715 7.188v5.786z" />
    </symbol>
    <symbol viewBox="0 0 512 512" id="icon-info-circled">
        <path d="M256 40c118.621 0 216 96.075 216 216 0 119.291-96.61 216-216 216-119.244 0-216-96.562-216-216 0-119.203 96.602-216 216-216m0-32C119.043 8 8 119.083 8 256c0 136.997 111.043 248 248 248s248-111.003 248-248C504 119.083 392.957 8 256 8zm-36 344h12V232h-12c-6.627 0-12-5.373-12-12v-8c0-6.627 5.373-12 12-12h48c6.627 0 12 5.373 12 12v140h12c6.627 0 12 5.373 12 12v8c0 6.627-5.373 12-12 12h-72c-6.627 0-12-5.373-12-12v-8c0-6.627 5.373-12 12-12zm36-240c-17.673 0-32 14.327-32 32s14.327 32 32 32 32-14.327 32-32-14.327-32-32-32z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-italic">
        <path d="M9.357 16.25h1.365V7.697H9.357v8.553zm.683-10.291a.91.91 0 0 0 .674-.282.922.922 0 0 0 .278-.67.918.918 0 0 0-.278-.675.918.918 0 0 0-.674-.277.922.922 0 0 0-.67.277.912.912 0 0 0-.282.675c0 .259.093.482.281.67a.916.916 0 0 0 .67.282z" fill-rule="evenodd" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-key">
        <g transform="matrix(-1 0 0 1 18 2)" fill="none" fill-rule="evenodd">
            <path d="M5.714 5.143c0 .944.15 1.654.448 2.13L.646 12.615 0 14.709 1.292 16l2.088-.642.41-.409v-1.475h1.475l.63-.63v-1.476h1.476l1.566-1.572c.582.327 1.223.49 1.92.49a5.143 5.143 0 0 0 5.141-5.289c-.075-2.684-2.312-4.92-4.995-4.995a5.143 5.143 0 0 0-5.288 5.14z" stroke="currentColor" stroke-width="1.5" />
            <circle fill="currentColor" cx="11.5" cy="4.5" r="1.5" />
        </g>
    </symbol>
    <symbol viewBox="0 0 576 512" id="icon-keyboard">
        <path d="M528 64H48C21.49 64 0 85.49 0 112v288c0 26.51 21.49 48 48 48h480c26.51 0 48-21.49 48-48V112c0-26.51-21.49-48-48-48zm16 336c0 8.823-7.177 16-16 16H48c-8.823 0-16-7.177-16-16V112c0-8.823 7.177-16 16-16h480c8.823 0 16 7.177 16 16v288zM168 268v-24c0-6.627-5.373-12-12-12h-24c-6.627 0-12 5.373-12 12v24c0 6.627 5.373 12 12 12h24c6.627 0 12-5.373 12-12zm96 0v-24c0-6.627-5.373-12-12-12h-24c-6.627 0-12 5.373-12 12v24c0 6.627 5.373 12 12 12h24c6.627 0 12-5.373 12-12zm96 0v-24c0-6.627-5.373-12-12-12h-24c-6.627 0-12 5.373-12 12v24c0 6.627 5.373 12 12 12h24c6.627 0 12-5.373 12-12zm96 0v-24c0-6.627-5.373-12-12-12h-24c-6.627 0-12 5.373-12 12v24c0 6.627 5.373 12 12 12h24c6.627 0 12-5.373 12-12zm-336 80v-24c0-6.627-5.373-12-12-12H84c-6.627 0-12 5.373-12 12v24c0 6.627 5.373 12 12 12h24c6.627 0 12-5.373 12-12zm384 0v-24c0-6.627-5.373-12-12-12h-24c-6.627 0-12 5.373-12 12v24c0 6.627 5.373 12 12 12h24c6.627 0 12-5.373 12-12zM120 188v-24c0-6.627-5.373-12-12-12H84c-6.627 0-12 5.373-12 12v24c0 6.627 5.373 12 12 12h24c6.627 0 12-5.373 12-12zm96 0v-24c0-6.627-5.373-12-12-12h-24c-6.627 0-12 5.373-12 12v24c0 6.627 5.373 12 12 12h24c6.627 0 12-5.373 12-12zm96 0v-24c0-6.627-5.373-12-12-12h-24c-6.627 0-12 5.373-12 12v24c0 6.627 5.373 12 12 12h24c6.627 0 12-5.373 12-12zm96 0v-24c0-6.627-5.373-12-12-12h-24c-6.627 0-12 5.373-12 12v24c0 6.627 5.373 12 12 12h24c6.627 0 12-5.373 12-12zm96 0v-24c0-6.627-5.373-12-12-12h-24c-6.627 0-12 5.373-12 12v24c0 6.627 5.373 12 12 12h24c6.627 0 12-5.373 12-12zm-96 152v-8c0-6.627-5.373-12-12-12H180c-6.627 0-12 5.373-12 12v8c0 6.627 5.373 12 12 12h216c6.627 0 12-5.373 12-12z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-language">
        <path d="M18.778 11.018c-.562-1.536-2.13-2.453-4.195-2.453-.081 0-.159.001-.236.005l-.014-1.857 3.172-.546c.104-.017.12-.107.098-.208-.02-.1-.15-.795-.169-.878-.024-.118-.092-.115-.186-.098-.094.016-2.925.415-2.925.415l-.012-1.87c0-.113-.062-.143-.175-.141l-.922.014c-.095.002-.148.044-.146.134l.03 2.076s-2.755.474-2.83.489c-.075.012-.153.047-.136.128.017.081.171.985.187 1.055.017.072.065.116.17.096l2.631-.453.032 1.816a4.23 4.23 0 0 0-2.03 1.173 3.915 3.915 0 0 0-1.087 2.666c0 1.428.874 2.276 2.095 2.426 2.846.348 4.607-2.754 5.192-4.244.988 1.356.23 3.919-1.884 5.382-.039.026-.088.116-.03.187l.557.68c.072.086.186.053.23.02 2.26-1.556 3.295-4.063 2.583-6.014zm-6.648 2.87c-.87-.11-.85-.823-.85-1.308 0-.696.295-1.422.79-1.94a2.889 2.889 0 0 1 1.105-.72l.074 3.85c-.347.117-.72.166-1.119.117zm2.185-.498l.041-3.699c.076-.003.15-.009.227-.009.695 0 1.344.131 1.696.325.352.196-.92 2.442-1.964 3.383zM6.26 6.488a.176.176 0 0 0-.177-.13H4.328a.175.175 0 0 0-.174.13l-3.147 9.936c-.015.046-.01.069.056.069h1.56c.067 0 .089-.02.102-.065l.907-2.986H6.78l.907 2.986c.014.044.035.065.102.065h1.56c.065 0 .07-.023.056-.069-.012-.045-2.775-8.767-3.144-9.936zm-2.357 5.687L5.206 7.45l1.302 4.725H3.903z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-linkedin">
        <path d="M17.714 1H2.282C1.575 1 1 1.583 1 2.298v15.404C1 18.417 1.575 19 2.282 19h15.432c.707 0 1.286-.583 1.286-1.298V2.298C19 1.583 18.421 1 17.714 1zM6.44 16.429H3.772v-8.59h2.672v8.59H6.44zM5.106 6.665a1.548 1.548 0 0 1 0-3.094 1.55 1.55 0 0 1 1.547 1.547c0 .856-.69 1.547-1.547 1.547zm11.335 9.764h-2.668V12.25c0-.996-.02-2.278-1.386-2.278-1.39 0-1.604 1.085-1.604 2.206v4.25H8.116v-8.59h2.559v1.174h.036c.358-.675 1.23-1.387 2.527-1.387 2.7 0 3.203 1.78 3.203 4.095v4.709z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-livechat">
        <path d="M15.274 6.595c-.39-2.5-2.55-4.361-5.245-4.361-2.98 0-5.314 2.272-5.314 5.173v.262c-.001.016-.005.032-.005.05v5.121a2.577 2.577 0 0 1-2.397-2.563c0-.933.506-1.793 1.321-2.247a.572.572 0 0 0-.556-.999 3.717 3.717 0 0 0-1.908 3.246 3.718 3.718 0 0 0 3.714 3.714c.127 0 .256-.01.385-.023h.012c.019 0 .036-.003.054-.004h.004a.57.57 0 0 0 .514-.567V8.344c.002-.017.005-.033.005-.05v-.887c0-2.298 1.793-4.03 4.171-4.03S14.2 5.108 14.2 7.406v.237c-.003.024-.007.049-.007.075v5.519c-.001.015-.004.03-.004.044v1.286c0 .878-.614 1.491-1.492 1.491h-.77l-.016.002a1.49 1.49 0 0 0-1.388-.96h-.98a1.493 1.493 0 0 0-1.49 1.491c0 .823.668 1.49 1.49 1.491h.98c.606 0 1.126-.365 1.36-.886.015.002.029.006.045.006h.77c1.526 0 2.633-1.109 2.633-2.635v-.559a3.716 3.716 0 0 0 3.544-3.706 3.716 3.716 0 0 0-3.601-3.708zM10.523 16.94h-.98a.353.353 0 0 1-.347-.348c0-.189.16-.348.348-.348h.979c.188 0 .348.16.348.348 0 .189-.16.348-.348.348zm4.813-4.074V8.369c.003-.025.007-.05.007-.075v-.553a2.572 2.572 0 0 1 2.39 2.562c0 1.36-1.06 2.473-2.397 2.563z" fill-rule="nonzero" fill="currentColor" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-lock">
        <path d="M5 8h10v9H5zm2-3c0-1.657 1.347-3 3-3 1.657 0 3 1.347 3 3v3H7V5z" stroke="currentColor" stroke-width="1.5" fill="none" />
    </symbol>
    <symbol viewBox="0 0 512 512" id="icon-magnifier">
        <path d="M508.5 481.6l-129-129c-2.3-2.3-5.3-3.5-8.5-3.5h-10.3C395 312 416 262.5 416 208 416 93.1 322.9 0 208 0S0 93.1 0 208s93.1 208 208 208c54.5 0 104-21 141.1-55.2V371c0 3.2 1.3 6.2 3.5 8.5l129 129c4.7 4.7 12.3 4.7 17 0l9.9-9.9c4.7-4.7 4.7-12.3 0-17zM208 384c-97.3 0-176-78.7-176-176S110.7 32 208 32s176 78.7 176 176-78.7 176-176 176z" />
    </symbol>
    <symbol viewBox="0 0 512 512" id="icon-mail">
        <path d="M464 64H48C21.5 64 0 85.5 0 112v288c0 26.5 21.5 48 48 48h416c26.5 0 48-21.5 48-48V112c0-26.5-21.5-48-48-48zM48 96h416c8.8 0 16 7.2 16 16v41.4c-21.9 18.5-53.2 44-150.6 121.3-16.9 13.4-50.2 45.7-73.4 45.3-23.2.4-56.6-31.9-73.4-45.3C85.2 197.4 53.9 171.9 32 153.4V112c0-8.8 7.2-16 16-16zm416 320H48c-8.8 0-16-7.2-16-16V195c22.8 18.7 58.8 47.6 130.7 104.7 20.5 16.4 56.7 52.5 93.3 52.3 36.4.3 72.3-35.5 93.3-52.3 71.9-57.1 107.9-86 130.7-104.7v205c0 8.8-7.2 16-16 16z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-map-pin">
        <g stroke="currentColor" stroke-width="1.5" fill="none" fill-rule="evenodd">
            <path d="M10 17s5-4.15 5-9.027C15 5.226 12.761 3 10 3S5 5.226 5 7.973C5 12.85 10 17 10 17z" />
            <circle cx="10" cy="8" r="2" />
        </g>
    </symbol>
    <symbol viewBox="0 0 64 512" id="icon-menu">
        <path d="M32 224c17.7 0 32 14.3 32 32s-14.3 32-32 32-32-14.3-32-32 14.3-32 32-32zM0 136c0 17.7 14.3 32 32 32s32-14.3 32-32-14.3-32-32-32-32 14.3-32 32zm0 240c0 17.7 14.3 32 32 32s32-14.3 32-32-14.3-32-32-32-32 14.3-32 32z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-message">
        <g stroke="currentColor" stroke-width="1.5" fill="none" fill-rule="evenodd">
            <path d="M11 18c1.219 0 7 .127 8-2 .506-1.076-2.891-1.076-2-3 .391-.943 1-1.915 1-3a8 8 0 1 0-16 0c0 4.418 3.582 8 9 8z" />
            <path d="M6.5 8.5h6.083m-6.083 3h7.083" stroke-linecap="square" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-mic">
        <g fill="none" fill-rule="evenodd">
            <path d="M10 2.75A2.75 2.75 0 0 0 7.25 5.5v3a2.75 2.75 0 0 0 5.5 0v-3A2.75 2.75 0 0 0 10 2.75zM10 14v3" stroke="currentColor" stroke-width="1.5" />
            <path fill="currentColor" d="M7 17h6v1H7z" />
            <path d="M5 8c.049 4 1.716 6 5 6s4.951-2 5-6" stroke="currentColor" stroke-width="1.5" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-multi-line">
        <g stroke-width="1.5" stroke="currentColor" fill="none" fill-rule="evenodd">
            <path d="M12.5 5h5v6.25H5" />
            <path d="M8.17 15.714l-4.42-4.42 4.42-4.419" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-mute">
        <g fill="none" fill-rule="evenodd">
            <path d="M9.47 2.265A2.735 2.735 0 0 0 6.737 5v3.53a2.735 2.735 0 0 0 5.47 0V5A2.735 2.735 0 0 0 9.47 2.265zm0 11.559v3.529-3.53z" stroke="currentColor" stroke-width="1.5" />
            <path fill="currentColor" fill-rule="nonzero" d="M6.824 16.47h5.294v1.324H6.824z" />
            <path d="M4.176 8.53c.052 3.529 1.817 5.294 5.295 5.294 3.477 0 5.242-1.765 5.294-5.294" stroke="currentColor" stroke-width="1.5" />
            <path d="M18.238 2.353L1.529 16.676" stroke="currentColor" stroke-width="2.5" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-permalink">
        <path d="M9.548 14.23l-2.651 2.652a2.676 2.676 0 0 1-3.78 0 2.676 2.676 0 0 1 0-3.78L6.91 9.311a2.677 2.677 0 0 1 3.781 0 .669.669 0 0 0 .945-.946 4.015 4.015 0 0 0-5.67 0l-3.792 3.792a4.014 4.014 0 0 0 0 5.67 4.014 4.014 0 0 0 5.67 0l2.65-2.65a.669.669 0 0 0-.945-.947zm8.28-12.057a4.014 4.014 0 0 0-5.67 0L9.506 4.824a.668.668 0 1 0 .946.945l2.651-2.651a2.676 2.676 0 0 1 3.78 0 2.676 2.676 0 0 1 0 3.78L13.09 10.69a2.678 2.678 0 0 1-3.781 0 .668.668 0 1 0-.945.945 4.015 4.015 0 0 0 5.67 0l3.793-3.792a4.014 4.014 0 0 0 0-5.67z" fill-rule="nonzero" fill="currentColor" />
    </symbol>
    <symbol viewBox="0 0 384 512" id="icon-pin">
        <path d="M300.79 203.91L290.67 128H328c13.25 0 24-10.75 24-24V24c0-13.25-10.75-24-24-24H56C42.75 0 32 10.75 32 24v80c0 13.25 10.75 24 24 24h37.33l-10.12 75.91C34.938 231.494 0 278.443 0 335.24c0 8.84 7.16 16 16 16h160v120.779c0 .654.08 1.306.239 1.94l8 32c2.009 8.037 13.504 8.072 15.522 0l8-32a7.983 7.983 0 0 0 .239-1.94V351.24h160c8.84 0 16-7.16 16-16 0-56.797-34.938-103.746-83.21-131.33zM33.26 319.24c6.793-42.889 39.635-76.395 79.46-94.48L128 96H64V32h256v64h-64l15.28 128.76c40.011 18.17 72.694 51.761 79.46 94.48H33.26z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-plus">
        <path d="M10 5v10m5-5H5" stroke="currentColor" stroke-width="1.5" fill="none" stroke-linecap="square" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-queue">
        <path d="M9.98 11.894c-.1 0-.2-.025-.29-.077L1.493 7.161a.587.587 0 0 1-.01-1.017l8.238-4.899a.588.588 0 0 1 .6-.001l8.195 4.828a.588.588 0 0 1-.006 1.017l-8.237 4.727a.586.586 0 0 1-.293.078zM2.954 6.638l7.025 3.991 7.069-4.057-7.025-4.138-7.07 4.204z" />
        <path d="M9.98 15.172c-.1 0-.2-.025-.29-.076l-8.197-4.657a.588.588 0 1 1 .581-1.022l7.905 4.49 7.946-4.56a.588.588 0 1 1 .585 1.02l-8.237 4.727a.584.584 0 0 1-.293.078z" />
        <path d="M9.98 18.447c-.1 0-.2-.025-.29-.076l-8.197-4.657a.588.588 0 1 1 .581-1.022l7.905 4.49 7.946-4.56a.588.588 0 0 1 .585 1.02l-8.237 4.727a.584.584 0 0 1-.293.078z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-quote">
        <path d="M5.7 4.5a3.2 3.2 0 0 1 3.2 3.2c0 4.8-2.622 8-5.6 8 1.467-2.113 1.933-3.713 1.4-4.8a2.2 2.2 0 0 1-2.2-2.2v-1a3.2 3.2 0 0 1 3.2-3.2zm9 0a3.2 3.2 0 0 1 3.2 3.2c0 4.8-2.622 8-5.6 8 1.467-2.113 1.933-3.713 1.4-4.8a2.2 2.2 0 0 1-2.2-2.2v-1a3.2 3.2 0 0 1 3.2-3.2z" stroke-width="1.5" stroke="currentColor" fill="none" stroke-linejoin="round" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-reload">
        <g stroke="currentColor" stroke-width="1.5" fill="none" fill-rule="evenodd">
            <path d="M5.905 14.322a6 6 0 1 0 0-8.485l-.873.873" />
            <path d="M9.981 7.417L5 6.98 5.436 2" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-send">
        <path d="M17.28 1.186L1.562 10.253a1.123 1.123 0 0 0 .134 2.01l4.919 2.035v3.58c0 1.059 1.326 1.518 1.99.711L10.734 16l4.434 1.832a1.122 1.122 0 0 0 1.537-.867L18.951 2.33c.144-.937-.863-1.61-1.67-1.144zM7.738 17.877v-3.116l1.912.79-1.912 2.326zm7.86-1.084l-7.236-2.99 7-8.273c.169-.197-.101-.463-.298-.295L6.105 12.87l-3.982-1.642 15.72-9.07-2.247 14.635z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-share">
        <g stroke="currentColor" stroke-width="1.5" fill="none" fill-rule="evenodd">
            <path d="M10 12.5V2.917" stroke-linecap="square" />
            <path d="M6.667 5.419l3.291-3.292L13.25 5.42m-.75 2.913H15V17.5H5V8.333h2.5" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-sign-out">
        <path d="M2.684 3h4.63c.232 0 .421.19.421.42v.282c0 .231-.19.42-.42.42H2.683a.563.563 0 0 0-.561.562v10.102c0 .309.252.562.56.562h4.631c.232 0 .421.189.421.42v.281c0 .232-.19.421-.42.421H2.683c-.93 0-1.684-.754-1.684-1.684V4.684A1.686 1.686 0 0 1 2.684 3zm9.787.684l-.25.25a.421.421 0 0 0 0 .595l4.63 4.61H7.034c-.231 0-.42.19-.42.42v.351c0 .232.189.421.42.421h9.819l-4.627 4.61a.421.421 0 0 0 0 .596l.25.249a.421.421 0 0 0 .595 0l5.77-5.753a.421.421 0 0 0 0-.596l-5.773-5.753a.421.421 0 0 0-.596 0z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-snippet">
        <g stroke="currentColor" stroke-width="1.5" fill="none" fill-rule="evenodd">
            <path d="M5.833 13.88L1.953 10l3.88-3.88" />
            <path d="M11.941 2.756L8.06 17.244" stroke-linecap="square" />
            <path d="M14.167 6.12l3.88 3.88-3.88 3.88" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-star">
        <path d="M10 15l-4.898 2.575.935-5.454-3.962-3.863 5.476-.796L10 2.5l2.45 4.962 5.475.796-3.962 3.863.935 5.454z" stroke-width="1.5" stroke="currentColor" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-strike">
        <g fill="none" fill-rule="evenodd">
            <path d="M5.775 13.259c.074.989.498 1.78 1.273 2.372.775.593 1.768.889 2.98.889 1.312 0 2.352-.311 3.122-.933.77-.621 1.155-1.458 1.155-2.51 0-.842-.258-1.511-.774-2.008-.516-.498-1.366-.894-2.551-1.19L9.782 9.56c-.788-.2-1.353-.442-1.694-.722a1.35 1.35 0 0 1-.512-1.095c0-.582.231-1.047.694-1.396.463-.35 1.075-.524 1.837-.524.714 0 1.3.165 1.758.496.457.33.736.79.837 1.377h1.436c-.058-.926-.46-1.685-1.206-2.278-.746-.592-1.672-.888-2.777-.888-1.212 0-2.189.3-2.932.9-.743.6-1.115 1.387-1.115 2.36 0 .815.235 1.467.706 1.957.471.489 1.225.866 2.262 1.13l1.468.381c.788.196 1.367.455 1.737.778.37.322.556.727.556 1.214 0 .566-.253 1.035-.758 1.408s-1.144.56-1.916.56c-.815 0-1.487-.178-2.016-.532-.529-.355-.838-.83-.928-1.428H5.775z" fill="currentColor" />
            <path d="M4.375 10h11.25" stroke="currentColor" stroke-width="1.5" stroke-linecap="square" />
        </g>
    </symbol>
    <symbol viewBox="0 0 640 512" id="icon-team">
        <path d="M408.795 244.28C423.843 224.794 432 201.025 432 176c0-61.855-50.043-112-112-112-61.853 0-112 50.041-112 112 0 25.025 8.157 48.794 23.205 68.28-12.93 3.695-71.205 25.768-71.205 92.757v60.677C160 425.442 182.558 448 210.286 448h219.429C457.442 448 480 425.442 480 397.714v-60.677c0-66.985-58.234-89.051-71.205-92.757zM320 96c44.183 0 80 35.817 80 80s-35.817 80-80 80-80-35.817-80-80 35.817-80 80-80zm128 301.714c0 10.099-8.187 18.286-18.286 18.286H210.286C200.187 416 192 407.813 192 397.714v-60.677c0-28.575 18.943-53.688 46.418-61.538l20.213-5.775C276.708 281.614 297.862 288 320 288s43.292-6.386 61.369-18.275l20.213 5.775C429.057 283.35 448 308.462 448 337.037v60.677zm-304 0V384H45.714C38.14 384 32 377.86 32 370.286v-45.508c0-21.431 14.207-40.266 34.813-46.153l12.895-3.684C93.904 283.237 110.405 288 128 288a95.582 95.582 0 0 0 29.234-4.564c5.801-10.547 13.46-20.108 22.904-28.483 9.299-8.247 18.915-14.143 27.098-18.247C197.22 218.209 192 197.557 192 176c0-16.214 2.993-31.962 8.708-46.618C183.09 108.954 157.03 96 128 96c-52.935 0-96 43.065-96 96 0 21.776 7.293 41.878 19.558 58.003C25.677 259.796 0 286.423 0 324.778v45.508C0 395.493 20.507 416 45.714 416h100.871A66.078 66.078 0 0 1 144 397.714zM128 128c35.346 0 64 28.654 64 64s-28.654 64-64 64-64-28.654-64-64 28.654-64 64-64zm460.442 122.003C600.707 233.878 608 213.776 608 192c0-52.935-43.065-96-96-96-29.031 0-55.091 12.955-72.71 33.385C445.006 144.041 448 159.788 448 176c0 21.557-5.219 42.207-15.235 60.704 8.19 4.106 17.812 10.004 27.115 18.256 9.439 8.373 17.094 17.933 22.892 28.478A95.573 95.573 0 0 0 512 288c17.595 0 34.096-4.763 48.292-13.06l12.895 3.684C593.793 284.512 608 303.347 608 324.778v45.508c0 7.574-6.14 13.714-13.714 13.714H496v13.714c0 6.343-.914 12.473-2.585 18.286h100.871C619.493 416 640 395.493 640 370.286v-45.508c0-38.369-25.689-64.987-51.558-74.775zM512 256c-35.346 0-64-28.654-64-64s28.654-64 64-64 64 28.654 64 64-28.654 64-64 64z" />
    </symbol>
    <symbol viewBox="0 0 20 20  " id="icon-trash">
        <g stroke="currentColor" stroke-width="1.5" fill="none" fill-rule="evenodd">
            <path d="M4 6h12l-1 12H5zm8-2.5a2 2 0 1 0-4 0" />
            <path d="M8 10v5m4-5v5" stroke-linecap="square" />
            <path d="M2.5 3.5h15" stroke-linecap="round" stroke-linejoin="round" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-twitter">
        <path d="M17.13 6.634c.01.16.01.319.01.478 0 4.864-3.701 10.468-10.467 10.468-2.085 0-4.021-.604-5.65-1.652.296.035.58.046.888.046 1.72 0 3.304-.581 4.568-1.572a3.686 3.686 0 0 1-3.44-2.551c.228.034.456.056.695.056.33 0 .66-.045.968-.125a3.68 3.68 0 0 1-2.95-3.61v-.046c.49.273 1.06.444 1.663.467a3.677 3.677 0 0 1-1.64-3.064c0-.684.182-1.31.5-1.857a10.458 10.458 0 0 0 7.587 3.85 4.153 4.153 0 0 1-.091-.843A3.676 3.676 0 0 1 13.45 3a3.67 3.67 0 0 1 2.688 1.162 7.243 7.243 0 0 0 2.335-.889 3.67 3.67 0 0 1-1.617 2.028 7.376 7.376 0 0 0 2.118-.57 7.91 7.91 0 0 1-1.845 1.903z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-upload">
        <path d="M16.89 16.188a.705.705 0 0 1-.703.703.705.705 0 0 1-.703-.703c0-.387.317-.704.704-.704.386 0 .703.317.703.704zm-2.953-.704a.705.705 0 0 0-.703.704c0 .386.317.703.704.703a.705.705 0 0 0 .703-.703.705.705 0 0 0-.704-.704zM19 13.797v3.656c0 .854-.693 1.547-1.547 1.547H2.547A1.547 1.547 0 0 1 1 17.453v-3.656c0-.854.693-1.547 1.547-1.547h4.36V8.759H5.053c-1.252 0-1.878-1.515-.995-2.401L9.005 1.41a1.409 1.409 0 0 1 1.99 0l4.946 4.947c.886.886.257 2.401-.995 2.401h-1.852v3.491h4.36c.853 0 1.546.693 1.546 1.547zM8.031 7.634v6.585c0 .154.127.281.281.281h3.376a.282.282 0 0 0 .28-.281V7.634h2.978c.25 0 .377-.302.2-.482L10.2 2.206a.282.282 0 0 0-.397 0L4.857 7.152a.283.283 0 0 0 .2.482h2.974zm9.844 6.163a.423.423 0 0 0-.422-.422h-4.36v.844c0 .777-.629 1.406-1.405 1.406H8.312c-.776 0-1.406-.63-1.406-1.406v-.844h-4.36a.423.423 0 0 0-.421.422v3.656c0 .232.19.422.422.422h14.906c.232 0 .422-.19.422-.422v-3.656z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-user">
        <g fill="none" fill-rule="evenodd">
            <path d="M0 0h20v20H0z" />
            <path d="M4 15.106c0-3.783 4.5-3.026 4.5-4.54 0 0 .086-1.004-.41-1.513C7.473 8.423 7 7.665 7 6.405 7 4.525 8.343 3 10 3s3 1.524 3 3.405c0 1.243-.46 2.017-1.105 2.648-.472.496-.395 1.514-.395 1.514 0 1.513 4.5.756 4.5 4.54 0 0-1.195.893-6 .893s-6-.894-6-.894z" stroke="currentColor" stroke-width="1.5" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-user-rounded">
        <g transform="translate(2.5 2.5)" stroke="currentColor" stroke-width="1.5" fill="none" fill-rule="evenodd">
            <rect x=".75" y=".75" width="13.5" height="13.5" rx="2" />
            <path d="M2.502 14.167c0-3.125 3.748-2.5 3.748-3.75 0 0 .072-.83-.34-1.25C5.394 8.646 5 8.02 5 6.979c0-1.553 1.12-2.812 2.5-2.812S10 5.426 10 6.979c0 1.027-.384 1.666-.922 2.188-.392.41-.328 1.25-.328 1.25 0 1.25 3.748.625 3.748 3.75" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-video">
        <g stroke-width="1.5" stroke="currentColor" fill="none" fill-rule="evenodd">
            <path d="M3 8h10v8H3zm10 2.376l4.048-1.314c.526-.171.952.137.952.69v4.494c0 .552-.426.862-.952.69L13 13.624v-3.247z" />
            <path d="M5.5 5h5" stroke-linecap="square" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-warning">
        <g stroke="currentColor" stroke-width="1.5" fill="none" fill-rule="evenodd">
            <path d="M10 3l8 14H2z" />
            <path d="M10 9v5" stroke-linecap="square" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-checkmark-circled">
        <path d="M486.4 1024c-129.922 0-252.067-50.594-343.936-142.464s-142.464-214.014-142.464-343.936c0-129.923 50.595-252.067 142.464-343.936s214.013-142.464 343.936-142.464c129.922 0 252.067 50.595 343.936 142.464s142.464 214.014 142.464 343.936-50.594 252.067-142.464 343.936c-91.869 91.87-214.014 142.464-343.936 142.464zM486.4 102.4c-239.97 0-435.2 195.23-435.2 435.2s195.23 435.2 435.2 435.2 435.2-195.23 435.2-435.2-195.23-435.2-435.2-435.2z" />
        <path d="M384 742.4c-6.552 0-13.102-2.499-18.102-7.499l-153.6-153.6c-9.997-9.997-9.997-26.206 0-36.203 9.998-9.997 26.206-9.997 36.205 0l135.498 135.498 340.299-340.298c9.997-9.997 26.206-9.997 36.203 0 9.998 9.998 9.998 26.206 0 36.205l-358.4 358.4c-5 4.998-11.55 7.498-18.102 7.498z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-cross-circled">
        <path d="M733.808 723.266l-208.874-185.666 208.874-185.667c10.566-9.394 11.518-25.574 2.126-36.141-9.394-10.566-25.574-11.522-36.142-2.126l-213.392 189.682-213.392-189.68c-10.568-9.392-26.749-8.44-36.141 2.126-9.394 10.566-8.442 26.749 2.126 36.141l208.874 185.666-208.875 185.666c-10.566 9.394-11.518 25.574-2.126 36.142 5.059 5.691 12.085 8.592 19.142 8.592 6.048 0 12.122-2.131 16.998-6.466l213.394-189.683 213.392 189.683c4.878 4.334 10.949 6.466 16.998 6.466 7.058 0 14.086-2.902 19.144-8.592 9.392-10.568 8.44-26.749-2.126-36.142z" />
        <path d="M486.4 1024c-129.922 0-252.067-50.594-343.936-142.464s-142.464-214.014-142.464-343.936c0-129.923 50.595-252.067 142.464-343.936s214.013-142.464 343.936-142.464c129.922 0 252.067 50.595 343.936 142.464s142.464 214.014 142.464 343.936-50.594 252.067-142.464 343.936c-91.869 91.87-214.014 142.464-343.936 142.464zM486.4 102.4c-239.97 0-435.2 195.23-435.2 435.2s195.23 435.2 435.2 435.2 435.2-195.23 435.2-435.2-195.23-435.2-435.2-435.2z" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-jump">
        <path d="M11.6 7.257V4L18 9.7l-6.4 5.7v-3.257S2 11.385 2 16c0-9.23 9.6-8.743 9.6-8.743z" stroke="currentColor" stroke-width="1.5" fill="none" fill-rule="evenodd" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-flag">
        <path d="M12.928 6.063l3.263-3.77a.74.74 0 0 0 .112-.759.71.71 0 0 0-.647-.422H3.141v17.72h1.406v-7.876h11.11a.71.71 0 0 0 .646-.422.691.691 0 0 0-.112-.759l-3.263-3.713zM4.547 9.578V2.547h9.562l-2.643 3.065c-.225.254-.225.647 0 .929l2.643 3.065H4.547v-.028z" fill-rule="nonzero" fill="currentColor" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-circle">
        <circle cx="10" cy="10" r="9" fill="currentColor" fill-rule="evenodd" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-cross">
            <path d="M16.364 3.636l-6.018 6.018-6.71 6.71m12.728 0L3.636 3.636" stroke="currentColor" stroke-width="1.5" fill="none" fill-rule="evenodd" stroke-linecap="square" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-post">
        <g fill="none" fill-rule="evenodd">
            <path d="M0 0h20v20H0z" />
            <path stroke="currentColor" stroke-width="1.5" d="M5 3h6l4 4v10H5z" />
            <path d="M8.5 10.5h3M8.5 13.5h3" stroke="currentColor" stroke-width="1.5" stroke-linecap="square" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-discover">
        <g transform="translate(1 1)" fill="none" fill-rule="evenodd">
            <path d="M0 0h18v18H0z" />
            <circle stroke="currentColor" stroke-width="1.5" cx="9" cy="9" r="6.75" />
            <path d="M9 15.75c1.5 0 3-3.022 3-6.75s-1.5-6.75-3-6.75S6 5.272 6 9s1.5 6.75 3 6.75z" stroke="currentColor" stroke-width="1.5" />
            <path d="M2.25 9c0 1.5 3.022 3 6.75 3s6.75-1.5 6.75-3S12.728 6 9 6 2.25 7.5 2.25 9z" stroke="currentColor" stroke-width="1.5" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-import">
        <g stroke="currentColor" stroke-width="1.5" fill="none" fill-rule="evenodd">
            <path d="M10 7.5v9.583" stroke-linecap="square" />
            <path d="M13.333 14.581l-3.291 3.292L6.75 14.58m.75-2.913H5V2.5h10v9.167h-2.5" />
        </g>
    </symbol>
    <symbol viewBox="0 0 89 83" id="icon-modal-warning">
        <g fill="currentColor" fill-rule="evenodd">
            <path d="M44.488 29a2.988 2.988 0 0 1 2.989 2.988v23.056a2.988 2.988 0 1 1-5.977 0V31.988A2.988 2.988 0 0 1 44.488 29zm-.106 34.021c1.947 0 3.382 1.52 3.382 3.493 0 2-1.435 3.519-3.382 3.519-1.946 0-3.382-1.52-3.382-3.52 0-1.972 1.436-3.492 3.382-3.492z" />
            <path d="M7.471 76.881H81.46L44.465 8.713 7.471 76.881zm78.4 5.626H3.06a3 3 0 0 1-2.637-4.431L41.828 1.778a3 3 0 0 1 5.274 0l41.405 76.298a3 3 0 0 1-2.637 4.43z" fill-rule="nonzero" />
        </g>
    </symbol>
    <symbol viewBox="0 0 82 82" id="icon-modal-success">
        <g fill="currentColor" fill-rule="evenodd">
            <path d="M41 82C18.356 82 0 63.644 0 41S18.356 0 41 0s41 18.356 41 41-18.356 41-41 41zm0-6.308c19.16 0 34.692-15.532 34.692-34.692S60.16 6.308 41 6.308 6.308 21.84 6.308 41 21.84 75.692 41 75.692z" fill-rule="nonzero" />
            <path d="M33.86 50.585l-8.671-8.723a2.446 2.446 0 0 0-3.47 0 2.475 2.475 0 0 0 0 3.49L31.76 55.45a3 3 0 0 0 4.23.026l23.716-23.277a2.444 2.444 0 0 0 .021-3.467 2.48 2.48 0 0 0-3.493-.025L33.861 50.585z" stroke="currentColor" />
        </g>
    </symbol>
    <symbol viewBox="0 0 82 82" id="icon-modal-info">
        <g fill="currentColor" fill-rule="evenodd">
            <path d="M40.988 61.033a2.988 2.988 0 0 0 2.989-2.989V34.988a2.988 2.988 0 1 0-5.977 0v23.056a2.988 2.988 0 0 0 2.988 2.989zm-.106-34.021c1.947 0 3.382-1.52 3.382-3.493 0-2-1.435-3.519-3.382-3.519-1.946 0-3.382 1.52-3.382 3.52 0 1.972 1.436 3.492 3.382 3.492z" />
            <path d="M41 82C18.356 82 0 63.644 0 41S18.356 0 41 0s41 18.356 41 41-18.356 41-41 41zm0-6.308c19.16 0 34.692-15.532 34.692-34.692S60.16 6.308 41 6.308 6.308 21.84 6.308 41 21.84 75.692 41 75.692z" fill-rule="nonzero" />
        </g>
    </symbol>
    <symbol viewBox="0 0 82 82" id="icon-modal-error">
        <g fill="currentColor" fill-rule="evenodd">
            <path d="M41 82C18.356 82 0 63.644 0 41S18.356 0 41 0s41 18.356 41 41-18.356 41-41 41zm0-6.308c19.16 0 34.692-15.532 34.692-34.692S60.16 6.308 41 6.308 6.308 21.84 6.308 41 21.84 75.692 41 75.692z" fill-rule="nonzero" />
            <path d="M56.6 56.203a2.988 2.988 0 0 0 0-4.226L30.796 26.175a2.988 2.988 0 0 0-4.226 4.226l25.802 25.802a2.988 2.988 0 0 0 4.226 0z" />
            <path d="M26.57 56.203a2.988 2.988 0 0 0 4.227 0L56.6 30.401a2.988 2.988 0 0 0-4.226-4.226L26.571 51.977a2.988 2.988 0 0 0 0 4.226z" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-file-document">
        <g fill="#FFF" fill-rule="evenodd">
            <path opacity=".75" d="M1 5h7.637v7.637H1z" />
            <path d="M10.273 5h5.455v1.091h-5.455z" />
            <path opacity=".6" d="M10.273 8.273h7.091v1.091h-7.091zM10.273 11.546h8.728v1.091h-8.728zM1 14.819h15.82v1.091H1z" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-file-generic">
        <g fill="#FFF" fill-rule="evenodd">
            <path d="M1 5h5.455v1.091H1z" />
            <path opacity=".6" d="M1 8.273h16.365v1.091H1zM1 11.546h18.001v1.091H1zM1 14.819h15.82v1.091H1z" />
        </g>
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-file-pdf">
        <path d="M8.848 2.08l11.217 15.147L2.24 19.732z" fill="#FFF" fill-rule="evenodd" opacity=".75" />
    </symbol>
    <symbol viewBox="0 0 20 20" id="icon-file-sheets">
        <g transform="translate(1 1)" fill="#FFF" fill-rule="evenodd" opacity=".75">
            <circle cx="6.12" cy="6.12" r="6.12" />
            <path d="M4.32 5.04h12.96V18H4.32z" />
        </g>
    </symbol>
    <symbol viewBox="0 0 24 24" id="icon-arrow-down">
        <path d="M18.585 12.1L12.5 18.185 6.415 12.1" stroke="currentColor" stroke-width="1.5" fill="none" fill-rule="evenodd" />
    </symbol>
    <symbol viewBox="0 0 320 512" id="icon-mobile">
        <path d="M192 416c0 17.7-14.3 32-32 32s-32-14.3-32-32 14.3-32 32-32 32 14.3 32 32zM320 48v416c0 26.5-21.5 48-48 48H48c-26.5 0-48-21.5-48-48V48C0 21.5 21.5 0 48 0h224c26.5 0 48 21.5 48 48zm-32 0c0-8.8-7.2-16-16-16H48c-8.8 0-16 7.2-16 16v416c0 8.8 7.2 16 16 16h224c8.8 0 16-7.2 16-16V48z" />
    </symbol>
    <symbol viewBox="0 0 448 512" id="icon-hand-pointer">
        <path d="M360.543 188.156c-17.46-28.491-54.291-37.063-82.138-19.693-15.965-20.831-42.672-28.278-66.119-20.385V60.25c0-33.222-26.788-60.25-59.714-60.25S92.857 27.028 92.857 60.25v181.902c-20.338-13.673-47.578-13.89-68.389 1.472-26.556 19.605-32.368 57.08-13.132 83.926l114.271 159.5C136.803 502.673 154.893 512 174 512h185.714c27.714 0 51.832-19.294 58.145-46.528l28.571-123.25a60.769 60.769 0 0 0 1.57-13.723v-87c0-45.365-48.011-74.312-87.457-53.343zM82.097 275.588l28.258 39.439a7.999 7.999 0 1 0 14.503-4.659V60.25c0-37.35 55.428-37.41 55.428 0V241.5a8 8 0 0 0 8 8h7.144a8 8 0 0 0 8-8v-36.25c0-37.35 55.429-37.41 55.429 0v36.25a8 8 0 0 0 8 8H274a8 8 0 0 0 8-8v-21.75c0-37.351 55.429-37.408 55.429 0v21.75a8 8 0 0 0 8 8h7.143a8 8 0 0 0 8-8c0-37.35 55.429-37.41 55.429 0v87c0 2.186-.25 4.371-.742 6.496l-28.573 123.251C383.717 471.055 372.626 480 359.715 480H174c-8.813 0-17.181-4.332-22.381-11.588l-114.283-159.5c-22.213-31.004 23.801-62.575 44.761-33.324zM180.285 401v-87a8 8 0 0 1 8-8h7.144a8 8 0 0 1 8 8v87a8 8 0 0 1-8 8h-7.144a8 8 0 0 1-8-8zm78.572 0v-87a8 8 0 0 1 8-8H274a8 8 0 0 1 8 8v87a8 8 0 0 1-8 8h-7.143a8 8 0 0 1-8-8zm78.572 0v-87a8 8 0 0 1 8-8h7.143a8 8 0 0 1 8 8v87a8 8 0 0 1-8 8h-7.143a8 8 0 0 1-8-8z" />
    </symbol>
    <symbol viewBox="0 0 512 512" id="icon-shield">
        <path d="M466.5 83.7l-192-80a48.15 48.15 0 0 0-36.9 0l-192 80C27.7 91.1 16 108.6 16 128c0 198.5 114.5 335.7 221.5 380.3 11.8 4.9 25.1 4.9 36.9 0C360.1 472.6 496 349.3 496 128c0-19.4-11.7-36.9-29.5-44.3zM262.2 478.8c-3.9 1.6-8.3 1.6-12.3 0C152 440 48 304 48 128c0-6.5 3.9-12.3 9.8-14.8l192-80c3.8-1.6 8.3-1.7 12.3 0l192 80c6 2.5 9.8 8.3 9.8 14.8.1 176-103.9 312-201.7 350.8z" />
    </symbol>
    <symbol viewBox="0 0 512 512" id="icon-shield-alt">
        <path d="M256 410.955V99.999l-142.684 59.452C123.437 279.598 190.389 374.493 256 410.955zm-32-66.764c-36.413-39.896-65.832-97.846-76.073-164.495L224 147.999v196.192zM466.461 83.692l-192-80a47.996 47.996 0 0 0-36.923 0l-192 80A48 48 0 0 0 16 128c0 198.487 114.495 335.713 221.539 380.308a48 48 0 0 0 36.923 0C360.066 472.645 496 349.282 496 128a48 48 0 0 0-29.539-44.308zM262.154 478.768a16.64 16.64 0 0 1-12.31-.001C152 440 48 304 48 128c0-6.48 3.865-12.277 9.846-14.769l192-80a15.99 15.99 0 0 1 12.308 0l192 80A15.957 15.957 0 0 1 464 128c0 176-104 312-201.846 350.768z" />
    </symbol>
    <symbol viewBox="0 0 512 512" id="icon-shield-check">
        <path d="M466.461 83.692l-192-80a47.996 47.996 0 0 0-36.923 0l-192 80A48 48 0 0 0 16 128c0 198.487 114.495 335.713 221.539 380.308a48 48 0 0 0 36.923 0C360.066 472.645 496 349.282 496 128a48 48 0 0 0-29.539-44.308zM262.154 478.768a16.64 16.64 0 0 1-12.31-.001C152 440 48 304 48 128c0-6.48 3.865-12.277 9.846-14.769l192-80a15.99 15.99 0 0 1 12.308 0l192 80A15.957 15.957 0 0 1 464 128c0 176-104 312-201.846 350.768zm144.655-299.505l-180.48 179.032c-4.705 4.667-12.303 4.637-16.97-.068l-85.878-86.572c-4.667-4.705-4.637-12.303.068-16.97l8.52-8.451c4.705-4.667 12.303-4.637 16.97.068l68.976 69.533 163.441-162.13c4.705-4.667 12.303-4.637 16.97.068l8.451 8.52c4.668 4.705 4.637 12.303-.068 16.97z" />
    </symbol>
    <symbol viewBox="0 0 448 512" id="icon-check">
        <path d="M413.505 91.951L133.49 371.966l-98.995-98.995c-4.686-4.686-12.284-4.686-16.971 0L6.211 284.284c-4.686 4.686-4.686 12.284 0 16.971l118.794 118.794c4.686 4.686 12.284 4.686 16.971 0l299.813-299.813c4.686-4.686 4.686-12.284 0-16.971l-11.314-11.314c-4.686-4.686-12.284-4.686-16.97 0z" />
    </symbol>
    <symbol viewBox="0 0 640 512" id="icon-team">
        <path d="M573.127 249.095C584.979 233.127 592 213.369 592 192c0-52.935-43.065-96-96-96-26.331 0-50.217 10.658-67.578 27.885a128.993 128.993 0 0 0-17.913-22.394C386.334 77.314 354.19 64 320 64s-66.334 13.314-90.51 37.49a129.115 129.115 0 0 0-17.913 22.394C194.217 106.658 170.331 96 144 96c-52.935 0-96 43.065-96 96 0 21.369 7.021 41.127 18.873 57.095C28.987 255.378 0 288.36 0 328v44c0 24.262 19.738 44 44 44h117.677c5.238 18.445 22.222 32 42.323 32h232c20.102 0 37.085-13.555 42.323-32H596c24.262 0 44-19.738 44-44v-44c0-39.64-28.986-72.622-66.873-78.905zM496 128c35.346 0 64 28.654 64 64s-28.654 64-64 64c-22.083 0-41.554-11.185-53.057-28.199C446.27 216.314 448 204.291 448 192s-1.73-24.314-5.057-35.801C454.446 139.185 473.917 128 496 128zM320 96c53.02 0 96 42.981 96 96s-42.98 96-96 96-96-42.981-96-96 42.98-96 96-96zm-176 32c22.083 0 41.554 11.185 53.057 28.199C193.73 167.686 192 179.709 192 192s1.73 24.314 5.057 35.801C185.554 244.815 166.083 256 144 256c-35.346 0-64-28.654-64-64s28.654-64 64-64zm16 224v32H44c-6.627 0-12-5.373-12-12v-44c0-26.51 21.49-48 48-48h25.655c24.374 10.662 52.272 10.681 76.689 0h22.81C178.452 292.976 160 320.372 160 352zm288 52c0 6.627-5.373 12-12 12H204c-6.627 0-12-5.373-12-12v-52c0-26.51 21.49-48 48-48h17.929c37.818 21.031 85.208 21.651 124.142 0H400c26.51 0 48 21.49 48 48v52zm160-32c0 6.627-5.373 12-12 12H480v-32c0-31.628-18.452-59.024-45.154-72h22.81c24.374 10.662 52.272 10.681 76.689 0H560c26.51 0 48 21.49 48 48v44z" />
    </symbol>
    <symbol viewBox="0 0 640 512" id="icon-user-plus">
        <path d="M640 252v8c0 6.627-5.373 12-12 12h-68v68c0 6.627-5.373 12-12 12h-8c-6.627 0-12-5.373-12-12v-68h-68c-6.627 0-12-5.373-12-12v-8c0-6.627 5.373-12 12-12h68v-68c0-6.627 5.373-12 12-12h8c6.627 0 12 5.373 12 12v68h68c6.627 0 12 5.373 12 12zm-264.942 32.165l-43.497-12.428C355.115 245.342 368 211.663 368 176c0-79.525-64.339-144-144-144-79.525 0-144 64.339-144 144 0 35.663 12.885 69.342 36.439 95.737l-43.497 12.428C17.501 300.005 0 350.424 0 380.866v39.705C0 453.34 26.66 480 59.429 480h329.143C421.34 480 448 453.34 448 420.571v-39.705c0-57.659-43.675-88.339-72.942-96.701zM224 64c61.856 0 112 50.144 112 112s-50.144 112-112 112-112-50.144-112-112S162.144 64 224 64zm192 356.571C416 435.72 403.72 448 388.571 448H59.429C44.28 448 32 435.72 32 420.571v-39.705c0-30.616 20.296-57.522 49.733-65.933l63.712-18.203C168.611 311.87 195.679 320 224 320s55.389-8.13 78.555-23.27l63.712 18.203C395.704 323.344 416 350.251 416 380.866v39.705z" />
    </symbol>
    <symbol viewBox="0 0 512 512" id="icon-globe">
        <path d="M504 256C504 118.815 392.705 8 256 8 119.371 8 8 118.74 8 256c0 136.938 111.041 248 248 248 136.886 0 248-110.987 248-248zm-41.625 64h-99.434c6.872-42.895 6.6-86.714.055-128h99.38c12.841 41.399 12.843 86.598-.001 128zM256.001 470.391c-30.732-27.728-54.128-69.513-67.459-118.391h134.917c-13.332 48.887-36.73 90.675-67.458 118.391zM181.442 320c-7.171-41.387-7.349-85.537.025-128h149.067c7.371 42.453 7.197 86.6.025 128H181.442zM256 41.617c33.557 30.295 55.554 74.948 67.418 118.383H188.582c11.922-43.649 33.98-88.195 67.418-118.383zM449.544 160h-93.009c-10.928-44.152-29.361-83.705-53.893-114.956C366.825 59.165 420.744 101.964 449.544 160zM209.357 45.044C184.826 76.293 166.393 115.847 155.464 160H62.456C91.25 101.975 145.162 59.169 209.357 45.044zM49.625 192h99.38c-6.544 41.28-6.818 85.1.055 128H49.625c-12.842-41.399-12.844-86.598 0-128zm12.831 160h93.122c11.002 44.176 29.481 83.824 53.833 114.968C144.875 452.786 91.108 409.738 62.456 352zm240.139 114.966c24.347-31.138 42.825-70.787 53.827-114.966h93.121c-28.695 57.827-82.504 100.802-146.948 114.966z" />
    </symbol>
    <symbol viewBox="0 0 512 512" id="icon-th-list">
        <path d="M0 80v352c0 26.51 21.49 48 48 48h416c26.51 0 48-21.49 48-48V80c0-26.51-21.49-48-48-48H48C21.49 32 0 53.49 0 80zm480 0v90.667H192V64h272c8.837 0 16 7.163 16 16zm0 229.333H192V202.667h288v106.666zM32 202.667h128v106.667H32V202.667zM160 64v106.667H32V80c0-8.837 7.163-16 16-16h112zM32 432v-90.667h128V448H48c-8.837 0-16-7.163-16-16zm160 16V341.333h288V432c0 8.837-7.163 16-16 16H192z" />
    </symbol>
    <symbol viewBox="0 0 512 512" id="icon-list">
        <path d="M506 114H134a6 6 0 0 1-6-6V84a6 6 0 0 1 6-6h372a6 6 0 0 1 6 6v24a6 6 0 0 1-6 6zm6 154v-24a6 6 0 0 0-6-6H134a6 6 0 0 0-6 6v24a6 6 0 0 0 6 6h372a6 6 0 0 0 6-6zm0 160v-24a6 6 0 0 0-6-6H134a6 6 0 0 0-6 6v24a6 6 0 0 0 6 6h372a6 6 0 0 0 6-6zM84 120V72c0-6.627-5.373-12-12-12H24c-6.627 0-12 5.373-12 12v48c0 6.627 5.373 12 12 12h48c6.627 0 12-5.373 12-12zm0 160v-48c0-6.627-5.373-12-12-12H24c-6.627 0-12 5.373-12 12v48c0 6.627 5.373 12 12 12h48c6.627 0 12-5.373 12-12zm0 160v-48c0-6.627-5.373-12-12-12H24c-6.627 0-12 5.373-12 12v48c0 6.627 5.373 12 12 12h48c6.627 0 12-5.373 12-12z" />
    </symbol>
    <symbol viewBox="0 0 512 512" id="icon-list-alt">
        <path d="M464 64c8.823 0 16 7.178 16 16v352c0 8.822-7.177 16-16 16H48c-8.823 0-16-7.178-16-16V80c0-8.822 7.177-16 16-16h416m0-32H48C21.49 32 0 53.49 0 80v352c0 26.51 21.49 48 48 48h416c26.51 0 48-21.49 48-48V80c0-26.51-21.49-48-48-48zm-336 96c-17.673 0-32 14.327-32 32s14.327 32 32 32 32-14.327 32-32-14.327-32-32-32zm0 96c-17.673 0-32 14.327-32 32s14.327 32 32 32 32-14.327 32-32-14.327-32-32-32zm0 96c-17.673 0-32 14.327-32 32s14.327 32 32 32 32-14.327 32-32-14.327-32-32-32zm288-148v-24a6 6 0 0 0-6-6H198a6 6 0 0 0-6 6v24a6 6 0 0 0 6 6h212a6 6 0 0 0 6-6zm0 96v-24a6 6 0 0 0-6-6H198a6 6 0 0 0-6 6v24a6 6 0 0 0 6 6h212a6 6 0 0 0 6-6zm0 96v-24a6 6 0 0 0-6-6H198a6 6 0 0 0-6 6v24a6 6 0 0 0 6 6h212a6 6 0 0 0 6-6z" />
    </symbol>
    <symbol viewBox="0 0 448 512" id="icon-sort">
        <path d="M204.485 392l-84 84.485c-4.686 4.686-12.284 4.686-16.971 0l-84-84.485c-4.686-4.686-4.686-12.284 0-16.97l7.07-7.071c4.686-4.686 12.284-4.686 16.971 0L95 419.887V44c0-6.627 5.373-12 12-12h10c6.627 0 12 5.373 12 12v375.887l51.444-51.928c4.686-4.686 12.284-4.686 16.971 0l7.07 7.071c4.687 4.686 4.687 12.284 0 16.97zm100.492-220.355h61.547l15.5 44.317A12 12 0 0 0 393.351 224h11.552c8.31 0 14.105-8.243 11.291-16.062l-60.441-168A11.999 11.999 0 0 0 344.462 32h-16.924a11.999 11.999 0 0 0-11.291 7.938l-60.441 168c-2.813 7.82 2.981 16.062 11.291 16.062h11.271c5.12 0 9.676-3.248 11.344-8.088l15.265-44.267zm10.178-31.067l18.071-51.243c.853-2.56 1.776-5.626 2.668-8.743.871 3.134 1.781 6.219 2.644 8.806l17.821 51.18h-41.204zm-3.482 307.342c4.795-6.044-1.179 2.326 92.917-133.561a12.011 12.011 0 0 0 2.136-6.835V300c0-6.627-5.373-12-12-12h-113.84c-6.627 0-12 5.373-12 12v8.068c0 6.644 5.393 12.031 12.037 12.031 81.861.001 76.238.011 78.238-.026-2.973 3.818 4.564-7.109-92.776 133.303a12.022 12.022 0 0 0-2.142 6.847V468c0 6.627 5.373 12 12 12h119.514c6.627 0 12-5.373 12-12v-8.099c0-6.627-5.373-12-12-12-87.527-.001-81.97-.01-84.084.019z" />
    </symbol>
    <symbol viewBox="0 0 448 512" id="icon-podcast">
        <path d="M326.011 313.366a81.658 81.658 0 0 0-11.127-16.147c-1.855-2.1-1.913-5.215-.264-7.481C328.06 271.264 336 248.543 336 224c0-63.221-52.653-114.375-116.41-111.915-57.732 2.228-104.69 48.724-107.458 106.433-1.278 26.636 6.812 51.377 21.248 71.22 1.648 2.266 1.592 5.381-.263 7.481a81.609 81.609 0 0 0-11.126 16.145c-2.003 3.816-7.25 4.422-9.961 1.072C92.009 289.7 80 258.228 80 224c0-79.795 65.238-144.638 145.178-143.995 77.583.624 141.19 63.4 142.79 140.969.73 35.358-11.362 67.926-31.928 93.377-2.738 3.388-8.004 2.873-10.029-.985zM224 0C100.206 0 0 100.185 0 224c0 82.003 43.765 152.553 107.599 191.485 4.324 2.637 9.775-.93 9.078-5.945-1.244-8.944-2.312-17.741-3.111-26.038a6.025 6.025 0 0 0-2.461-4.291c-48.212-35.164-79.495-92.212-79.101-156.409.636-103.637 84.348-188.625 187.964-190.76C327.674 29.822 416 116.79 416 224c0 63.708-31.192 120.265-79.104 155.21a6.027 6.027 0 0 0-2.462 4.292c-.799 8.297-1.866 17.092-3.11 26.035-.698 5.015 4.753 8.584 9.075 5.947C403.607 376.922 448 306.75 448 224 448 100.204 347.814 0 224 0zm64 355.75c0 32.949-12.871 104.179-20.571 132.813C262.286 507.573 242.858 512 224 512c-18.857 0-38.286-4.427-43.428-23.438C172.927 460.134 160 388.898 160 355.75c0-35.156 31.142-43.75 64-43.75 32.858 0 64 8.594 64 43.75zm-32 0c0-16.317-64-16.3-64 0 0 27.677 11.48 93.805 19.01 122.747 6.038 2.017 19.948 2.016 25.981 0C244.513 449.601 256 383.437 256 355.75zM288 224c0 35.346-28.654 64-64 64s-64-28.654-64-64 28.654-64 64-64 64 28.654 64 64zm-32 0c0-17.645-14.355-32-32-32s-32 14.355-32 32 14.355 32 32 32 32-14.355 32-32z" />
    </symbol>
    <symbol viewBox="0 0 256 512" id="icon-angle-down">
        <path d="M119.5 326.9L3.5 209.1c-4.7-4.7-4.7-12.3 0-17l7.1-7.1c4.7-4.7 12.3-4.7 17 0L128 287.3l100.4-102.2c4.7-4.7 12.3-4.7 17 0l7.1 7.1c4.7 4.7 4.7 12.3 0 17L136.5 327c-4.7 4.6-12.3 4.6-17-.1z" />
    </symbol>
    <symbol viewBox="0 0 448 512" id="icon-play-solid">
        <path d="M424.4 214.7L72.4 6.6C43.8-10.3 0 6.1 0 47.9V464c0 37.5 40.7 60.1 72.4 41.3l352-208c31.4-18.5 31.5-64.1 0-82.6z" />
    </symbol>
    <symbol viewBox="0 0 448 512" id="icon-play">
        <path d="M424.4 214.7L72.4 6.6C43.8-10.3 0 6.1 0 47.9V464c0 37.5 40.7 60.1 72.4 41.3l352-208c31.4-18.5 31.5-64.1 0-82.6zm-16.2 55.1l-352 208C45.6 483.9 32 476.6 32 464V47.9c0-16.3 16.4-18.4 24.1-13.8l352 208.1c10.5 6.2 10.5 21.4.1 27.6z" />
    </symbol>
    <symbol viewBox="0 0 448 512" id="icon-pause">
        <path d="M48 479h96c26.5 0 48-21.5 48-48V79c0-26.5-21.5-48-48-48H48C21.5 31 0 52.5 0 79v352c0 26.5 21.5 48 48 48zM32 79c0-8.8 7.2-16 16-16h96c8.8 0 16 7.2 16 16v352c0 8.8-7.2 16-16 16H48c-8.8 0-16-7.2-16-16V79zm272 400h96c26.5 0 48-21.5 48-48V79c0-26.5-21.5-48-48-48h-96c-26.5 0-48 21.5-48 48v352c0 26.5 21.5 48 48 48zM288 79c0-8.8 7.2-16 16-16h96c8.8 0 16 7.2 16 16v352c0 8.8-7.2 16-16 16h-96c-8.8 0-16-7.2-16-16V79z" />
    </symbol>
    <symbol viewBox="0 0 640 512" id="icon-volume-mute">
        <path d="M615.554 509.393L4.534 27.657c-5.188-4.124-6.051-11.673-1.927-16.861l4.978-6.263c4.124-5.188 11.673-6.051 16.861-1.927l611.021 481.736c5.188 4.124 6.051 11.673 1.927 16.861l-4.978 6.263c-4.125 5.189-11.674 6.051-16.862 1.927zM407.172 126.221C450.902 152.963 480 201.134 480 256c0 19.945-3.861 38.996-10.856 56.463l26.002 20.5C505.972 309.488 512 283.404 512 256c0-66.099-34.976-124.573-88.133-157.079-7.538-4.611-17.388-2.235-21.997 5.302-4.61 7.539-2.236 17.387 5.302 21.998zm-171.913 1.844L256 107.328v37.089l32 25.229v-81.63c0-21.466-25.963-31.979-40.97-16.971l-37.075 37.068 25.304 19.952zm221.925-83.804C528.548 87.899 576 166.532 576 256c0 42.442-10.685 82.442-29.529 117.428l25.467 20.078C594.94 352.775 608 305.811 608 256c0-100.587-53.23-189.576-134.123-239.04-7.541-4.61-17.389-2.235-21.997 5.304-4.609 7.539-2.235 17.387 5.304 21.997zM357.159 208.178c13.422 8.213 22.517 21.271 25.639 36.209l32.141 25.341a89.491 89.491 0 0 0 1.06-13.728c0-30.891-15.753-58.972-42.14-75.117-7.538-4.615-17.388-2.239-21.998 5.297-4.611 7.537-2.24 17.386 5.298 21.998zm128.318 239.41a248.52 248.52 0 0 1-28.293 20.151c-7.539 4.609-9.913 14.458-5.304 21.997 4.612 7.544 14.465 9.91 21.997 5.304a280.708 280.708 0 0 0 37.246-27.233l-25.646-20.219zM256 266.666V404.67l-77.659-77.643a24 24 0 0 0-16.969-7.028H64V192h97.296l-40.588-32H56c-13.255 0-24 10.745-24 24v144c0 13.255 10.745 24 24 24h102.059l88.971 88.952c15.029 15.028 40.97 4.465 40.97-16.971V291.895l-32-25.229zm151.123 119.147c-7.498 4.624-9.853 14.443-5.253 21.965 4.611 7.541 14.462 9.911 21.997 5.302a184.087 184.087 0 0 0 9.738-6.387l-26.482-20.88z" />
    </symbol>
    <symbol viewBox="0 0 576 512" id="icon-volume">
        <path d="M576 256c0 100.586-53.229 189.576-134.123 239.04-7.532 4.606-17.385 2.241-21.997-5.304-4.609-7.539-2.235-17.388 5.304-21.997C496.549 424.101 544 345.467 544 256c0-89.468-47.452-168.101-118.816-211.739-7.539-4.609-9.913-14.458-5.304-21.997 4.608-7.539 14.456-9.914 21.997-5.304C522.77 66.424 576 155.413 576 256zm-96 0c0-66.099-34.976-124.572-88.133-157.079-7.538-4.611-17.388-2.235-21.997 5.302-4.61 7.539-2.236 17.388 5.302 21.998C418.902 152.963 448 201.134 448 256c0 54.872-29.103 103.04-72.828 129.779-7.538 4.61-9.912 14.459-5.302 21.998 4.611 7.541 14.462 9.911 21.997 5.302C445.024 380.572 480 322.099 480 256zm-138.14-75.117c-7.538-4.615-17.388-2.239-21.998 5.297-4.612 7.537-2.241 17.387 5.297 21.998C341.966 218.462 352 236.34 352 256s-10.034 37.538-26.841 47.822c-7.538 4.611-9.909 14.461-5.297 21.998 4.611 7.538 14.463 9.909 21.998 5.297C368.247 314.972 384 286.891 384 256s-15.753-58.972-42.14-75.117zM256 88.017v335.964c0 21.436-25.942 31.999-40.971 16.971L126.059 352H24c-13.255 0-24-10.745-24-24V184c0-13.255 10.745-24 24-24h102.059l88.971-88.954C230.037 56.038 256 66.551 256 88.017zm-32 19.311l-77.659 77.644A24.001 24.001 0 0 1 129.372 192H32v128h97.372a24.001 24.001 0 0 1 16.969 7.028L224 404.67V107.328z" />
    </symbol>
    <symbol viewBox="0 0 320 512" id="icon-sort">
        <path d="M288 288H32c-28.4 0-42.8 34.5-22.6 54.6l128 128c12.5 12.5 32.8 12.5 45.3 0l128-128c20-20.1 5.7-54.6-22.7-54.6zM160 448L32 320h256L160 448zM32 224h256c28.4 0 42.8-34.5 22.6-54.6l-128-128c-12.5-12.5-32.8-12.5-45.3 0l-128 128C-10.7 189.5 3.6 224 32 224zM160 64l128 128H32L160 64z" />
    </symbol>
    <symbol viewBox="0 0 512 512" id="icon-clock">
        <path d="M256 8C119 8 8 119 8 256s111 248 248 248 248-111 248-248S393 8 256 8zm216 248c0 118.7-96.1 216-216 216-118.7 0-216-96.1-216-216 0-118.7 96.1-216 216-216 118.7 0 216 96.1 216 216zm-148.9 88.3l-81.2-59c-3.1-2.3-4.9-5.9-4.9-9.7V116c0-6.6 5.4-12 12-12h14c6.6 0 12 5.4 12 12v146.3l70.5 51.3c5.4 3.9 6.5 11.4 2.6 16.8l-8.2 11.3c-3.9 5.3-11.4 6.5-16.8 2.6z" />
    </symbol>
    <symbol viewBox="0 0 512 512" id="icon-sort-amount-down">
        <path d="M204.485 392l-84 84.485c-4.686 4.686-12.284 4.686-16.971 0l-84-84.485c-4.686-4.686-4.686-12.284 0-16.97l7.07-7.071c4.686-4.686 12.284-4.686 16.971 0L95 419.887V44c0-6.627 5.373-12 12-12h10c6.627 0 12 5.373 12 12v375.887l51.444-51.928c4.686-4.686 12.284-4.686 16.971 0l7.07 7.071c4.687 4.686 4.687 12.284 0 16.97zM384 308v-8c0-6.627-5.373-12-12-12H268c-6.627 0-12 5.373-12 12v8c0 6.627 5.373 12 12 12h104c6.627 0 12-5.373 12-12zm64-96v-8c0-6.627-5.373-12-12-12H268c-6.627 0-12 5.373-12 12v8c0 6.627 5.373 12 12 12h168c6.627 0 12-5.373 12-12zm64-96v-8c0-6.627-5.373-12-12-12H268c-6.627 0-12 5.373-12 12v8c0 6.627 5.373 12 12 12h232c6.627 0 12-5.373 12-12zM320 404v-8c0-6.627-5.373-12-12-12h-40c-6.627 0-12 5.373-12 12v8c0 6.627 5.373 12 12 12h40c6.627 0 12-5.373 12-12z" />
    </symbol>
    <symbol viewBox="0 0 576 512" id="icon-edit-rounded">
        <path d="M417.8 315.5l20-20c3.8-3.8 10.2-1.1 10.2 4.2V464c0 26.5-21.5 48-48 48H48c-26.5 0-48-21.5-48-48V112c0-26.5 21.5-48 48-48h292.3c5.3 0 8 6.5 4.2 10.2l-20 20c-1.1 1.1-2.7 1.8-4.2 1.8H48c-8.8 0-16 7.2-16 16v352c0 8.8 7.2 16 16 16h352c8.8 0 16-7.2 16-16V319.7c0-1.6.6-3.1 1.8-4.2zm145.9-191.2L251.2 436.8l-99.9 11.1c-13.4 1.5-24.7-9.8-23.2-23.2l11.1-99.9L451.7 12.3c16.4-16.4 43-16.4 59.4 0l52.6 52.6c16.4 16.4 16.4 43 0 59.4zm-93.6 48.4L403.4 106 169.8 339.5l-8.3 75.1 75.1-8.3 233.5-233.6zm71-85.2l-52.6-52.6c-3.8-3.8-10.2-4-14.1 0L426 83.3l66.7 66.7 48.4-48.4c3.9-3.8 3.9-10.2 0-14.1z" />
    </symbol>
    <symbol id="icon-reply" viewBox="0 0 576 512">
        <path d="M11.093 251.65l175.998 184C211.81 461.494 256 444.239 256 408v-87.84c154.425 1.812 219.063 16.728 181.19 151.091-8.341 29.518 25.447 52.232 49.68 34.51C520.16 481.421 576 426.17 576 331.19c0-171.087-154.548-201.035-320-203.02V40.016c0-36.27-44.216-53.466-68.91-27.65L11.093 196.35c-14.791 15.47-14.791 39.83 0 55.3zm23.127-33.18l176-184C215.149 29.31 224 32.738 224 40v120c157.114 0 320 11.18 320 171.19 0 74.4-40 122.17-76.02 148.51C519.313 297.707 395.396 288 224 288v120c0 7.26-8.847 10.69-13.78 5.53l-176-184a7.978 7.978 0 0 1 0-11.06z" />
    </symbol>
    <symbol id="icon-clipboard" viewBox="0 0 384 512">
        <path d="M336 64h-88.581c.375-2.614.581-5.283.581-8 0-30.879-25.122-56-56-56s-56 25.121-56 56c0 2.717.205 5.386.581 8H48C21.49 64 0 85.49 0 112v352c0 26.51 21.49 48 48 48h288c26.51 0 48-21.49 48-48V112c0-26.51-21.49-48-48-48zm16 400c0 8.822-7.178 16-16 16H48c-8.822 0-16-7.178-16-16V112c0-8.822 7.178-16 16-16h48v20c0 6.627 5.373 12 12 12h168c6.627 0 12-5.373 12-12V96h48c8.822 0 16 7.178 16 16v352zM192 32c13.255 0 24 10.745 24 24s-10.745 24-24 24-24-10.745-24-24 10.745-24 24-24" />
    </symbol>
    <symbol id="icon-cube" viewBox="0 0 512 512">
        <path d="M239.1 6.3l-208 78c-18.7 7-31.1 25-31.1 45v225.1c0 18.2 10.3 34.8 26.5 42.9l208 104c13.5 6.8 29.4 6.8 42.9 0l208-104c16.3-8.1 26.5-24.8 26.5-42.9V129.3c0-20-12.4-37.9-31.1-44.9l-208-78C262 2.2 250 2.2 239.1 6.3zM256 34.2l224 84v.3l-224 97.1-224-97.1v-.3l224-84zM32 153.4l208 90.1v224.7l-208-104V153.4zm240 314.8V243.5l208-90.1v210.9L272 468.2z" />
    </symbol>
    <symbol id="icon-circle-cross" viewBox="0 0 256 256">
        <path d="M183.191,174.141c2.5,2.498,2.5,6.552,0,9.05c-1.249,1.25-2.889,1.875-4.525,1.875c-1.638,0-3.277-0.625-4.525-1.875  l-46.142-46.142L81.856,183.19c-1.249,1.25-2.888,1.875-4.525,1.875c-1.638,0-3.277-0.625-4.525-1.875c-2.5-2.498-2.5-6.552,0-9.05  l46.143-46.143L72.806,81.856c-2.5-2.499-2.5-6.552,0-9.05c2.497-2.5,6.553-2.5,9.05,0l46.142,46.142l46.142-46.142  c2.497-2.5,6.553-2.5,9.051,0c2.5,2.499,2.5,6.552,0,9.05l-46.143,46.142L183.191,174.141z M256,128C256,57.42,198.58,0,128,0  C57.42,0,0,57.42,0,128c0,70.58,57.42,128,128,128C198.58,256,256,198.58,256,128z M243.2,128c0,63.521-51.679,115.2-115.2,115.2  c-63.522,0-115.2-51.679-115.2-115.2C12.8,64.478,64.478,12.8,128,12.8C191.521,12.8,243.2,64.478,243.2,128z" fill="#ef0e0e" />
    </symbol>
    <symbol id="icon-circle-check" viewBox="0 0 32 32">
        <g>
            <path d="M16,0C7.163,0,0,7.163,0,16c0,8.837,7.163,16,16,16c8.836,0,16-7.164,16-16C32,7.163,24.836,0,16,0z M16,30   C8.268,30,2,23.732,2,16C2,8.268,8.268,2,16,2s14,6.268,14,14C30,23.732,23.732,30,16,30z" fill="#2db730" />
            <path d="M23.3,10.393L13.012,20.589l-4.281-4.196c-0.394-0.391-1.034-0.391-1.428,0   c-0.395,0.391-0.395,1.024,0,1.414l4.999,4.899c0.41,0.361,1.023,0.401,1.428,0l10.999-10.899c0.394-0.39,0.394-1.024,0-1.414   C24.334,10.003,23.695,10.003,23.3,10.393z" fill="#2db730" />
        </g>
    </symbol>
    <symbol id="icon-loading" viewBox="0 0 100 100" preserveAspectRatio="xMidYMid" class="lds-rolling">
        <circle cx="50" cy="50" fill="none" stroke="currentColor" stroke-width="5" r="26" stroke-dasharray="122.52211349000194 42.840704496667314" transform="rotate(150 50 50)"><animateTransform attributeName="transform" type="rotate" calcMode="linear" values="0 50 50;360 50 50" keyTimes="0;1" dur="1s" begin="0s" repeatCount="indefinite"></animateTransform></circle>
    </symbol>
    <symbol id="icon-sort-down" viewBox="0 0 16 16"><g stroke-width="1.5" fill="none" fill-rule="evenodd"><path stroke="#CBCED1" d="M10.657 6L8 3.343 5.343 6"/><path stroke="#9EA2A8" d="M10.657 10L8 12.657 5.343 10"/></g></symbol>
    <symbol id="icon-sort-up" viewBox="0 0 16 16"><g stroke-width="1.5" fill="none" fill-rule="evenodd"><path stroke="#CBCED1" d="M10.657 10L8 12.657 5.343 10"/><path stroke="#9EA2A8" d="M10.657 6L8 3.343 5.343 6"/></g></symbol>
    <symbol id="icon-ban" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
        <path d="M256 8C119.033 8 8 119.033 8 256s111.033 248 248 248 248-111.033 248-248S392.967 8 256 8zM103.265 408.735c-80.622-80.622-84.149-208.957-10.9-293.743l304.644 304.643c-84.804 73.264-213.138 69.706-293.744-10.9zm316.37-11.727L114.992 92.365c84.804-73.263 213.137-69.705 293.743 10.9 80.622 80.621 84.149 208.957 10.9 293.743z" />
    </symbol>
    <symbol id="icon-circled-arrow-down" viewBox="0 0 512 512">
      <path d="M256 8C119 8 8 119 8 256s111 248 248 248 248-111 248-248S393 8 256 8zm216 248c0 118.7-96.1 216-216 216-118.7 0-216-96.1-216-216 0-118.7 96.1-216 216-216 118.7 0 216 96.1 216 216zm-92.5-4.5l-6.9-6.9c-4.7-4.7-12.5-4.7-17.1.2L273 330.3V140c0-6.6-5.4-12-12-12h-10c-6.6 0-12 5.4-12 12v190.3l-82.5-85.6c-4.7-4.8-12.4-4.9-17.1-.2l-6.9 6.9c-4.7 4.7-4.7 12.3 0 17l115 115.1c4.7 4.7 12.3 4.7 17 0l115-115.1c4.7-4.6 4.7-12.2 0-16.9z"/>
    </symbol>
    <symbol id="icon-marketplace-installer" width="818px" height="18px" viewBox="0 0 818 18">
      <defs>
          <path d="M4.23904354,6.69174481 L4,6.46190251" id="path-1"></path>
          <path d="M5.02490772,7.44735961 L4,6.46190251" id="path-2"></path>
          <path d="M6.27864386,8.65283709 L4,6.46190251" id="path-3"></path>
          <path d="M7.06030829,9.40441379 L4,6.46190251" id="path-4"></path>
          <path d="M7.67973749,10 L4,6.46190251" id="path-5"></path>
          <polyline id="path-6" points="8.22245052 9.47817702 7.67973749 10 4 6.46190251"></polyline>
          <polyline id="path-7" points="8.91155959 8.81559304 7.67973749 10 4 6.46190251"></polyline>
          <polyline id="path-8" points="9.5143542 8.23600113 7.67973749 10 4 6.46190251"></polyline>
          <polyline id="path-9" points="10.7210096 7.07579219 7.67973749 10 4 6.46190251"></polyline>
          <polyline id="path-10" points="11.5636902 6.26554796 7.67973749 10 4 6.46190251"></polyline>
          <polyline id="path-11" points="12.0786348 5.77042449 7.67973749 10 4 6.46190251"></polyline>
          <polyline id="path-12" points="12.76451 5.11094988 7.67973749 10 4 6.46190251"></polyline>
          <polyline id="path-13" points="13.4378238 4.46355327 7.67973749 10 4 6.46190251"></polyline>
          <polyline id="path-14" points="13.7997577 4.11555082 7.67973749 10 4 6.46190251"></polyline>
          <polyline id="path-15" points="14.3803465 3.55731005 7.67973749 10 4 6.46190251"></polyline>
          <polyline id="path-16" points="14.6691383 3.27963438 7.67973749 10 4 6.46190251"></polyline>
          <polyline id="path-17" points="14.9249351 3.0336836 7.67973749 10 4 6.46190251"></polyline>
          <polyline id="path-18" points="16 2 7.67973749 10 4 6.46190251"></polyline>
      </defs>
      <g id="Page-1" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
          <g id="sprite_30fps" transform="translate(1.000000, 1.000000)">
              <g id="Group">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="0,50.26566726535555"></path>
                  <g transform="translate(4.000000, 3.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,7.831 L3.9,0 M7.694,4.238 L3.738,8.194 L0,4.456"></path>
                  </g>
              </g>
              <g id="Group" transform="translate(20.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="6.309518669750073,43.95614859560548"></path>
                  <g transform="translate(4.000000, 3.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,7.891023 L3.9,0.060023"></path>
                      <polyline points="7.694 4.298023 3.738 8.254023 3.55271368e-15 4.516023"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(40.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="11.23561634937571,39.03005091597984"></path>
                  <g transform="translate(4.000000, 3.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,8.147927 L3.9,0.316927"></path>
                      <polyline points="7.694 4.554927 3.738 8.510927 0 4.772927"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(60.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="15.43826769318981,34.82739957216574"></path>
                  <g transform="translate(4.000000, 3.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,8.677262 L3.9,0.846262"></path>
                      <polyline points="7.694 5.084262 3.738 9.040262 0 5.302262"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(80.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="19.12688492082794,31.13878234452761"></path>
                  <g transform="translate(4.000000, 4.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,8.162728 L3.9,0.331728"></path>
                      <polyline points="7.694 4.569728 3.738 8.525728 0 4.787728"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(100.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="22.41366130363328,27.85200596172227"></path>
                  <g transform="translate(4.000000, 4.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,8.4617 L3.9,0.6307"></path>
                      <polyline points="7.694 4.8687 3.738 8.8247 0 5.0867"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(120.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="25.36974071138243,24.89592655397311"></path>
                  <g transform="translate(4.000000, 4.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,8.64145 L3.9,0.81045"></path>
                      <polyline points="7.694 5.04845 3.738 9.00445 0 5.26645"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(140.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="28.04462514092069,22.22104212443485"></path>
                  <g transform="translate(4.000000, 4.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,8.748156 L3.9,0.917156"></path>
                      <polyline points="7.694 5.155156 3.738 9.111156 0 5.373156"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(160.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="30.47488513936153,19.79078212599402"></path>
                  <g transform="translate(4.000000, 4.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,8.806194 L3.9,0.975194"></path>
                      <polyline points="7.694 5.213194 3.738 9.169194 0 5.431194"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(180.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="32.68870296724897,17.57696429810658"></path>
                  <g transform="translate(4.000000, 4.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,8.829412 L3.9,0.998412"></path>
                      <polyline points="7.694 5.236412 3.738 9.192412 0 5.454412"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(200.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="34.70849140023716,15.55717586511838"></path>
                  <g transform="translate(4.000000, 5.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,7.831 L3.9,0"></path>
                      <polyline points="7.694 4.238 3.738 8.194 0 4.456"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(220.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="36.55251610281903,13.71315116253652"></path>
                  <g transform="translate(4.000000, 5.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,7.831 L3.9,0"></path>
                      <polyline points="7.694 4.238 3.738 8.194 0 4.456"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(240.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="38.23595723280788,12.02971003254766"></path>
                  <g transform="translate(4.000000, 5.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,7.831 L3.9,0"></path>
                      <polyline points="7.694 4.238 3.738 8.194 0 4.456"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(260.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="39.77163469241522,10.49403257294033"></path>
                  <g transform="translate(4.000000, 5.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,7.831 L3.9,0"></path>
                      <polyline points="7.694 4.238 3.738 8.194 0 4.456"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(280.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="41.17052118313375,9.095146082221799"></path>
                  <g transform="translate(4.000000, 5.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,7.831 L3.9,0"></path>
                      <polyline points="7.694 4.238 3.738 8.194 0 4.456"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(300.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="42.44211577580978,7.823551489545761"></path>
                  <g transform="translate(4.000000, 5.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,7.831 L3.9,0"></path>
                      <polyline points="7.694 4.238 3.738 8.194 0 4.456"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(320.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="43.59472260670677,6.670944658648773"></path>
                  <g transform="translate(4.000000, 5.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,7.831 L3.9,0"></path>
                      <polyline points="7.694 4.238 3.738 8.194 0 4.456"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(340.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="44.63566315322812,5.630004112127423"></path>
                  <g transform="translate(4.000000, 5.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,7.831 L3.9,0"></path>
                      <polyline points="7.694 4.238 3.738 8.194 0 4.456"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(360.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="45.57144084512059,4.694226420234955"></path>
                  <g transform="translate(4.000000, 5.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,7.831 L3.9,0"></path>
                      <polyline points="7.694 4.238 3.738 8.194 0 4.456"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(380.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="46.40787072936746,3.857796535988089"></path>
                  <g transform="translate(4.000000, 5.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,7.831 L3.9,0"></path>
                      <polyline points="7.694 4.238 3.738 8.194 0 4.456"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(400.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="47.15018302776506,3.115484237590489"></path>
                  <g transform="translate(4.000000, 5.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,7.831 L3.9,0"></path>
                      <polyline points="7.694 4.238 3.738 8.194 0 4.456"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(420.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="47.80310686431982,2.462560401035723"></path>
                  <g transform="translate(4.000000, 5.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,7.831 L3.9,0"></path>
                      <polyline points="7.694 4.238 3.738 8.194 0 4.456"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(440.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5" stroke-dasharray="48.37093870634003,1.89472855901552"></path>
                  <g transform="translate(4.000000, 5.000000)" id="Shape" stroke="#1D74F5">
                      <path d="M3.9,7.831 L3.9,0"></path>
                      <polyline points="7.694 4.238 3.738 8.194 0 4.456"></polyline>
                  </g>
              </g>
              <g id="Group" transform="translate(800.000000, 0.000000)"></g>
              <g id="Group" transform="translate(780.000000, 0.000000)"></g>
              <g id="Group" transform="translate(760.000000, 0.000000)"></g>
              <g id="Group" transform="translate(740.000000, 0.000000)"></g>
              <g id="Group" transform="translate(720.000000, 0.000000)"></g>
              <g id="Group" transform="translate(700.000000, 0.000000)"></g>
              <g id="Group" transform="translate(680.000000, 0.000000)"></g>
              <g id="Group" transform="translate(660.000000, 0.000000)"></g>
              <g id="Group" transform="translate(640.000000, 0.000000)"></g>
              <g id="Group" transform="translate(620.000000, 0.000000)"></g>
              <g id="Group" transform="translate(600.000000, 0.000000)"></g>
              <g id="Group" transform="translate(580.000000, 0.000000)"></g>
              <g id="Group" transform="translate(560.000000, 0.000000)"></g>
              <g id="Group" transform="translate(540.000000, 0.000000)"></g>
              <g id="Group" transform="translate(520.000000, 0.000000)"></g>
              <g id="Group" transform="translate(500.000000, 0.000000)"></g>
              <g id="Group" transform="translate(480.000000, 0.000000)"></g>
              <g id="Group" transform="translate(460.000000, 0.000000)"></g>
              <g id="Group" transform="translate(460.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5"></path>
                  <g id="Shape">
                      <use stroke="#FFFFFF" stroke-width="3" xlink:href="#path-1"></use>
                      <use stroke="#1D74F5" stroke-width="1" xlink:href="#path-1"></use>
                  </g>
              </g>
              <g id="Group" transform="translate(480.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5"></path>
                  <g id="Shape">
                      <use stroke="#FFFFFF" stroke-width="3" xlink:href="#path-2"></use>
                      <use stroke="#1D74F5" stroke-width="1" xlink:href="#path-2"></use>
                  </g>
              </g>
              <g id="Group" transform="translate(500.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5"></path>
                  <g id="Shape">
                      <use stroke="#FFFFFF" stroke-width="3" xlink:href="#path-3"></use>
                      <use stroke="#1D74F5" stroke-width="1" xlink:href="#path-3"></use>
                  </g>
              </g>
              <g id="Group" transform="translate(520.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5"></path>
                  <g id="Shape">
                      <use stroke="#FFFFFF" stroke-width="3" xlink:href="#path-4"></use>
                      <use stroke="#1D74F5" stroke-width="1" xlink:href="#path-4"></use>
                  </g>
              </g>
              <g id="Group" transform="translate(540.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5"></path>
                  <g id="Shape">
                      <use stroke="#FFFFFF" stroke-width="3" xlink:href="#path-5"></use>
                      <use stroke="#1D74F5" stroke-width="1" xlink:href="#path-5"></use>
                  </g>
              </g>
              <g id="Group" transform="translate(560.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5"></path>
                  <g id="Shape">
                      <use stroke="#FFFFFF" stroke-width="3" xlink:href="#path-6"></use>
                      <use stroke="#1D74F5" stroke-width="1" xlink:href="#path-6"></use>
                  </g>
              </g>
              <g id="Group" transform="translate(580.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5"></path>
                  <g id="Shape">
                      <use stroke="#FFFFFF" stroke-width="3" xlink:href="#path-7"></use>
                      <use stroke="#1D74F5" stroke-width="1" xlink:href="#path-7"></use>
                  </g>
              </g>
              <g id="Group" transform="translate(600.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5"></path>
                  <g id="Shape">
                      <use stroke="#FFFFFF" stroke-width="3" xlink:href="#path-8"></use>
                      <use stroke="#1D74F5" stroke-width="1" xlink:href="#path-8"></use>
                  </g>
              </g>
              <g id="Group" transform="translate(620.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5"></path>
                  <g id="Shape">
                      <use stroke="#FFFFFF" stroke-width="3" xlink:href="#path-9"></use>
                      <use stroke="#1D74F5" stroke-width="1" xlink:href="#path-9"></use>
                  </g>
              </g>
              <g id="Group" transform="translate(640.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5"></path>
                  <g id="Shape">
                      <use stroke="#FFFFFF" stroke-width="3" xlink:href="#path-10"></use>
                      <use stroke="#1D74F5" stroke-width="1" xlink:href="#path-10"></use>
                  </g>
              </g>
              <g id="Group" transform="translate(660.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5"></path>
                  <g id="Shape">
                      <use stroke="#FFFFFF" stroke-width="3" xlink:href="#path-11"></use>
                      <use stroke="#1D74F5" stroke-width="1" xlink:href="#path-11"></use>
                  </g>
              </g>
              <g id="Group" transform="translate(680.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5"></path>
                  <g id="Shape">
                      <use stroke="#FFFFFF" stroke-width="3" xlink:href="#path-12"></use>
                      <use stroke="#1D74F5" stroke-width="1" xlink:href="#path-12"></use>
                  </g>
              </g>
              <g id="Group" transform="translate(700.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5"></path>
                  <g id="Shape">
                      <use stroke="#FFFFFF" stroke-width="3" xlink:href="#path-13"></use>
                      <use stroke="#1D74F5" stroke-width="1" xlink:href="#path-13"></use>
                  </g>
              </g>
              <g id="Group" transform="translate(720.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5"></path>
                  <g id="Shape">
                      <use stroke="#FFFFFF" stroke-width="3" xlink:href="#path-14"></use>
                      <use stroke="#1D74F5" stroke-width="1" xlink:href="#path-14"></use>
                  </g>
              </g>
              <g id="Group" transform="translate(740.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5"></path>
                  <g id="Shape">
                      <use stroke="#FFFFFF" stroke-width="3" xlink:href="#path-15"></use>
                      <use stroke="#1D74F5" stroke-width="1" xlink:href="#path-15"></use>
                  </g>
              </g>
              <g id="Group" transform="translate(760.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5"></path>
                  <g id="Shape">
                      <use stroke="#FFFFFF" stroke-width="3" xlink:href="#path-16"></use>
                      <use stroke="#1D74F5" stroke-width="1" xlink:href="#path-16"></use>
                  </g>
              </g>
              <g id="Group" transform="translate(780.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5"></path>
                  <g id="Shape">
                      <use stroke="#FFFFFF" stroke-width="3" xlink:href="#path-17"></use>
                      <use stroke="#1D74F5" stroke-width="1" xlink:href="#path-17"></use>
                  </g>
              </g>
              <g id="Group" transform="translate(800.000000, 0.000000)">
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
                  <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5"></path>
                  <g id="Shape">
                      <use stroke="#FFFFFF" stroke-width="3" xlink:href="#path-18"></use>
                      <use stroke="#1D74F5" stroke-width="1" xlink:href="#path-18"></use>
                  </g>
              </g>
          </g>
      </g>
    </symbol>
    <symbol id="icon-app-installed" viewBox="0 0 16 16" fill="none" fill-rule="evenodd">
      <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#E1E5E8"></path>
      <path d="M8,0 C5.879,0 3.843,0.843 2.343,2.343 C0.843,3.843 0,5.879 0,8 C0,10.121 0.843,12.157 2.343,13.657 C3.843,15.157 5.879,16 8,16 C10.121,16 12.157,15.157 13.657,13.657 C15.157,12.157 16,10.121 16,8 C16,5.879 15.157,3.843 13.657,2.343 C12.157,0.843 10.121,0 8,0 Z" id="Shape" stroke="#1D74F5"></path>
      <g id="Shape">
          <use stroke="#FFFFFF" stroke-width="3" xlink:href="#path-18"></use>
          <use stroke="#1D74F5" stroke-width="1" xlink:href="#path-18"></use>
      </g>
    </symbol>
</svg>


<div id="initial-page-loading" class="page-loading">
	<div class="loading-animation">
		<div class="bounce bounce1"></div>
		<div class="bounce bounce2"></div>
		<div class="bounce bounce3"></div>
	</div>
</div>
<style id='css-variables'> :root {--rc-color-alert: #ffd21f;
--rc-color-alert-light: #f6c502;
--rc-color-alert-message-primary: var(--rc-color-button-primary);
--rc-color-alert-message-primary-background: #f1f6ff;
--rc-color-alert-message-secondary: #7ca52b;
--rc-color-alert-message-secondary-background: #fafff1;
--rc-color-alert-message-warning: #d52d24;
--rc-color-alert-message-warning-background: #fff3f3;
--rc-color-button-primary: #1d74f5;
--rc-color-button-primary-light: #175cc4;
--rc-color-content: var(--color-white);
--rc-color-error: #f5455c;
--rc-color-error-light: #e1364c;
--rc-color-link-active: var(--rc-color-button-primary);
--rc-color-primary: var(--color-dark);
--rc-color-primary-dark: var(--color-dark-medium);
--rc-color-primary-darkest: var(--color-darkest);
--rc-color-primary-light: var(--color-gray);
--rc-color-primary-light-medium: var(--color-gray-medium);
--rc-color-primary-lightest: var(--color-gray-lightest);
--rc-color-success: #2de0a5;
--rc-color-success-light: #25d198;}</style>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" style="display:none">
    <symbol id="icon-chatpal-enter" fill="#FFFFFF" x="0px" y="0px" viewBox="0 0 100 100" enable-background="new 0 0 100 100" xml:space="preserve"><path d="M36.977,80.296c-0.401,0-0.807-0.121-1.158-0.371L6.906,59.326c-0.527-0.375-0.84-0.982-0.84-1.629  c0-0.646,0.313-1.253,0.839-1.629l28.912-20.606c0.901-0.641,2.148-0.432,2.79,0.468c0.641,0.899,0.432,2.148-0.468,2.79  L13.98,55.938h75.953V21.704c0-1.104,0.896-2,2-2s2,0.896,2,2v35.949c0,1.431-0.85,2.285-2.272,2.285H14.658l23.48,16.729  c0.9,0.641,1.109,1.89,0.469,2.79C38.217,80.004,37.602,80.296,36.977,80.296z"></path></symbol>
</svg>

<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" style="display:none">
    <symbol id="icon-chatpal-logo-icon-darkblue" viewBox="0 0 48 57" width="27px" height="24px">
        <g id="Page-1" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
            <g id="Outline-black-Copy-7" transform="translate(0.000000, -28.000000)">
                <g id="Group-8">
                    <path d="M17.0782237,77.3942887 L3.08428051,84.8880697 L6.68509058,73.5334833 L0.0980054069,71.0865356 C2.25127483,42.8616902 3.32790954,28.7492676 3.32790954,28.7492676 C3.32790954,28.7492676 10.1654988,28.7492676 23.8406774,28.7492676 L44.7147288,28.7492676 L47.5833494,71.0865356 L23.4177323,79.7492676 L17.0782237,77.3942887 Z" id="Combined-Shape" fill="#125074"></path>
                    <g id="Group-10" transform="translate(10.000000, 0.000000)" fill="#FFFFFF">
                        <path d="M17.368,42.128 C17.812,42.128 17.997,42.461 17.997,42.72 C17.997,43.09 17.146,44.126 17.146,49.935 C17.146,50.379 17.146,50.823 17.183,51.23 C17.849,49.343 18.589,47.641 19.403,46.346 C20.439,44.681 21.364,44.089 22.511,44.089 C25.323,44.089 27.432,47.234 27.432,53.117 C27.432,58.075 24.694,60.258 22.215,60.258 C20.365,60.258 19.292,59.148 18.848,58.63 C18.7,58.445 18.626,58.297 18.626,58.149 C18.626,57.927 18.848,57.594 19.144,57.594 C19.292,57.594 19.44,57.631 19.662,57.853 C20.143,58.334 20.883,58.741 21.697,58.741 C23.029,58.741 23.769,57.15 23.769,53.043 C23.769,48.714 23.214,46.494 22.03,46.494 C20.624,46.494 18.922,50.601 17.59,55.189 C18.145,58.741 18.996,61.997 18.996,65.327 C18.996,68.546 17.22,70.248 15.703,70.248 C14.26,70.248 13.557,68.842 13.557,67.362 C13.557,65.993 14.149,62.219 15.148,58.112 C14.889,55.707 14.63,53.228 14.63,50.268 C14.63,44.348 16.554,42.128 17.368,42.128 Z M15.962,67.621 C15.962,65.882 15.851,64.254 15.703,62.7 C15.259,64.846 15,66.548 15,67.288 C15,68.546 15.259,68.805 15.555,68.805 C15.851,68.805 15.962,68.509 15.962,67.621 Z" id="p"></path>
                        <path d="M7.748,61.196 C3.224,61.196 -0.78,57.868 -0.78,51.68 C-0.78,43.1 4.68,38.212 8.32,38.212 C10.764,38.212 12.636,40.188 12.636,42.84 C12.636,45.648 11.752,47.26 10.868,47.26 C9.88,47.26 8.476,46.272 8.476,45.596 C8.476,44.4 9.88,43.88 9.88,41.436 C9.88,41.176 9.568,40.344 8.684,40.344 C6.448,40.344 4.368,44.66 4.368,50.848 C4.368,56.1 6.396,58.388 8.996,58.388 C13.676,58.388 15.86,51.68 15.86,51.68 C15.86,51.68 16.068,51.108 16.536,51.108 C16.9,51.108 17.16,51.316 17.16,51.68 C17.16,51.94 17.004,52.408 17.004,52.408 C17.004,52.408 14.248,61.196 7.748,61.196 Z" id="c"></path>
                    </g>
                </g>
            </g>
        </g>
    </symbol>
</svg>


  <script type="text/javascript">__meteor_runtime_config__ = JSON.parse(decodeURIComponent("%7B%22meteorRelease%22%3A%22METEOR%401.6.1.3%22%2C%22meteorEnv%22%3A%7B%22NODE_ENV%22%3A%22production%22%2C%22TEST_METADATA%22%3A%22%7B%7D%22%7D%2C%22PUBLIC_SETTINGS%22%3A%7B%7D%2C%22ROOT_URL%22%3A%22http%3A%2F%2Frocketchat.marguerite.io%3A3000%22%2C%22ROOT_URL_PATH_PREFIX%22%3A%22%22%2C%22appId%22%3A%22zb2yb503dv5o.s8lnryhs4s3o%22%2C%22accountsConfigCalled%22%3Atrue%2C%22autoupdateVersion%22%3A%2284be318aefdd9d59cd5e8f3d13fa7839fa997335%22%2C%22autoupdateVersionRefreshable%22%3A%227fe34aa5a4618c75369721ea53a34d157b27c438%22%2C%22autoupdateVersionCordova%22%3A%223793711725af1eda1c151a0a0e2ac04a545ea1e9%22%7D"))</script>

  <script type="text/javascript" src="/c029a6b2088014967102f8efaaf260dc7e0d3df5.js?meteor_js_resource=true"></script>


</body>
</html>
```




Finalement, Les Jenkins pipelines utiliseront aussi leur propre HUBOT pour poster des messages aux dévelopepurs par exemple.


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
