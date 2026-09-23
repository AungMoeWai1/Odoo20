#!/bin/bash
set -e

# Default values if not provided
: "${DB_HOST:=odoo_db}"
: "${DB_PORT:=5432}"
: "${DB_USER:=odoo20}"
: "${DB_PASSWORD:=odoo20}"
: "${DB_NAME:=odoo_db}"

MARKER_DIR="/data/odoo/filestore"
MARKER_FILE="$MARKER_DIR/.initialized_${DB_NAME}"
mkdir -p "$MARKER_DIR"

echo "Waiting for Postgres at $DB_HOST:$DB_PORT..."
until python3 -c "
import psycopg2, sys
try:
    psycopg2.connect(host='$DB_HOST', port=$DB_PORT, user='$DB_USER', password='$DB_PASSWORD', dbname='postgres').close()
except Exception as e:
    print(e, file=sys.stderr)
    sys.exit(1)
"; do
    echo "Postgres not ready yet, retrying in 2s..."
    sleep 2
done
echo "Postgres is up."

if [ ! -f "$MARKER_FILE" ]; then
    echo "No init marker found -> initializing database '$DB_NAME' with base,web modules (one-time)..."
    python3 /opt/odoo/odoo-bin \
        -c /etc/odoo.conf \
        --db_host="$DB_HOST" \
        --db_port="$DB_PORT" \
        --db_user="$DB_USER" \
        --db_password="$DB_PASSWORD" \
        -d "$DB_NAME" \
        -i base,web \
        --stop-after-init
    touch "$MARKER_FILE"
    echo "Initialization complete."
else
    echo "Init marker found -> skipping initialization."
fi

echo "Starting Odoo server..."
exec python3 /opt/odoo/odoo-bin \
    -c /etc/odoo.conf \
    --db_host="$DB_HOST" \
    --db_port="$DB_PORT" \
    --db_user="$DB_USER" \
    --db_password="$DB_PASSWORD" \
    -d "$DB_NAME" \
    -i base,web \
    -u all
