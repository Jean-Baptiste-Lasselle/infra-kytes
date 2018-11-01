La pomme, de l'histoire du paysan qui PXE-boote ses applications Meteor

Les fruits, les potes des fleurs romatiques comme marguerite

https://www.technologies-ebusiness.com/enjeux-et-tendances/realiser-api-management-tyk-docker
ouais non c clair ça a les chiffres d'une solution qui vaut le coup de l'essai.
Le mieux c'est que je fasse un comparatif avec GRavitee.io

Donc le but de ce concept de API Gateway, c'est donc de déolacer la couche logicielle qui implémente les fonctions de gestion des autorisations / ppermissions, pour laconsommations des API REST micro services, typpiquement;

C'est vraiment intéresant e conept qui EST BIEN SPECIFIQUE A L'ARCHITECTURE MICROSERVIE
pourqoii? parce que l'idée est de dire, mais voilà, en fait l'architecture micro-services, c'est tuprends ton appli codée à l'ancienne, un bon gros paquebot bien monolithique, ou au mieux une architecture genre SOA ou OSGI comme eclipse, bref, soit un bon gros monolythe , ou une appli avec bonne architecture bien modulaire, , et tu fais ça :
- tu éclate ton appli en petits blocs. comment tu fais le découpage? ben en fait, le principe, c'est qu'un micro-service, ça doit faire un truc simple, un seul, mais ça doit super bien le faire, et de manière immutable avec promises.
exemple : si dans ton appli, il y a des workflows, et qu dans différents workflow, des emails sont envoyés, (par exemple ton code source utilise `javax.mail`) , alors tu vas écrire un microsservice `CAMPAGNE E-MAILER``, qui fonctionne comme suit:
-. Tu lui donne l'ID_µCAMPAGNE, la clé primaire de la table 'campaganes' de ta base de données,l'adresse email, le prénom le nom et la civilité du destinataire, l'objet du mail (subject), et lexte du message, 
- il appelle  un autre mmicroservice, `autre-microservice.mon-entreprise.io`, pour lui demander quel est l'adresse e-mail du manager responsable de la campagne .ID_µCAMPAGNE
- l'autre microserice lui renvoie l'adresse email,
- et il envoie enfin l'email avec comme expéditeur l'adresse e-mail du responsalble de la campagne



Donc l'idée des API gateway est :
mais purée, tu fais une solution que tu as éclatée en micro-services, alors nom de dieu, tu vas pas faire écrire du code qui implémente authorization / permissions, dans chaque micro-service, oui oui, imagines:
- tu es responable d'un servce avec 150 dévelopepurs
- tu as un rpojet ou il faut développer envrion 140 microservices, d'après tes calculs avec l'architecture que tu as rapidemetn prototypée
- tu vas te staffer 5/6 éupes de 5 développeurs
- ehmais purée, si tu leur fait à chacun écrire du code qui implémente des fonctionnalités de gfestion d'autorisation permissions
- mais utu peux être certains qu'ils vont faire des choses très différentes, sc'est sûr!
- alors pourqupoi ne pas lerur retirer cette couche à toutes ces équipes, et tu écris toi même le code une fois, que tu colles dans uen appli que tu packeage etc Ce code quee tu as écris, tu vas appeler ça hum.... le portail des paysans.
- et en fait , les micro-services, pour s'appeler entre entre eux, .. eh ben ils ne vont pas sappeler entre entre. Eh oui. désormais, ton microservice de campagne email là,, eh bien tu n'aura plus besoin de lui indiquer , par configuration, le nom de domaine de l'autre micro-serivies, souviens-toi, "autre-microservice.mon-entreprise.io". au lieu de cela, tu vas configurer le portail des paysans, et lui dire :
ok portail des paysans, il y a une nouvelle API, elle a pour nom de domaine "autre-microservice.mon-entreprise.io", et tu rendras disponible cette api sous le petit npm "bernard".
- Une fois ça fait, tuconfigures maintenant ton microservice qui envoie les email, tu vas me modifier son code source, pour qu'il fonctionne de la mainère suivante :
- le parmaètre de configuration nom de domaine de l'autre microservice, je veux plus en entedre parler das ton code source
- ton microservice devra avoir deux nouveaux paramètres de configurations,  le nom de domaine du portail des paysans, et l'alias de l'autre service. Je t'ai déployé une instance du portail des paysans sous le nom de domaine  "portail-paysans.mon-entreprise.io", pour tests.
- dans ta nouvelle version, partout dans ton code tu remplaces "autre-microservice.mon-entreprise.io" par  "http://portail-paysans.mon-entreprise.io/bernard" 
- bon en fait n'ecri pas bernard, mais utilisases une varible qui charge sa valeur du fichier de conficguration TOML de ton microservice. oups yaml. Oh si tu veux faire vraiment très vieux, disons du fichier XML de configuration.
- bon après, quand ta modif de code est terminée, et que tout les tests sont au vert, je te montrerais le portail des payasans que j'ai coodé
- regardes, tu  va sur  "http://portail-paysans.mon-entreprise.io/o/meuh" dans firefox, et là t'as un page de login / mot de passe
- hop, maitnenat, sur le portail des paysans, je peux changer le nom de domaine de l'autre microservice, c'est pas de soucis, toi c'est toujours "http://portail-paysans.mon-entreprise.io/bernard" que tu appelles, je peux re-déployer à volonté, on a mêem pas de re-configuration à chaud à faire de ton micro-servie, pour qu'il saches quel est el nouveau nom de domaine !  C4est pas bon, ça?
- et attends, je me susi pas arrêté ensi bon chemin, je vous ai dis à tous de virer le code d'auth autorisation de vos micro-serices, parce que maintenant, c'est dan el portail des paysans que je configure les permissiosn / autorisatios !!!
- T'imagines? ça veut dire que maintenant, on aa viré du code de 140 micro-services  à la fois ! et au leiu de faire 140 backup de 140 database d'autorisations / permissiosn dans chaque microsercie, eh ben on a un seul et unqique backup :!!!
- et du coup j'ai même pu complétement enfermér tous les micro-services dns un sous-réseau dédié, avec un firewall:
- pour tous les protocoles, et tous les numéros de ports,  tout le traffic entreant dans le réseau est interdit, tout le trafiic soortant du réseau est interdit, SAUF:
- une communication réseau sortante est autorisée si et suelement si elle est  à destination de l'hôte réseu "portail-paysans.mon-entreprise.io" , et en provenance de l'un des hôtes réseau répertoirés dasn le portail des paysans.
- une communicaation réseau entrante n'est aceptée que si elle est en provenance de l'hôte réseau "portail-paysans.mon-entreprise.io" , et si elle est à destination d'un des hôtes réseau référencés dans el portail des paysans

### dernière partie article=> ARchitecture micro-services, le coupe circuit

L'idée est la suivante : 

le load balancer se rend compte qu'il y a a 1 conteneur , ben ça fait  10 fosi qu'il envoie des requête et que ça réponds un code http genre unavailable ou internal server error , bref c'est down. 

Bon ben au lieu de continuer, à chaque fois qu'il reçoit une requête, d'envoyer une requête vers le conteneur, puis recevoir une erreur, et rransmettrela réponse avec l'erreur, il décide à la place, pendant les 30 prochaines secondes, de renvoyer directement la page d'erreur, sans même envoyer une seule requête, d'un quelconque protocole réseau, vers le conteneur derrière.

Quand il y a uen forte cahrge, çça soulage énormément la bande passante du réseau interne, derrière le load balancer !!!
évidemment , il y ades paramètres de configuration qui permette d'adopter le comportement optimal du coupe-circuit : 
* la durée pendant laquelle le laod balancer renvoie directement l'erreur sans essayer de contacter le ocnteneur derrière
* les pages d'erreurs renoyées (html/css/js/imgs)

### infra
ajouter integration free ipa server / keycloak / api gateway, ça donne deux stacks :

* un :
  * free ipa server / <=usePAM=> / keycloak / <=SAML=> / Tyk
  * free ipa server / <=usePAM=> / keycloak / <=SAML=> / Gravitee.io => tester les 17 000 par secondes, setup terraform de l'infra de tests avec symian army.
  
  Ah! mais oui au fait, tu te rappelles, cher développeur, avant j'allais moi me logguer, dans le portail des paysans, pour configurer l'alisa, le nom de domaine pour chacun des 140 microservices?
  BOn, maintenant, Traefik fait cela automatiqeuement, en se basnat les paramètres suivants que tu  collés dans ton yaml de déploiement (`docker-compose;yml` ou un `saint-nectaire-deployement.yaml`) : 

```yaml
version: 3
services:
...

  mailer_campagnes_marketing:
    image: campagnes-e-mailer:4.3.1-fourme-d-ambert
    labels:
      - traefik.backend=mailer_campagnes_marketing
      - traefik.frontend.rule=Host:mailer-campagnes-marketing.mon-entreprise.io
      - traefik.docker.network=reseau_dans_lequel_le_contneur_docker_traefik_est_aussi
      - traefik.port=8080
    networks:
      - reseau_dans_lequel_le_contneur_docker_traefik_est_aussi
    depends_on:
      - mongo
  notre_traefik:
    image: traefik # The official Traefik docker image
    command: --api --docker # Enables the web UI and tells Traefik to listen to docker
    ports:
      - "80:80"     # The HTTP port
      - "8080:8080" # The Web UI (enabled by --api)
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock # So that Traefik can listen to the Docker events
    networks:
      - reseau_dans_lequel_le_contneur_docker_traefik_est_aussi
```




  
