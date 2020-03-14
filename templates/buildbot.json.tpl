[
  {
    "cpu": 128,
    "essential": true,
    "image": "${image}",
    "memory": 128,
    "memoryReservation": 64,
    "name": "${name}",
    "portMappings": [
      {
        "containerPort": ${container_port}
      }
    ],
    "environment": [
      {
        "name": "BUILDBOT_CONFIG_URL",
        "value": "https://github.com/buildbot/buildbot-docker-example-config/archive/master.tar.gz"
      }
    ]
  }
]
