FROM ubuntu:22.04

WORKDIR /app

COPY linux_cli.sh

RUN chmod +x linux_cli.sh

FROM base AS tests

COPY test_linux_cli.sh .

RUN chmod +x test_linux_cli.sh \
    && ./test_linux_cli.sh

FROM base AS production

ENTRYPOINT ["./linux_cli.sh"]

CMD []
