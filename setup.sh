#!/bin/sh
set -e
env

export SCAP_TARGET='stig-rhel7-disa'
export TAILORING_SUFFIX='_basefile'
#export PATH=/root/.local/bin:${PATH}
if [ -f "/etc/centos-release" ]
then
    echo "****  Found OS: Centos   ****"
    OS=centos7
    yum install -y epel-release wget
    yum install -y python-pip
    pip install --user awscli==1.16.5

else
    echo "****  Found OS: RHEL   ****"
    OS=rhel7
    yum-config-manager --enable 'Red Hat Enterprise Linux Server 7 RHSCL (RPMs)'
    echo "****  Installing PIP   ****"
    easy_install pip
    echo "****  installing awscli version 1.16.5   ****"
    pip install --user awscli==1.16.5

fi

echo "****  Updating OS     ****"
yum-complete-transaction --cleanup-only
yum update -y

echo "****  Installing required packages   ****"
rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y openscap-utils scap-security-guide htop fail2ban aide firewalld gdisk wget

echo "****    Running Remediation steps   ****"

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
wget -q https://www.redhat.com/security/data/oval/Red_Hat_Enterprise_Linux_7.xml -O /tmp/Red_Hat_Enterprise_Linux_7.xml
oscap oval eval --results scan-oval-results.xml --report scan-oval-report.html /tmp/Red_Hat_Enterprise_Linux_7.xml

echo "****      Scaning with Stig definition    ****"
oscap xccdf eval --remediate --fetch-remote-resources --results-arf scan-stig-xccdf-arf-result-untailored.xml --report scan-stig-xccdf-report-untailored.html --profile xccdf_org.ssgproject.content_profile_stig /usr/share/xml/scap/ssg/content/ssg-rhel7-ds.xml || echo "Seems the scan finished with non-zero error code:      $?"

[ -z $ami_name ] && DIR_NAME=${OS}-$(date +"%Y%m%d-%H%M%S") || DIR_NAME=$ami_name
#DIR_NAME=${OS}-$(date +"%Y%m%d-%H%M%S")
reports=$(ls scan*.{html,xml})
for report in $reports;do
    echo "****      uploading generated report to s3:  $report      ****"
    su - root -c "/root/.local/bin/aws s3 cp $(pwd)/${report} s3://${bucket}/${DIR_NAME}/"
done

# Disabling FIPS
yum remove -y dracut-fips\*
dracut --force
grubby --update-kernel=ALL --remove-args=fips=1
sed -i 's/ fips=1//' /etc/default/grub

yum remove -y epel-release wget
yum clean all
