FROM buildbot/buildbot-master:v2.7.0

COPY master.cfg /var/lib/buildbot

RUN pip install boto3

CMD ["dumb-init", "/usr/src/buildbot/docker/start_buildbot.sh"]
