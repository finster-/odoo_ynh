#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

export appname="libreerp"
export FORKNAME="odoo"

# dependencies used by the app
pkg_dependencies="curl postgresql xfonts-75dpi xfonts-base wkhtmltopdf node-less python3-dev gcc libldap2-dev libssl-dev libsasl2-dev python3-pip python3-dev python3-venv python3-wheel libxslt-dev libzip-dev python3-setuptools libjpeg-dev zlib1g-dev libfreetype6-dev libffi-dev libpq-dev"

#=================================================
# PERSONAL HELPERS
#=================================================

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
            ynh_replace_string "^{$" "{'auto_install': True," $final_path/$appname/addons/auth_ldap/__manifest__.py
        else
            ynh_replace_string "'auto_install': False" "'auto_install': True" $final_path/$appname/addons/auth_ldap/__openerp__.py
        fi
    fi 

}

function setup_database() {
    export preinstall=1
    ynh_configure server.conf $conf_file
    chown $app:$app $conf_file
    # Load translation
    #param=" --without-demo True --addons-path $final_path/$appname/addons --db_user $app --db_password $db_pass --db_host 127.0.0.1 --db_port 5432 --db-filter '^$app\$' -d $app "
    param=" -c $conf_file -d $app "
    ynh_exec_as $app $bin_file -c $conf_file --stop-after-init -i base -d $app
    ynh_exec_as $app $bin_file -c $conf_file --stop-after-init -i auth_ldap -d $app
    ynh_exec_as $app $bin_file -c $conf_file --stop-after-init --load-language $lang -d $app
    # Configure language, timezone and ldap
    ynh_exec_as $app $bin_file shell -c $conf_file -d $app <<< \
"
self.env['res.users'].search([['login', '=', 'admin']])[0].write({'password': '$admin_password'})
self.env.cr.commit()
"
    ynh_exec_as $app $bin_file shell -c $conf_file -d $app <<< \
"
self.write({'tz':'$tz','lang':'$lang'})
self.env.cr.commit()
"
    ynh_exec_as $app $bin_file shell -c $conf_file -d $app <<< \
"
template=env['res.users'].create({
  'login':'template',
  'password':'',
  'name':'template',
  'email':'template',
  'sel_groups_9_10':9,
  'tz':'$tz',
  'lang':'$lang'
})
self.env.cr.commit()
self.company_id.ldaps.create({
  'ldap_server':'localhost',
  'ldap_server_port':389,
  'ldap_base':'ou=users, dc=yunohost,dc=org',
  'ldap_filter':'uid=%s',
  'user':template.id,
  'company':self.company_id.id
})
self.env.cr.commit()
"
    export preinstall=0
    ynh_configure server.conf $conf_file
    chown $app:$app $conf_file
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
    content=""
    content2=""
    content3=""
    if [[ $preinstall == '1' ]]
    then
    	content="dbfilter = $db_name"
	else
		content="db_name = $db_name"
		if [[ $app_version > 9 ]]
		then
			content2="dbfilter = False"
		fi
		content3="list_db = False"
	fi

    mkdir -p "$(dirname $DEST)"
    if [ -f '../manifest.json' ] ; then
        ynh_add_config "${YNH_CWD}/../conf/$TEMPLATE" "$DEST"
    else
        ynh_add_config "${YNH_CWD}/../settings/conf/$TEMPLATE" "$DEST"
    fi
}

# Argument $1 is the size of the swap in MiB
ynh_add_swap () {
	# Declare an array to define the options of this helper.
	declare -Ar args_array=( [s]=size= )
	local size
	# Manage arguments with getopts
	ynh_handle_getopts_args "$@"

	local swap_max_size=$(( $size * 1024 ))

	local free_space=$(df --output=avail / | sed 1d)
	# Because we don't want to fill the disk with a swap file, divide by 2 the available space.
	local usable_space=$(( $free_space / 2 ))

	# Compare the available space with the size of the swap.
	# And set a acceptable size from the request
	if [ $usable_space -ge $swap_max_size ]
	then
		local swap_size=$swap_max_size
	elif [ $usable_space -ge $(( $swap_max_size / 2 )) ]
	then
		local swap_size=$(( $swap_max_size / 2 ))
	elif [ $usable_space -ge $(( $swap_max_size / 3 )) ]
	then
		local swap_size=$(( $swap_max_size / 3 ))
	elif [ $usable_space -ge $(( $swap_max_size / 4 )) ]
	then
		local swap_size=$(( $swap_max_size / 4 ))
	else
		echo "Not enough space left for a swap file" >&2
		local swap_size=0
	fi

	# If there's enough space for a swap, and no existing swap here
	if [ $swap_size -ne 0 ] && [ ! -e /swap ]
	then
		# Preallocate space for the swap file
		fallocate -l ${swap_size}K /swap
		chmod 0600 /swap
		# Create the swap
		mkswap /swap
		# And activate it
		swapon /swap
		# Then add an entry in fstab to load this swap at each boot.
		echo -e "/swap swap swap defaults 0 0 #Swap added by $app" >> /etc/fstab
	fi
}

ynh_del_swap () {
	# If there a swap at this place
	if [ -e /swap ]
	then
		# Clean the fstab
		sed -i "/#Swap added by $app/d" /etc/fstab
		# Desactive the swap file
		swapoff /swap
		# And remove it
		rm /swap
	fi
}

#=================================================
# EXPERIMENTAL HELPERS
#=================================================

#=================================================
# FUTURE OFFICIAL HELPERS
#=================================================
