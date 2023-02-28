#!/bin/sh
set -e
env

export SCAP_TARGET='stig-rhel8-disa'
export TAILORING_SUFFIX='_basefile'
#export PATH=/root/.local/bin:${PATH}
if [ -f "/etc/centos-release" ]
then
    echo "****  Found OS: Centos   ****"
    OS=centos8
    yum install -y epel-release wget
else
    echo "****  Found OS: RHEL   ****"
    OS=rhel8
fi

echo "***  Enabling FIPS   ***"
fips-mode-setup --enable

echo "****  Installing PIP   ****"
yum install -y curl python3
curl https://bootstrap.pypa.io/pip/3.6/get-pip.py -o get-pip.py
python3 get-pip.py
echo "****  installing requests  ****"
/usr/local/bin/pip3 install --user --no-warn-script-location --upgrade requests
echo "****  installing awscli version 1.24.10  ****"
/usr/local/bin/pip3 install --user --no-warn-script-location awscli==1.24.10

echo "****  Updating OS     ****"
yum -y install yum-utils
yum update -y

echo "****  Installing required packages   ****"
rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum install -y openscap-utils scap-security-guide htop fail2ban aide firewalld gdisk wget net-tools

echo "****  Setting custom audit configs   ***"

# Note that unless used with the associated custom tailoring, scan
# remediations below will change these logging configs
sed -i 's/^max_log_file_action.*/max_log_file_action = ROTATE/' /etc/audit/auditd.conf
sed -i 's/^admin_space_left_action.*/admin_space_left_action = ROTATE/' /etc/audit/auditd.conf
sed -i 's/^disk_full_action.*/disk_full_action = ROTATE/' /etc/audit/auditd.conf
sed -i 's/^disk_error_action.*/disk_error_action = SYSLOG/' /etc/audit/auditd.conf

# Add required OpenSCAP configs from custom hardening
mv /home/ec2-user/custom_privileged.rules /etc/audit/rules.d/
chown root:root /etc/audit/rules.d/custom_privileged.rules
chmod 0640 /etc/audit/rules.d/custom_privileged.rules

echo "****    Running Remediation steps   ****"
# CAT 2 STIG Finding - V-230278
grubby --update-kernel=ALL --args="vsyscall=none"
# CAT 3 STIG Finding - V-230491
grubby --update-kernel=ALL --args="pti=on"

echo "****    Running firewalld remediation   ****"
firewall-cmd || yum install firewalld -y
systemctl restart dbus
systemctl restart firewalld
systemctl enable firewalld

echo "****    Firewalld: setting default zone => drop   ****"
firewall-cmd --set-default-zone=drop
firewall-cmd --zone=drop --permanent --add-service=ssh
firewall-cmd --permanent --add-port=22/tcp
firewall-cmd --reload

# Scanning 
echo "****      Scaning with  SSG-OVAL definition   ****"
# Pull latest OVAL definitions
wget -q https://www.redhat.com/security/data/oval/Red_Hat_Enterprise_Linux_8.xml -O /tmp/Red_Hat_Enterprise_Linux_8.xml
oscap oval eval --results scan-oval-results.xml --report scan-oval-report.html /tmp/Red_Hat_Enterprise_Linux_8.xml

echo "****      Scaning with Stig definition    ****"
oscap xccdf eval --remediate --fetch-remote-resources --results-arf scan-stig-xccdf-arf-result.xml --report scan-stig-xccdf-report.html --profile "xccdf_org.globalnet_profile_stig-rhel8-disa_tailored" /home/ec2-user/ssg-rhel8-ds-custom-auditd-tailoring.xml || echo "Seems the scan finished with non-zero error code:      $?"

[ -z $ami_name ] && DIR_NAME=${OS}-$(date +"%Y%m%d-%H%M%S") || DIR_NAME=$ami_name
reports=$(ls scan*.{html,xml})
for report in $reports;do
    echo "****      uploading generated report to s3:  $report      ****"
    su - root -c "/root/.local/bin/aws s3 cp $(pwd)/${report} s3://${bucket}/${DIR_NAME}/" 
done

yum remove -y epel-release wget
yum clean all