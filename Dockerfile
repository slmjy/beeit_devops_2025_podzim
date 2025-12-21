# Dockerfile
FROM ubuntu:20.04 AS base

# Instalace nástrojů
RUN apt-get update && apt-get install -y procps bash

# Nastavení adresáře
WORKDIR /app


# =======================================================
# ------------------------ TESTY ------------------------
# =======================================================
FROM base AS tests

# Kopírování skriptů do testovacího prostředí
COPY linux_cli.sh /app/linux_cli.sh
COPY test_linux_cli.sh /app/test_linux_cli.sh

# Práva pro soubory
RUN chmod +x /app/linux_cli.sh /app/test_linux_cli.sh

# Spuštění testů
RUN ./test_linux_cli.sh


# =======================================================
# ---------------------- IMAGE --------------------------
# =======================================================
FROM base AS production

COPY linux_cli.sh /app/linux_cli.sh
RUN chmod +x /app/linux_cli.sh

# =======================================================
# ------------------ ENTRYPOINT A CMD -------------------
# =======================================================

ENTRYPOINT ["/app/linux_cli.sh"]

CMD ["-h"]
