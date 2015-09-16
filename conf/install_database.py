#!/usr/bin/python
import oerplib
oerp = oerplib.OERP(server='localhost', protocol='xmlrpc', port=8069)
oerp.db.create_database('ADMIN_PASSWORD', 'DOMAIN_DATABASE', False, 'DATABASE_LANG', 'DATABASE_PASSWORD')