[
  {
    "cpu": 256,
    "essential": true,
    "image": "${image}",
    "memory": 384,
    "memoryReservation": 128,
    "name": "${name}",
    "portMappings": [
      {
        "containerPort": ${container_port}
      }
    ],
    "environment": [
      {
        "name": "BUILDBOT_WEB_URL",
        "value": "ssm:///buildbot/web-url"
      }
    ]
  }
]
