ARG ALPINE_VER=3.16

FROM alpine:${ALPINE_VER} AS base

#
# BUILD
#
FROM base AS terraform

ARG TARGETARCH

RUN \
    apk add --no-cache \
        curl \
        jq \
        && \
    TF_VER=$(curl -fsSL "https://api.github.com/repos/hashicorp/terraform/releases/latest" | jq -r '.tag_name') && \
    curl -LJ https://releases.hashicorp.com/terraform/${TF_VER//v/}/terraform_${TF_VER//v/}_linux_${TARGETARCH}.zip -o terraform.zip && \
    unzip terraform.zip

# 
# COLLECT
# 
FROM base AS collector

# add terraform
COPY --from=terraform /terraform /bar/usr/local/bin/

# add local files
COPY root/ /bar/

RUN \
    echo "**** directories ****" && \
    mkdir -p /bar/{config,data} && \
    echo "**** permissions ****" && \
    chmod a+x /bar/usr/local/bin/*

#
# RELEASE
#
FROM base
LABEL maintainer="by275"
LABEL org.opencontainers.image.source https://github.com/by275/docker-terraform

RUN \
    echo "**** install runtime packages ****" && \
    apk add --no-cache \
        bash \
        ca-certificates \
        curl \
        tini \
        tzdata

# add build artifacts
COPY --from=collector /bar/ /

# environment settings
ENV LANG=C.UTF-8 \
    TZ=Asia/Seoul \
    PS1="\u@\h:\w\\$ " \
    DATE_FORMAT="+%4Y/%m/%d %H:%M:%S" \
    TF_WORK_DIR=/config \
    TF_DATA_DIR=/data \
    TF_AUTO_RUN=0

VOLUME /config /data

ENTRYPOINT ["/sbin/tini", "--", "entrypoint.sh"]
