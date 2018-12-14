#
# Common variables
#

export APPNAME="odoo"
DEPENDENCIES="curl postgresql xfonts-75dpi xfonts-base wkhtmltopdf node-less python3-dev gcc libldap2-dev libssl-dev libsasl2-dev python3-pip python3-dev python3-venv python3-wheel libxslt-dev libzip-dev python3-setuptools python-virtualenv python-wheel python-setuptools libjpeg-dev zlib1g-dev"

# Install dependencies
function install_dependencies() {
    ynh_add_swap 1024
    ynh_install_app_dependencies $DEPENDENCIES

    if ! wkhtmltopdf --version | grep "wkhtmltopdf 0.12.4 (with patched qt)"; then
        # The debian package has a bug so we deploy a more recent version
        ynh_setup_source /usr/
    fi
    pushd $final_path
    if grep "python3" $final_path/$APPNAME/$APPNAME-bin ; then
        python3 -m venv venv
        venv/bin/pip3 install wheel
        venv/bin/pip3 install -r $APPNAME/requirements.txt
    else
        virtualenv venv
        venv/bin/pip install wheel
        venv/bin/pip install -r $APPNAME/requirements.txt
    fi
    popd
}


# Add services
function add_services() {
    if ! grep "^postgresql:$" /etc/yunohost/services.yml; then
        yunohost service add postgresql
    fi
    ynh_configure app.service /etc/systemd/system/$app.service
    systemctl daemon-reload

    yunohost service add $app --log /var/log/$app.log
    yunohost service stop $app
    yunohost service start $app
    yunohost service enable $app
}

function ssowat_and_restart() {
    # Restart odoo service
    service $app restart

    # Configure SSOWat
    ynh_sso_access "/web/database/manager"

    # Reload services
    service nginx reload
}
