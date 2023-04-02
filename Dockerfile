FROM docker:stable
USER root
RUN apk add --update bash
RUN apk add --no-cache shadow
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]