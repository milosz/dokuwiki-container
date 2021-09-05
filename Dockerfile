FROM alpine AS source-code

RUN mkdir -p /opt/dokuwiki \
 && wget -q -P /tmp https://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz \
 && tar -x -z -f /tmp/dokuwiki-stable.tgz -C /opt/dokuwiki --strip-components 1

FROM alpine

ARG UID=5000
ARG GID=5000
ARG BUILD_DATE

LABEL maintainer Milosz Galazka <milosz@sleeplessbeastie.eu>
LABEL build_date $BUILD_DATE
LABEL application Dokuwiki

COPY --from=source-code /opt/dokuwiki /opt/dokuwiki

RUN apk add --no-cache shadow \
 && groupadd -r -g $GID  dokuwiki \
 && useradd --no-log-init -u $UID -r -g dokuwiki dokuwiki  \
 && chown -R dokuwiki:dokuwiki /opt/dokuwiki \
 && apk del shadow

RUN apk add --no-cache unit-php7 php7-session php7-gd php7-xml php7-json php7-openssl

COPY configuration/acl.auth.php   /opt/dokuwiki/conf/acl.auth.php
COPY configuration/local.php      /opt/dokuwiki/conf/local.php
COPY configuration/plugins.php    /opt/dokuwiki/conf/plugins.php
COPY configuration/users.auth.php /opt/dokuwiki/conf/users.auth.php

COPY configuration/unit.config.json /var/lib/unit/conf.json
RUN chown -R dokuwiki:dokuwiki /var/lib/unit

EXPOSE 8080

USER dokuwiki

WORKDIR /opt/dokuwiki

CMD [ "unitd", "--no-daemon", \
               "--control", "unix:/var/lib/unit/control.unit.sock", \
               "--pid", "/var/lib/unit/unit.pid", \
               "--log", "/dev/stdout" ]
