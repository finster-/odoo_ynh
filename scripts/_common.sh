#
# Common variables
#

APPNAME="odoo"

function define_paths() {
    command -v bc >/dev/null 2>&1 || ynh_package_install bc
    # In odoo 10 some file change
    if [ $(echo "$odoo_version >= 10" | bc) -ne 0 ]; then
        if [ $(echo "$odoo_version >= 11" | bc) -ne 0 ]; then
            export source_path=/usr/lib/python3/dist-packages/odoo/
        else
            export source_path=/usr/lib/python2.7/dist-packages/odoo/
        fi
        export conf_file=/etc/odoo/odoo.conf
        export bin_file=/usr/bin/odoo
    else
        export source_path=/usr/lib/python2.7/dist-packages/openerp/
        export conf_file=/etc/odoo/openerp-server.conf
        export bin_file=/usr/bin/openerp-server
    fi
}

function check_odoo_version () {
    command -v bc >/dev/null 2>&1 || ynh_package_install bc
    if [ $(echo "$odoo_version >= 10" | bc) -ne 0 ]; then
        if [ -f /usr/bin/openerp-server ]; then
            ynh_die "Another version of odoo is installed"
        fi
    else
        if [ -f /usr/bin/odoo ]; then
            ynh_die "Another version of odoo is installed"
        fi
    fi
}

function define_is_master() {
    if [ -f $bin_file ]; then
        export is_master=false
    else
        export is_master=true
    fi
}

function define_port () {
    if [ "$is_master" = true ]; then
        export port=$(ynh_find_port 8069)
        yunohost app checkport $port
        if [[ ! $? -eq 0 ]]; then
        ynh_die "Port 8069 unavailable" 1
        fi
    else
        # FIXME find master port
        export port="8069"
    fi
}

function define_dbpass () {
    # TODO set -x
    if [ "$is_master" = true ]; then
        # Generate random password
        if [ "${1:-}" = "restore" ]; then
            export dbpass=$(ynh_app_setting_get $app psqlpwd)
        else
            export dbpass=$(ynh_string_random)
        fi
    else
        export dbpass=$(grep db_password /etc/odoo/odoo.conf | cut -d \= -f 2 | sed -e 's/^[ \t]*//')
    fi
    ynh_app_setting_set "$app" psqlpwd "$dbpass"
}

# Install dependencies
function install_dependencies() {
    if [ ! -f /etc/apt/sources.list.d/odoo.list ]; then
        # Install Odoo
        # Prepare installation
        # We nee to setup postgresql before to let the odoo package make some magic
        # see red comment on https://nightly.odoo.com/
        ynh_package_install curl bc postgresql

        # Install Odoo
        curl -sS https://nightly.odoo.com/odoo.key | sudo apt-key add -
        sh -c "echo 'deb http://nightly.odoo.com/${odoo_version}/nightly/deb/ ./' > /etc/apt/sources.list.d/odoo.list"
        # TODO if 8.0 install https://www.odoo.com/apps/modules/8.0/shell/
    fi

    if is_jessie ; then
        sudo echo "deb http://http.debian.net/debian jessie-backports main" | sudo tee /etc/apt/sources.list.d/jessie-backport.list
        apt-get update
        ynh_install_app_dependencies curl postgresql odoo xfonts-75dpi xfonts-base wkhtmltopdf node-less python-xlrd python3-dev gcc libldap2-dev libssl-dev libsasl2-dev python3-pip
        pip3 install pyldap
    fi
    if is_stretch ; then
        sudo echo "deb http://http.debian.net/debian stretch-backports main" | sudo tee /etc/apt/sources.list.d/stretch-backport.list
        apt-get update
        ynh_install_app_dependencies curl postgresql odoo xfonts-75dpi xfonts-base wkhtmltopdf node-less python-xlrd python3-dev gcc libldap2-dev libssl-dev libsasl2-dev python3-pip python3-num2words python3-pyldap python3-phonenumbers
    fi

    if ! wkhtmltopdf --version | grep "wkhtmltopdf 0.12.4 (with patched qt)"; then
        # The debian package has a bug so we deploy a more recent version
        ynh_setup_source /usr/
    fi
}


# Create db
function create_general_db() {
    service postgresql reload
    if ! su -c "psql -lqt | cut -d \| -f 1 " - postgres | grep $APPNAME; then
        # Generate random password
        ynh_psql_execute_as_root "ALTER USER $APPNAME WITH CREATEDB;"
        ynh_psql_execute_as_root "ALTER USER $APPNAME WITH PASSWORD '$dbpass';"
        su -c "createdb -O $APPNAME $APPNAME" -  postgres
    fi
}

# Add services
function add_services() {
    if ! grep "^postgresql:$" /etc/yunohost/services.yml; then
        yunohost service add postgresql
    fi
    if ! grep "^odoo:$" /etc/yunohost/services.yml; then
        ynh_configure odoo.service /etc/systemd/system/odoo.service
        rm /etc/init.d/odoo

        yunohost service add odoo --log /var/log/odoo/odoo-server.log
        yunohost service stop odoo
        yunohost service start odoo
        yunohost service enable odoo
    fi
}

function ssowat_and_restart() {
    # Restart odoo service
    service odoo restart

    # Configure SSOWat
    ynh_sso_access "/web/database/manager"

    # Reload services
    service nginx reload
}
