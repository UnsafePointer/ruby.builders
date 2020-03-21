# ruby.builders

[ruby.builders](https://ruby.builders) is the [Buildbot](https://buildbot.net/) instance providing continuous integration for the [ruby](https://github.com/UnsafePointer/ruby) PlayStation emulation project. In this repository you'll find every infrastructure/configuration as code parts and pieces that make it tick.

## Design goals

* Everything has to be code: every single AWS resource, configuration file, continuous integration orchestration script.
* Everything has to run locally: reproduce CI builds locally, trigger CI builds locally, run Buidbot locally.
* Linux workers with Xorg (or Wayland).
* Windows workers with Desktop Window Manager.
* Basic GitHub integration: only trigger builds on pull requests updates, use status API to report back.
* Cost efficiency: ephemeral workers, single master. High availability is not a concern.

## Project structure

```Bash
.
├── docker # Contains everything necessary to build the Buildbot master Docker image
│   ├── Dockerfile
│   ├── README.md
│   ├── docker-compose.yml # Docker Compose project to run everything locally
│   ├── ecr-login.sh
│   ├── ecr-push.sh # Bash script to build and push the Docker image to ECR
│   └── master.cfg
├── main.tf # Terraform project to bootstrap a micro VPC and Buildbot on AWS Fargate
├── packer # Contains everything necessary to build the Buildbot worker AMI
│   ├── README.md
│   ├── build-ami.sh # Bash script to build and publis the AMI
│   ├── linux
│   │   ├── Dockerfile # Dockerfile to test AMI steps locally
│   │   ├── buildbot-worker.service # systemd service unit for Buildbot worker process
│   │   ├── linux.json
│   │   ├── main.tf # Terraform project to test the AMI
│   │   └── self-terminate.sh # Bash script to self-terminate EC2 instances
│   └── windows
│       ├── main.tf
│       └── self-terminate.bat # Bash script to self-terminate EC2 instances
└── templates
    └── buildbot.json.tpl
```
