# docker-terraform

## Quick Start

### version check

```bash
$ docker run --rm ghcr.io/by275/terraform:latest version
Terraform v1.2.1
on linux_amd64
```

### init

Place your `*.tf` file in `/config`, then

```bash
$ docker run --rm \
    -v ${PWD}/config:/config \
    ghcr.io/by275/terraform:latest init

Initializing the backend...

Initializing provider plugins...

```

## Usage

### Automation

First, try with `TF_AUTO_RUN=1`, which will be executing terraform commands `init`, `plan`, and `apply` in order.

```bash
docker run --rm \
    -v ${PWD}/config:config \
    -e TF_AUTO_RUN=1 \
    -e TZ=Asia/Seoul \
    ghcr.io/by275/terraform:latest
```

If there's no problem with your configuration, use `TF_AUTO_RUN=2` to execute `apply` repeatedly until it is successful.

If you want to get notified, consider using

```bash
    -v /etc/hostname:/etc/hostname:ro \
    -e DISCORD_WEBHOOK="URL" \
```
