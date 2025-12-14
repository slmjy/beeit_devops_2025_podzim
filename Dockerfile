# Dockerfile
FROM ubuntu:latest AS base

WORKDIR /app
RUN apt-get update && apt-get install -y sudo bash

COPY linux_cli.sh /usr/local/bin/linux_cli
RUN chmod +x /usr/local/bin/linux_cli

FROM base AS tests

COPY test_linux_cli.sh /app/test_linux_cli.sh
RUN chmod +x /app/test_linux_cli.sh

RUN /app/test_linux_cli.sh

FROM base AS production

ENTRYPOINT ["/usr/local/bin/linux_cli"]

CMD ["-h"]
