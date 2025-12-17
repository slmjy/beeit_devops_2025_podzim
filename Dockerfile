# Stage 1: BASE
FROM ubuntu:22.04 AS base

WORKDIR /app

RUN apt-get update \
 && apt-get install -y procps dos2unix bash apt-utils \
 && rm -rf /var/lib/apt/lists/*

COPY linux_cli.sh /app/linux_cli.sh

# Upravíme konce řádků a nastavíme spustitelnost
RUN dos2unix /app/linux_cli.sh \
 && chmod +x /app/linux_cli.sh

#Stage 2: TESTS

FROM base AS tests

# Testovací skript
COPY test_linux_cli.sh /app/test_linux_cli.sh

RUN dos2unix /app/test_linux_cli.sh \
 && chmod +x /app/test_linux_cli.sh

RUN /app/test_linux_cli.sh

# Stage 3: PRODUCTION (finální image)
FROM ubuntu:22.04 AS production

WORKDIR /app

RUN apt-get update \
 && apt-get install -y bash procps \
 && rm -rf /var/lib/apt/lists/*

COPY --from=base /app/linux_cli.sh /app/linux_cli.sh

LABEL maintainer="silvia"

ENTRYPOINT ["/app/linux_cli.sh"]
CMD ["-h"]

