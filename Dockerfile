ARG ALPINE_VER=3.16

FROM alpine:${ALPINE_VER} AS alpine

#
# BUILD
#
FROM alpine AS builder

ARG TARGETARCH

RUN mkdir -p /bar/usr/local/bin

# add local files
COPY root/ /bar/

# add terraform
RUN \
    apk add --no-cache \
        curl \
        jq && \
    TF_VER=$(curl -fsSL "https://api.github.com/repos/hashicorp/terraform/releases/latest" | jq -r '.tag_name' | sed 's/v//') && \
    curl -LJ https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_${TARGETARCH}.zip -o terraform.zip && \
    unzip terraform.zip -d /bar/usr/bin

#
# RELEASE
#
FROM alpine
LABEL maintainer="by275"
LABEL org.opencontainers.image.source https://github.com/by275/docker-terraform

# add build artifacts
COPY --from=builder /bar/ /

RUN \
    echo "**** install runtime packages ****" && \
    apk add --update --no-cache \
        bash \
        curl \
        ca-certificates \
        tzdata \
        tini && \
    echo "**** permissions ****" && \
    chmod a+x /usr/local/bin/* && \
    echo "**** cleanup ****" && \
    rm -rf \
        /tmp/* \
        /root/.cache

# environment settings
ENV LANG=C.UTF-8 \
    TZ=Asia/Seoul \
    PS1="\u@\h:\w\\$ " \
    DATE_FORMAT="+%4Y/%m/%d %H:%M:%S" \
    TF_WORK_DIR=/config \
    TF_DATA_DIR=/data \
    TF_AUTO_RUN=0

VOLUME /config /data
WORKDIR /config

ENTRYPOINT ["/sbin/tini", "--", "entrypoint.sh"]
