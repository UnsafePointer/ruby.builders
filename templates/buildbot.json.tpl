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
        "containerPort": ${web_container_port}
      },
      {
        "containerPort": ${workers_container_port}
      }
    ],
    "environment": [
      {
        "name": "BUILDBOT_WEB_URL",
        "value": "ssm:///buildbot/web-url"
      },
      {
        "name": "BUILDBOT_ADMIN_USERNAME",
        "value": "ssm:///buildbot/admin-username"
      },
      {
        "name": "BUILDBOT_ADMIN_PASSWORD",
        "value": "ssm:///buildbot/admin-password"
      },
      {
        "name": "BUILDBOT_LINUX_WORKER_USERNAME",
        "value": "ssm:///buildbot/worker/linux-worker-username"
      },
      {
        "name": "BUILDBOT_WINDOWS_WORKER_USERNAME",
        "value": "ssm:///buildbot/worker/windows-worker-username"
      },
      {
        "name": "BUILDBOT_WORKER_PASSWORD",
        "value": "ssm:///buildbot/worker/worker-password"
      },
      {
        "name": "BUILDBOT_GITHUB_HOOK_SECRET",
        "value": "ssm:///buildbot/github_hook_secret"
      },
      {
        "name": "BUILDBOT_GITHUB_API_TOKEN",
        "value": "ssm:///buildbot/github_api_token"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${region}",
        "awslogs-group": "${name}",
        "awslogs-stream-prefix": "${name}"
      }
    }
  }
]
