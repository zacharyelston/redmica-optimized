#!/usr/bin/env ruby
# Usage: rails runner scripts/configure_ldap.rb
# Configures Redmica LDAP authentication source for canonical Redstone stack

require_relative '../config/environment'

# Settings for canonical LDAP
ldap_name = 'Redstone LDAP'
ldap_host = ENV['LDAP_HOST'] || 'redstone-ldap'
ldap_port = (ENV['LDAP_PORT'] || 1389).to_i
ldap_base_dn = ENV['LDAP_BASE_DN'] || 'ou=users,dc=redstone,dc=local'
ldap_account = ENV['LDAP_BIND_DN'] || 'cn=admin,dc=redstone,dc=local'
ldap_account_password = ENV['LDAP_BIND_PASSWORD'] || 'admin'
ldap_attr_login = ENV['LDAP_ATTR_LOGIN'] || 'uid'
ldap_attr_firstname = ENV['LDAP_ATTR_FIRSTNAME'] || 'givenName'
ldap_attr_lastname = ENV['LDAP_ATTR_LASTNAME'] || 'sn'
ldap_attr_mail = ENV['LDAP_ATTR_MAIL'] || 'mail'
ldap_onthefly = true
ldap_tls = false

existing = AuthSourceLdap.find_by(name: ldap_name)
if existing
  puts "[INFO] Updating existing LDAP source: #{ldap_name}"
  ldap = existing
else
  puts "[INFO] Creating new LDAP source: #{ldap_name}"
  ldap = AuthSourceLdap.new
end

ldap.name = ldap_name
ldap.host = ldap_host
ldap.port = ldap_port
ldap.base_dn = ldap_base_dn
ldap.account = ldap_account
ldap.account_password = ldap_account_password
ldap.attr_login = ldap_attr_login
ldap.attr_firstname = ldap_attr_firstname
ldap.attr_lastname = ldap_attr_lastname
ldap.attr_mail = ldap_attr_mail
ldap.onthefly_register = ldap_onthefly
ldap.tls = ldap_tls

if ldap.save
  puts "[SUCCESS] LDAP source configured: #{ldap.inspect}"
else
  puts "[ERROR] Failed to configure LDAP: #{ldap.errors.full_messages.join(', ')}"
  exit 1
end
