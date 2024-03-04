ARG mugs_version=latest
FROM mugs-ui-tui:$mugs_version
ARG mugs_version

LABEL org.opencontainers.image.source=https://github.com/Raku-MUGS/MUGS-UI-WebSimple

USER raku:raku

WORKDIR /home/raku/MUGS/MUGS-UI-WebSimple
COPY . .

RUN zef install --deps-only . \
 && zef install . --/test \
 && rm -rf /home/raku/.zef $(find /tmp/.zef -maxdepth 1 -user raku)

ENV MUGS_WEB_SIMPLE_HOST="0.0.0.0"
ENV MUGS_WEB_SIMPLE_PORT="20000"
EXPOSE 20000

CMD ["mugs-web-simple"]
