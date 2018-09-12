FROM mongo:latest

# - Marguerite.io Digitals

# La commande [echo 'db.runCommand("ping").ok' | mongo localhost:27017/test --quiet], doit envoyer sur la sortie standard, la valeur '1'.
# - > Il faudra à l'avenir utilsier ce healthcheck, plus fin que celui ci-dessous : 
EXPOSE 27017

USER 1001

COPY mongo-healthcheck /usr/local/bin/
RUN chmod +x /usr/local/bin/mongo-healthcheck
HEALTHCHECK CMD ["mongo-healthcheck"]

ENTRYPOINT [ "/app-entrypoint.sh" ]
CMD [ "/run.sh" ]


