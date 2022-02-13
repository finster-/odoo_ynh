# LibreERP pour YunoHost

[![Niveau d'intégration](https://dash.yunohost.org/integration/libreerp.svg)](https://dash.yunohost.org/appci/app/libreerp) ![](https://ci-apps.yunohost.org/ci/badges/libreerp.status.svg) ![](https://ci-apps.yunohost.org/ci/badges/libreerp.maintain.svg)  
[![Installer LibreERP avec YunoHost](https://install-app.yunohost.org/install-with-yunohost.svg)](https://install-app.yunohost.org/?app=libreerp)

*[Read this readme in english.](./README.md)*
*[Lire ce readme en français.](./README_fr.md)*

> *Ce package vous permet d'installer LibreERP rapidement et simplement sur un serveur YunoHost.
Si vous n'avez pas YunoHost, regardez [ici](https://yunohost.org/#/install) pour savoir comment l'installer et en profiter.*

## Vue d'ensemble

LibreERP is a suite of web based open source business apps. LibreERP is a fork of Odoo Community Edition.

The main LibreERP Apps include an Open Source CRM, Website Builder, eCommerce, Project Management, Billing &amp; Accounting, Point of Sale, Human Resources, Marketing, Manufacturing, Purchase Management, ...

LibreERP Apps can be used as stand-alone applications, but they also integrate seamlessly so you get a full-featured Open Source ERP when you install several Apps.


**Version incluse :** 12.0-6

**Démo :** https://www.odoo.com/trial

## Avertissements / informations importantes

**WARNING**: LibreERP is a complex app. **DO NOT USE THIS PACKAGE** to run your business unless you know what you are doing!!! If you don't, you should consider to ask for help from a professionnal!

**IMPORTANT:** This app MUST be installed on a domain's root!
https://erp.example.com/ will work
https://example.com/erp/ will NOT work

To connect on your LibreERP
-----------
- Go on https://YOURDOMAIN/web
- Use your master password

About licences
-----------
LibreERP 8.0 is under AGPL-3.0
Next version are under LGPL-3.0
LibreERP is forked from Odoo Community Edition. The name is change due to Odoo trademark policy.

## Documentations et ressources

* Site officiel de l'app : https://odoo.com
* Documentation officielle utilisateur : https://www.odoo.com/documentation/15.0/applications.html
* Documentation officielle de l'admin : https://www.odoo.com/documentation/15.0/administration.html
* Dépôt de code officiel de l'app : https://github.com/odoo/odoo
* Documentation YunoHost pour cette app : https://yunohost.org/app_libreerp
* Signaler un bug : https://github.com/YunoHost-Apps/libreerp_ynh/issues

## Informations pour les développeurs

Merci de faire vos pull request sur la [branche testing](https://github.com/YunoHost-Apps/libreerp_ynh/tree/testing).

Pour essayer la branche testing, procédez comme suit.
```
sudo yunohost app install https://github.com/YunoHost-Apps/libreerp_ynh/tree/testing --debug
ou
sudo yunohost app upgrade libreerp -u https://github.com/YunoHost-Apps/libreerp_ynh/tree/testing --debug
```

**Plus d'infos sur le packaging d'applications :** https://yunohost.org/packaging_apps