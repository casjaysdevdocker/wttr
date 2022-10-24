FROM golang:1-alpine AS builder

RUN apk add --no-cache git

WORKDIR /app

RUN git clone "https://github.com/chubin/wttr.in" "/tmp/wttr" && \
  cp -R "/tmp/wttr/share/we-lang/." /app/

RUN go get -u github.com/mattn/go-colorable && \
  go get -u github.com/klauspost/lctime && \
  go get -u github.com/mattn/go-runewidth && \
  cd /app && CGO_ENABLED=0 go build .

FROM casjaysdevdocker/alpine:latest AS build

ARG ALPINE_VERSION="v3.16"

ARG DEFAULT_DATA_DIR="/usr/local/share/template-files/data" \
  DEFAULT_CONF_DIR="/usr/local/share/template-files/config" \
  DEFAULT_TEMPLATE_DIR="/usr/local/share/template-files/defaults"

ARG PACK_LIST="bash python3 py3-pip py3-scipy py3-wheel py3-gevent zlib jpeg llvm11 libtool py3-numpy-dev python3-dev"
ARG PACK_DEV="autoconf automake g++ gcc jpeg-dev llvm11-devmake zlib-dev"

ENV LANG=en_US.UTF-8 \
  ENV=ENV=~/.bashrc \
  TZ="America/New_York" \
  SHELL="/bin/sh" \
  TERM="xterm-256color" \
  TIMEZONE="${TZ:-$TIMEZONE}" \
  HOSTNAME="casjaysdev-wttr" \
  LLVM_CONFIG=/usr/bin/llvm11-config

WORKDIR /app

COPY ./rootfs/. /
COPY --from=builder /app/wttr.in /app/bin/wttr.in
COPY --from=builder /tmp/wttr/bin /app/bin
COPY --from=builder /tmp/wttr/lib /app/lib
COPY --from=builder /tmp/wttr/share /app/share
COPY --from=builder /tmp/wttr/requirements.txt /app

RUN set -ex; \
  rm -Rf "/etc/apk/repositories"; \
  mkdir -p "${DEFAULT_DATA_DIR}" "${DEFAULT_CONF_DIR}" "${DEFAULT_TEMPLATE_DIR}"; \
  echo "http://dl-cdn.alpinelinux.org/alpine/${ALPINE_VERSION}/main" >>"/etc/apk/repositories"; \
  echo "http://dl-cdn.alpinelinux.org/alpine/${ALPINE_VERSION}/community" >>"/etc/apk/repositories"; \
  if [ "${ALPINE_VERSION}" = "edge" ]; then echo "http://dl-cdn.alpinelinux.org/alpine/${ALPINE_VERSION}/testing" >>"/etc/apk/repositories" ; fi ; \
  apk update --update-cache && apk add --no-cache ${PACK_LIST} && \
  apk add --no-cache --virtual .build ${PACK_DEV} && \
  mkdir -p /app/cache && \
  chmod -R o+rw /var/run && \
  pip install -r requirements.txt --no-cache-dir && \
  apk del --no-cache -r .build

RUN echo 'Running cleanup' ; \
  rm -Rf /usr/share/doc/* /usr/share/info/* /tmp/* /var/tmp/* ; \
  rm -Rf /usr/local/bin/.gitkeep /usr/local/bin/.gitkeep /config /data /var/cache/apk/* ; \
  rm -rf /lib/systemd/system/multi-user.target.wants/* ; \
  rm -rf /etc/systemd/system/*.wants/* ; \
  rm -rf /lib/systemd/system/local-fs.target.wants/* ; \
  rm -rf /lib/systemd/system/sockets.target.wants/*udev* ; \
  rm -rf /lib/systemd/system/sockets.target.wants/*initctl* ; \
  rm -rf /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* ; \
  rm -rf /lib/systemd/system/systemd-update-utmp* ; \
  if [ -d "/lib/systemd/system/sysinit.target.wants" ]; then cd "/lib/systemd/system/sysinit.target.wants" && rm $(ls | grep -v systemd-tmpfiles-setup) ; fi

FROM scratch

ARG \
  SERVICE_PORT="8002" \
  EXPOSE_PORTS="80" \
  PHP_SERVER="wttr" \
  NODE_VERSION="system" \
  NODE_MANAGER="system" \
  BUILD_VERSION="latest" \
  LICENSE="MIT" \
  IMAGE_NAME="wttr" \
  BUILD_DATE="Mon Oct 24 05:30:33 PM EDT 2022" \
  TIMEZONE="America/New_York"

LABEL maintainer="CasjaysDev <docker-admin@casjaysdev.com>" \
  org.opencontainers.image.vendor="CasjaysDev" \
  org.opencontainers.image.authors="CasjaysDev" \
  org.opencontainers.image.vcs-type="Git" \
  org.opencontainers.image.name="${IMAGE_NAME}" \
  org.opencontainers.image.base.name="${IMAGE_NAME}" \
  org.opencontainers.image.license="${LICENSE}" \
  org.opencontainers.image.vcs-ref="${BUILD_VERSION}" \
  org.opencontainers.image.build-date="${BUILD_DATE}" \
  org.opencontainers.image.version="${BUILD_VERSION}" \
  org.opencontainers.image.schema-version="${BUILD_VERSION}" \
  org.opencontainers.image.url="https://hub.docker.com/r/casjaysdevdocker/${IMAGE_NAME}" \
  org.opencontainers.image.vcs-url="https://github.com/casjaysdevdocker/${IMAGE_NAME}" \
  org.opencontainers.image.url.source="https://github.com/casjaysdevdocker/${IMAGE_NAME}" \
  org.opencontainers.image.documentation="https://hub.docker.com/r/casjaysdevdocker/${IMAGE_NAME}" \
  org.opencontainers.image.description="Containerized version of ${IMAGE_NAME}"

ENV LANG=en_US.UTF-8 \
  ENV=~/.bashrc \
  SHELL="/bin/bash" \
  PORT="${SERVICE_PORT}" \
  TERM="xterm-256color" \
  PHP_SERVER="${PHP_SERVER}" \
  CONTAINER_NAME="${IMAGE_NAME}" \
  TZ="${TZ:-America/New_York}" \
  TIMEZONE="${TZ:-$TIMEZONE}" \
  HOSTNAME="casjaysdev-${IMAGE_NAME}" \
  WTTR_MYDIR="/app" \
  WTTR_GEOLITE="/app/GeoLite2-City.mmdb" \
  WTTR_WEGO="/app/bin/wttr.in" \
  WTTR_LISTEN_HOST="0.0.0.0" \
  WTTR_LISTEN_PORT="${PORT}"

COPY --from=build /. /

USER root
WORKDIR /root

VOLUME [ "/config","/data" ]

EXPOSE $EXPOSE_PORTS

#CMD [ "" ]
ENTRYPOINT [ "tini", "-p", "SIGTERM", "--", "/usr/local/bin/entrypoint.sh" ]
HEALTHCHECK --start-period=1m --interval=2m --timeout=3s CMD [ "/usr/local/bin/entrypoint.sh", "healthcheck" ]
