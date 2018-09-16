FROM centos:7

ARG VERSION_ROCKET_CHAT
ENV VERSION_ROCKET_CHAT

ARG UTILISATEUR_ROCKETCHAT_HUBOT=jbl
ENV UTILISATEUR_ROCKETCHAT_HUBOT=jbl

ARG UTILISATEUR_ROCKETCHAT_HUBOT_MDP=jbl
ENV UTILISATEUR_ROCKETCHAT_HUBOT_MDP=jbl

ARG CHATROOM_ROCKETCHAT_HUBOT=receptionyooma
ENV CHATROOM_ROCKETCHAT_HUBOT=receptionyooma

RUN yum update -y && yum install -y vim

RUN mkdir -p /marguerite
WORKDIR /marguerite

ADD ./initialiser-rocketchat-pour-hubot .
RUN chmod +x ./initialiser-rocketchat-pour-hubot

CMD ["./initialiser-rocketchat-pour-hubot"]
