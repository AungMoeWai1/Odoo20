#!/bin/bash

# Default values if not provided
: "${DB_HOST:=odoo_db}"
: "${PORT:=5432}"
: "${USER:=odoo20}"
: "${PASSWORD:=odoo20}"
: "${DB_NAME:=odoo_db}"

exec python3 /opt/odoo/odoo-bin \
    -c /etc/odoo.conf \
    --db_host="$DB_HOST" \
    --db_port="$DB_PORT" \
    --db_user="$DB_USER" \
    --db_password="$DB_PASSWORD" \
    -d "$DB_NAME" \
    # for first start run plese use install base and web module.
    -i base,web 
    # -u all
