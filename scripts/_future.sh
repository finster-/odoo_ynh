
log() {
  echo "${1}"
}

info() {
  log "[INFO] ${1}"
}

warn() {
  log "[WARN] ${1}"
}

err() {
  log "[ERR] ${1}"
}
ynh_check_var () {
    test -n "$1" || ynh_die "$2"
}

ynh_exit_properly () {
    exit_code=$?
    if [ "$exit_code" -eq 0 ]; then
            exit 0
    fi
    trap '' EXIT
    set +eu
    echo -e "\e[91m \e[1m"
    err "$app script has encountered an error."

    if type -t CLEAN_SETUP > /dev/null; then
        CLEAN_SETUP
    fi

    ynh_die
}

# Activate signal capture
# Exit if a command fail, and if a variable is used unset.
# Capturing exit signals on shell script
#
# example: CLEAN_SETUP () {
#             # Clean residual file un remove by remove script
#          }
#          ynh_trap_on
ynh_trap_on () {
    set -eu
    trap ynh_exit_properly EXIT # Capturing exit signals on shell script
}

ynh_export () {
    local ynh_arg=""
    for var in $@;
    do
        ynh_arg=$(echo $var | awk '{print toupper($0)}')
        ynh_arg="YNH_APP_ARG_$ynh_arg"
        export $var=${!ynh_arg}
    done
}

# Save listed var in YunoHost app settings
# usage: ynh_save_args VARNAME1 [VARNAME2 [...]]
ynh_save_args () {
    for var in $@;
    do
        ynh_app_setting_set $app $var ${!var}
    done
}

ynh_sso_access () {
    ynh_app_setting_set $app unprotected_uris "/"

    if [[ $is_public -eq 0 ]]; then
        ynh_app_setting_set $app protected_uris "$1"
    fi
    sudo yunohost app ssowatconf
}
ynh_configure () {
    local TEMPLATE=$1
    local DEST=$2
    type j2 2>/dev/null || sudo pip install j2cli
    j2 "${YNH_CWD}/../conf/$TEMPLATE.j2" > "${YNH_CWD}/../conf/$TEMPLATE"
    sudo cp "${YNH_CWD}/../conf/$TEMPLATE" "$DEST"
}

ynh_configure_nginx () {
    ynh_configure nginx.conf /etc/nginx/conf.d/$domain.d/$app.conf
    sudo service nginx reload
}
# Find a free port and return it
#
# example: port=$(ynh_find_port 8080)
#
# usage: ynh_find_port begin_port
# | arg: begin_port - port to start to search
ynh_find_port () {
    port=$1
    test -n "$port" || ynh_die "The argument of ynh_find_port must be a valid port."
    while netcat -z 127.0.0.1 $port       # Check if the port is free
    do
        port=$((port+1))    # Else, pass to next port
    done
    echo $port
}

ynh_rm_nginx_conf () {
    if [ -e "/etc/nginx/conf.d/$domain.d/$app.conf" ]; then
        sudo rm "/etc/nginx/conf.d/$domain.d/$app.conf"
        sudo service nginx reload
    fi
}


ynh_secure_rm () {
    [[ "/var/www /opt /home/yunohost.app" =~ $1 ]] \
        || (test -n "$1" && sudo rm -Rf $1 )
}

# Upgrade
ynh_read_json () {
    python3 -c "import sys, json;print(json.load(open('$1'))['$2'])"
}

ynh_read_manifest () {
    if [ -f '../manifest.json' ] ; then
        ynh_read_json '../manifest.json' "$1"
    else
        ynh_read_json '../settings/manifest.json' "$1"
    fi
}
ynh_exit_if_up_to_date () {
    if [ "${version}" = "${last_version}" ]; then
        info "Up-to-date, nothing to do"
        exit 0
    fi
}


# # Execute a command as root user
#
# usage: ynh_psql_execute_as_root sql [db]
# | arg: sql - the SQL command to execute
# | arg: db - the database to connect to
ynh_psql_execute_as_root () {
        sudo su -c "psql" - postgres <<< ${1}
}

# Create a user
#
# usage: ynh_psql_create_user user pwd [host]
# | arg: user - the user name to create
# | arg: pwd - the password to identify user by
ynh_psql_create_user() {
        ynh_psql_execute_as_root \
        "CREATE USER ${1} WITH PASSWORD '${2}';"
}

# Create a database and grant optionnaly privilegies to a user
#
# usage: ynh_psql_create_db db [user [pwd]]
# | arg: db - the database name to create
# | arg: user - the user to grant privilegies
# | arg: pwd - the password to identify user by
ynh_psql_create_db() {
    db=$1
    # grant all privilegies to user
    if [[ $# -gt 1 ]]; then
        ynh_psql_create_user ${2} "${3}"
        sudo su -c "createdb -O ${2} $db" -  postgres
    else
        sudo su -c "createdb $db" -  postgres
    fi

}

# Drop a database
#
# usage: ynh_psql_drop_db db
# | arg: db - the database name to drop
ynh_psql_drop_db() {
    sudo su -c "dropdb ${1}" -  postgres
}

# Drop a user
#
# usage: ynh_psql_drop_user user
# | arg: user - the user name to drop
ynh_psql_drop_user() {
    sudo su -c "dropuser ${1}" - postgres
}


# Execute a command as another user
# usage: exec_as USER COMMAND [ARG ...]
exec_as() {
  local USER=$1
  shift 1

  if [[ $USER = $(whoami) ]]; then
    eval "$@"
  else
    # use sudo twice to be root and be allowed to use another user
    sudo sudo -u "$USER" "$@"
  fi
}

ynh_debian_release () {
	lsb_release --codename --short
}

is_stretch () {
	if [ "$(ynh_debian_release)" == "stretch" ]
	then
		return 0
	else
		return 1
	fi
}

is_jessie () {
	if [ "$(ynh_debian_release)" == "jessie" ]
	then
		return 0
	else
		return 1
	fi
}

