#!/bin/bash

echo "Starting the final script to join AD and install Kerberos libraries"

echo "changing network config"

echo "DNS1=10.40.0.4
DOMAIN=reddog.microsoft.com cloudera.local" | sudo tee -a /etc/sysconfig/network-scripts/ifcfg-eth0

sudo service network restart

longhostname=`hostname`
shorthostname=$(echo $longhostname | awk -F: '{ st = index($0,"."); print substr($0,0,st-1)}')
sudo hostnamectl set-hostname $shorthostname

echo "Installing Kerberos and sssd libraries"
sudo yum -y install sssd sssd-client adcli krb5-workstation krb5-libs krb5-auth-dialog

sudo touch /etc/krb5.conf

echo "[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
default_realm = CLOUDERA.LOCAL
dns_lookup_kdc = false
dns_lookup_realm = false
ticket_lifetime = 86400
renew_lifetime = 604800
forwardable = true
default_tgs_enctypes = rc4-hmac
default_tkt_enctypes = rc4-hmac
permitted_enctypes = rc4-hmac
udp_preference_limit = 1
kdc_timeout = 3000
rdns=false
[realms]
CLOUDERA.LOCAL = {
kdc = 10.40.0.4
admin_server = 10.40.0.4
}" | sudo tee /etc/krb5.conf

hostname=`hostname`

echo -n 'HelloWorld123!' | sudo adcli join CLOUDERA.LOCAL -U da --stdin-password --verbose --show-details --host-fqdn $hostname

sudo touch /etc/sssd/sssd.conf

echo "[sssd]
services = nss, pam, ssh, autofs
config_file_version = 2
domains = CLOUDERA.LOCAL

[domain/CLOUDERA.LOCAL]
id_provider = ad
override_homedir = /home/%u
default_shell = /bin/bash
dyndns_update = true
dyndns_refresh_interval = 43200
dyndns_update_ptr = true
dyndns_ttl = 3600
ad_hostname = $hostname.cloudera.local" | sudo tee /etc/sssd/sssd.conf

sudo chmod 600 /etc/sssd/sssd.conf

sudo authconfig --enablesssd --enablemkhomedir --enablesssdauth --update

sudo service sssd restart

id lufthansa
