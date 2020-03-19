# Buildbot Docker image

## Requirements

* [AWS CLI version 2](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
* [Docker](https://www.docker.com/)

## Usage

Create a file .env with the following contents:

```bash
REGION="us-east-1"
ACCOUNT="XXXXXXXXXXXX"
```

Then execute the following:

```bash
$ env $(cat .env | xargs) ./ecr-login.sh
```

To push to ECR:

```
$ env $(cat .env | xargs) ./ecr-push.sh
```
