Odoo
----

Odoo is a suite of web based open source business apps.

The main Odoo Apps include an <a href="https://www.odoo.com/page/crm">Open Source CRM</a>, <a href="https://www.odoo.com/page/website-builder">Website Builder</a>, <a href="https://www.odoo.com/page/e-commerce">eCommerce</a>, <a href="https://www.odoo.com/page/project-management">Project Management</a>, <a href="https://www.odoo.com/page/accounting">Billing &amp; Accounting</a>, <a href="https://www.odoo.com/page/point-of-sale">Point of Sale</a>, <a href="https://www.odoo.com/page/employees">Human Resources</a>, Marketing, Manufacturing, Purchase Management, ...  

Odoo Apps can be used as stand-alone applications, but they also integrate seamlessly so you get
a full-featured <a href="https://www.odoo.com">Open Source ERP</a> when you install several Apps.

Odoo for YunoHost
----------------------------
Warning: This YunoHost app is still in development. Use it at your own risk! I am **not** responsible for any data loss that jeopardizes your organization


**WARNING**: Odoo is a complex app. **DO NOT USE IT** to run your business unless you know what you are doing!!! If you don't, use <a href="https://www.odoo.com/fr_FR/pricing-online#num_users=1&custom_apps=0">the hosted Odoo</a> that will give you peace and customer support!


**Important:** This app MUST be installed on a domain's root!
https://odoo.example.com/ will work
https://example.com/odoo/ will NOT work

What does not work
------------------
- Automatic database creation (experimental)
- Backup and restore via Odoo (works with a trick shared on the Github)
- Backup and restore via YunoHost
- Automatic LDAP configuration

Still to do
-----------
- Automatic LDAP setup + emails
- Backup/restore via Odoo fix
- Backup/restore via YunoHost
- SMTP settings


Configuration
-------------
**Setup LDAP**
- Create a user named "template" with email "template". This user will give its permissions by default to YunoHost users so you can also give it appropriate permissions.
- In "Edit Company Data" (on the logo), go to "Configuration" and add a LDAP setting
- LDAP Address: localhost
- LDAP Port: 389
- LDAP Base: ou=users, dc=yunohost,dc=org
- LDAP filter: uid=%s
- Template user: template
- Save

**Backup via Odoo**
- In YunoHost, open the port 8069
- Access Odoo via your server's IP or URL via *:8069* at the end
- Go to manage databases and backup

**Restore via Odoo**
- In YunoHost, open the port 8069 (if you haven't opened it already)
- Access Odoo via your server's IP or URL via *:8069* at the end
- Go to manage databases and delete the old database
- Restore
- **Important!** The database must be named "*subdomain-domain-tld*" (for example *erp-test-com* if you access the database via *erp.test.com*
