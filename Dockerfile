ARG mugs_version=latest
FROM mugs-games:$mugs_version
ARG mugs_version

LABEL org.opencontainers.image.source=https://github.com/Raku-MUGS/MUGS-UI-WebSimple

USER root:root

COPY . /home/raku

RUN zef install --deps-only . \
 && raku -c -Ilib bin/mugs-web-simple

RUN zef install . --/test

USER raku:raku

ENV MUGS_WEB_SIMPLE_HOST="0.0.0.0"
ENV MUGS_WEB_SIMPLE_PORT="20000"
EXPOSE 20000

ENTRYPOINT ["mugs-web-simple"]
