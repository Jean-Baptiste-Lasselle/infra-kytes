FROM mongo:latest

# - Marguerite.io Digitals

# La commande [echo 'db.runCommand("ping").ok' | mongo localhost:27017/test --quiet], doit envoyer sur la sortie standard, la valeur '1'.
# - > Il faudra à l'avenir utilsier ce healthcheck, plus fin que celui ci-dessous : 
EXPOSE 27017

# USER 1001

# COPY mongo-healthcheck /usr/local/bin/
RUN mkdir -p /testlive/
COPY replicaset-health-check /testlive/
COPY replicaset-health-check.silencieux /usr/local/bin/

# - -------------------------------------------------------------
# - Rendu exécutable par operations.sh à la place, ou devrait 
# - être commité exécutable dans ce repository Git.
# - -------------------------------------------------------------
# RUN chmod +x /usr/local/bin/mongo-healthcheck
# - -------------------------------------------------------------
HEALTHCHECK --interval=6s --timeout=5s --retries=150  CMD /usr/local/bin/replicaset-health-check.silencieux 

# ENTRYPOINT [ "/app-entrypoint.sh" ]
# CMD [ "/run.sh" ]
# see https://medium.freecodecamp.org/docker-entrypoint-cmd-dockerfile-best-practices-abc591c30e21 for improvements 
# CMD ["/usr/bin/mongod", "--smallfiles", "--oplogSize", "128", "--replSet", "rs0"]

