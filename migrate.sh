# `migrate.sh`
# It is a wrapper script for `migrate` CLI tool. It is used to run migrations, create new migrations, set version and display the current database version.
# It is used to simplify the usage of `migrate` CLI tool and to avoid the need of remembering the commands and flags.
# Notice that `migrate` CLI tool is required to be installed in the system.
# Check the official documentation for more information: https://github.com/golang-migrate/migrate/blob/master/cmd/migrate/README.md

#!/bin/bash
set -e

migrations_dir="migrations/"

# Execute migrations based on direction and steps target
#   `direction` -> `up` for forwarding migrations | `down` for backwarding migrations (rollbacks)
#   `steps` -> amount of steps to migrate from current to given direction. If it is not given, it will apply all migrations
function run_migrations() {
    local direction=$1 
    local steps=$2

    case $direction in
        up)
            migrate -path=$migrations_dir -database=$POSTGRES_DATASOURCE up $steps
        ;;
        down)
            migrate -path=$migrations_dir -database=$POSTGRES_DATASOURCE down $steps 
        ;;
        *)
            echo "invalid migration direction"
    esac
}

# Creates a new migrations file for `up` and `down` directions respectively
function create_migration() {
    local name=$1

    # Arbitrary digits limit for track sequential migrations
    # Currently is set to 4, so migrations sequential numbers will be 0001, 0002 and so on. 
    local digits_limit=4

    if [ -z "$name" ]
    then
        echo "invalid migration name"
    else
        migrate create -ext=sql -dir=$migrations_dir -seq -digits=$digits_limit $name > /dev/null 2>&1

        echo "Migration \"$name\" has been created successfuly"
    fi 
}

# Displays the current database version number based on the latest migration ran
function show_version() {
    migrate -path=$migrations_dir -database=$POSTGRES_DATASOURCE version 
}

# Forces version update database without run any migration
# It is used for manual syncing
function set_version() {
    local version=$1

    migrate -path=$migrations_dir -database=$POSTGRES_DATASOURCE force $version
}

command=$1

case $command in
    migrate)
        direction=$2
        target=$3

        run_migrations $direction $target
    ;;
    create)
        migration_name=$2

        create_migration $migration_name
    ;;
    set-version)
        version=$2

        set_version $version
    ;; 
    version)
        show_version
    ;;
    *)
        echo "Invalid command"
    ;;
esac