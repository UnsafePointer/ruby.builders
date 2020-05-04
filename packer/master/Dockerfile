FROM ubuntu:18.04

# Update

RUN apt-get update

# Python

RUN apt-get -y install python3 python3-pip

# Other tools

RUN apt-get -y install curl

# Buildbot

RUN pip3 install buildbot boto3 txrequests

# User

RUN groupadd --gid 1000 buildbot \
    && useradd --uid 1000 --gid buildbot --shell /bin/bash --create-home buildbot

COPY master.cfg buildbot.tac /home/buildbot/

RUN chown buildbot:buildbot /home/buildbot/master.cfg &&\
    chown buildbot:buildbot /home/buildbot/buildbot.tac

USER buildbot

WORKDIR /home/buildbot
