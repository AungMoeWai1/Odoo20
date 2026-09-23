FROM python:3.12

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential gcc git xvfb wget ca-certificates curl \
        libpq-dev libxml2-dev libxslt1-dev zlib1g-dev \
        libsasl2-dev libldap2-dev libjpeg-dev libssl-dev libffi-dev && \
    wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb && \
    dpkg -i wkhtmltox_0.12.6.1-2.jammy_amd64.deb || apt-get -f install -y && \
    rm wkhtmltox_0.12.6.1-2.jammy_amd64.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /opt

# Download and extract Odoo source from Google Drive
ARG ODOO_FILE_ID
ARG ODOO_ARCHIVE_URL

RUN if [ -n "$ODOO_ARCHIVE_URL" ]; then \
      echo "Downloading from direct URL..." && \
      curl -L "$ODOO_ARCHIVE_URL" -o odoo.tar.gz; \
    else \
      echo "Downloading from Google Drive (ID: $ODOO_FILE_ID)..." && \
      COOKIE=$(mktemp) && \
      curl -sc "$COOKIE" "https://drive.google.com/uc?export=download&id=${ODOO_FILE_ID}" > /dev/null && \
      CONFIRM=$(grep -oP 'confirm=\K[^&]+' "$COOKIE" || true) && \
      if [ -n "$CONFIRM" ]; then \
        curl -Lb "$COOKIE" "https://drive.google.com/uc?export=download&confirm=${CONFIRM}&id=${ODOO_FILE_ID}" -o odoo.tar.gz; \
      else \
        curl -L "https://drive.google.com/uc?export=download&id=${ODOO_FILE_ID}" -o odoo.tar.gz; \
      fi; \
    fi && \
    file odoo.tar.gz | grep -q gzip && \
    mkdir -p /opt/odoo && \
    tar -xzf odoo.tar.gz -C /opt && \
    rm odoo.tar.gz

# Copy configuration and requirements
COPY ./requirements.txt /opt/requirements.txt

# Install Python dependencies
RUN pip install --upgrade setuptools wheel && \
    pip install --upgrade pip && \
    pip install -r /opt/requirements.txt

# Copy and prepare entrypoint script
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8069 8071

ENTRYPOINT ["/entrypoint.sh"]
