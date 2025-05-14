#!/bin/bash
mkdir -p /opt/scripts
curl -L https://.../create_tables.sql -o /opt/scripts/create_tables.sql
curl -L https://.../seed_and_query.sql -o /opt/scripts/seed_and_query.sql
bash /opt/scripts/create_tables.sql
bash /opt/scripts/seed_and_query.sql
