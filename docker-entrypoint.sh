#!/bin/bash
#
# First do all the setup that we could not do in the Dockerfile, since this
# requires input from the docker run command, e.g.:
# - we have remounted volumes due to --volumes-from
# - we will have environment variables set for MySQL settings
# - we have been --link'ed to the MySQL container, setting the mysql hostname

set -e

if [ -z "$MYSQL_DATABASE" -o -z "$MYSQL_USER" -o -z "$MYSQL_PASSWORD" ]; then
    echo >&2 `basename -- "$0"` \
        ": error: The following environment variables must be set:"
    echo >&2 "    \$MYSQL_DATABASE, \$MYSQL_USER, \$MYSQL_PASSWORD"
    echo >&2 "Add them as command line options to docker run:"
    echo >&2 "    -e MYSQL_DATABASE=... -e MYSQL_USER=... -e MYSQL_PASSWORD=..."
    exit 1
fi

# Append MySQL configuration to Known's config.ini. The config.ini is not
# stored in a volume, so we must do this every time a container is run.
echo "dbname = '$MYSQL_DATABASE'" >> /var/www/known/config.ini
echo "dbuser = '$MYSQL_USER'" >> /var/www/known/config.ini
echo "dbpass = '$MYSQL_PASSWORD'" >> /var/www/known/config.ini

# Fix permissions for the uploads directory, since it was mounted by
# --volumes-from when the container was run.
chown -R root:www-data /var/www/known/uploads
chmod -R 775 /var/www/known/uploads

# We could not init the DB in the Dockerfile, since then we were not yet
# --link'ed to the MySQL container, so do it now. This is idempotent, so it's
# ok to do it every time we run a container even though the DB is in a volume.
mysql -h mysql -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE \
    < /var/www/known/schemas/mysql/mysql.sql

source /etc/apache2/envvars
exec "$@"
