#!/usr/bin/env bash

set -e

role=${CONTAINER_ROLE:-app}
env=${APP_ENV:-production}

if [ "$env" == "local" ] && [ ! -z "$DEV_UID" ]; then
    echo "Changing www-data UID to $DEV_UID"
    echo "The UID should only be changed in development environments."
    usermod -u $DEV_UID www-data
fi


# Application
if [ "$role" = "app" ]; then

    ln -sf /etc/supervisor/conf.d-available/application.conf /etc/supervisor/conf.d/application.conf

fi

exec supervisord -c /etc/supervisor/supervisord.conf