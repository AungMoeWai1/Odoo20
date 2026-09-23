FROM python:3.12

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential gcc git xvfb wget ca-certificates curl file \
        libpq-dev libxml2-dev libxslt1-dev zlib1g-dev \
        libsasl2-dev libldap2-dev libjpeg-dev libssl-dev libffi-dev && \
    wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb && \
    dpkg -i wkhtmltox_0.12.6.1-2.jammy_amd64.deb || apt-get -f install -y && \
    rm wkhtmltox_0.12.6.1-2.jammy_amd64.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# Download Odoo source from Google Drive using gdown
ARG ODOO_FILE_ID

RUN pip install --no-cache-dir gdown && \
    echo "Downloading from Google Drive (ID: ${ODOO_FILE_ID})..." && \
    gdown "https://drive.google.com/uc?id=${ODOO_FILE_ID}" -O /opt/odoo.tar.gz && \
    echo "Verifying archive..." && \
    file /opt/odoo.tar.gz | grep -q gzip && \
    mkdir -p /opt/odoo && \
    tar -xzf /opt/odoo.tar.gz -C /opt && \
    rm /opt/odoo.tar.gz && \
    du -sh /opt/odoo

# Copy configuration and requirements
COPY ./requirements.txt /opt/requirements.txt

RUN pip install --upgrade setuptools wheel && \
    pip install --upgrade pip && \
    pip install -r /opt/requirements.txt \
    pip install psycopg2-binary

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8069 8071

ENTRYPOINT ["/entrypoint.sh"]
