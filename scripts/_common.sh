#
# Common variables
#

export appname="libreerp"
export FORKNAME="odoo"
DEPENDENCIES="curl postgresql xfonts-75dpi xfonts-base wkhtmltopdf node-less python3-dev gcc libldap2-dev libssl-dev libsasl2-dev python3-pip python3-dev python3-venv python3-wheel libxslt-dev libzip-dev python3-setuptools libjpeg-dev zlib1g-dev libfreetype6-dev libffi-dev"

function debranding() {
    # Remove Odoo references to avoid trademark issue
    if [ -d $final_path/$appname/$FORKNAME ]; then
        python_app=$final_path/$appname/$FORKNAME
    else
        python_app=$final_path/$appname/openerp
    fi
    find $final_path/$appname -type f \( -iname '*.xml' -o -iname '*.po' \) -exec sed -i 's/Powered by <a[^>]*>Odoo<\/a>//g' {} \;
    find $final_path/$appname -type f \( -iname '*.xml' -o -iname '*.po' \) -exec sed -i 's/<a[^>]*>Powered by <[^>]*>Odoo<\/[^>]*><\/a>//g' {} \;
    find $final_path/$appname -type f \( -iname '*.xml' -o -iname '*.po' \) -exec sed -i 's/Powered by <[^>]*>Odoo<\/[^>]*>//g' {} \;
    find $final_path/$appname -type f \( -iname '*.xml' -o -iname '*.po' \) -exec sed -i 's/Powered by <[^>]*><img[^>]*Odoo[^>]*><\/a>//g' {} \;
    sed -i 's/<a[^>]*>My Odoo.com account<\/a>//g' $final_path/$appname/addons/web/static/src/xml/base.xml
    sed -i 's/<a[^>]*>Documentation<\/a>//g' $final_path/$appname/addons/web/static/src/xml/base.xml
    sed -i 's/<a[^>]*>Support<\/a>//g' $final_path/$appname/addons/web/static/src/xml/base.xml
    cp ../conf/logo_type.png  $python_app/addons/base/static/img/logo_white.png
    cp ../conf/favicon.ico  $final_path/$appname/addons/web/static/src/img/favicon.ico

}
function setup_files() {
   
    if [[ $oca -eq 0 ]]; then
        ynh_setup_source $final_path/$appname $app_version
    else
        ynh_setup_source $final_path/$appname "oca-$app_version"
    fi
    debranding
    mkdir -p $final_path/custom-addons
    chown -R $app:$app $final_path
    touch /var/log/$app.log
    chown $app:$app /var/log/$app.log
    
    if [ ! -f $conf_file ]; then
        ynh_configure server.conf $conf_file
        chown $app:$app $conf_file

        # Autoinstall the LDAP auth module
        if ls $final_path/$appname/$FORKNAME-bin > /dev/null ; then
            ynh_replace_string "^{$" "{'auto_install': True," ${final_path}/$appname/addons/auth_ldap/__manifest__.py
        else
            ynh_replace_string "'auto_install': False" "'auto_install': True" ${final_path}/$appname/addons/auth_ldap/__openerp__.py
        fi
    fi 

}
# Install dependencies
function install_dependencies() {
    ynh_add_swap 1024
    ynh_install_app_dependencies $DEPENDENCIES

    if ! wkhtmltopdf --version | grep "wkhtmltopdf 0.12.4 (with patched qt)"; then
        # The debian package has a bug so we deploy a more recent version
        if [ -f '../manifest.json' ] ; then
            ynh_setup_source /usr/
        else
            OLD_YNH_CWD=$YNH_CWD
            YNH_CWD=$YNH_CWD/../settings/conf
            ynh_setup_source /usr/
            YNH_CWD=$OLD_YNH_CWD
        fi
    fi
    pushd $final_path
    if grep "python3" $final_path/$appname/$FORKNAME-bin ; then
        python3 -m venv venv
        venv/bin/pip3 install wheel
        venv/bin/pip3 install -r $appname/requirements.txt
    else
        virtualenv venv
        venv/bin/pip install wheel
        venv/bin/pip install -r $appname/requirements.txt
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
