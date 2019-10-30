#!/bin/sh

#xccdf_org.ssgproject.content_rule_set_firewalld_default_zone
firewall-cmd || yum install firewalld -y
systemctl start firewalld
firewall-cmd --set-default-zone public
firewall-cmd --zone=public --permanent --add-service=ssh

# xccdf_org.ssgproject.content_rule_service_firewalld_enabled
systemctl enable firewalld
