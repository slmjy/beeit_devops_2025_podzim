FROM ubuntu:22.04

WORKDIR /app

COPY linux_cli.sh /app/linux_cli.sh

RUN chmod +x /app/linux_cli.sh \
    && apt-get update \
    && apt-get install -y procps apt-utils \
    && rm -rf /var/lib/apt/lists/*


ENTRYPOINT ["/app/linux_cli.sh"]


CMD ["-h"]



