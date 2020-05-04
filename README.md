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
├── main.tf # Terraform project to bootstrap a micro VPC and Buildbot on EC2
├── packer # Contains everything necessary to build the Buildbot worker AMI
│   ├── linux
│   │   ├── build-ami.sh # Bash script to validate and build AMI
│   │   ├── buildbot-worker.service # systemd service unit for Buildbot worker process
│   │   ├── Dockerfile # Dockerfile to test AMI steps locally
│   │   ├── linux.json # Packer template to build a Buildbot worker AMI
│   │   ├── main.tf # Terraform project to test the AMI
│   │   └── self-terminate.sh # Bash script to self-terminate EC2 instances
│   ├── master
│   │   ├── build-ami.sh # Bash script to validate and build AMI
│   │   ├── buildbot-master.service # systemd service unit for Buildbot master process
│   │   ├── buildbot.tac # Buildbot master configuration file
│   │   ├── Dockerfile # Dockerfile to test AMI steps locally
│   │   ├── linux.json # Packer template to build a Buildbot master AMI
│   │   ├── main.tf # Terraform project to test the AMI
│   │   ├── master.cfg # Buildbot master configuration file
│   │   ├── nginx.service # systemd service unit for nginx process
│   │   ├── ruby.builders.conf # nginx configuration file
│   │   └── self-terminate.sh # Bash script to self-terminate EC2 instances
│   ├── README.md
│   └── windows
│       ├── main.tf # Terraform project to test the AMI
│       └── self-terminate.bat # Bash script to self-terminate EC2 instances
├── README.md
└── templates
    └── buildbot.json.tpl
```
