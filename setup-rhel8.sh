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

echo "****  Installing PIP   ****"
dnf install -y curl python3
curl https://bootstrap.pypa.io/pip/3.6/get-pip.py -o get-pip.py
python3 get-pip.py
echo "****  installing awscli version 1.16.5   ****"
/usr/local/bin/pip3 install --user awscli==1.16.5

echo "****  Updating OS     ****"
dnf clean all
dnf check
#dnf check-update && true
dnf -y install yum-utils
dnf update -y

echo "****  Installing required packages   ****"
rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf install -y openscap-utils scap-security-guide htop fail2ban aide firewalld gdisk wget net-tools

echo "****    Running Remediation steps   ****"


echo "****    Running firewalld remediation   ****"
firewall-cmd || dnf install firewalld -y
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
wget -q https://access.redhat.com/security/data/oval/v2/RHEL8/rhel-8.oval.xml.bz2 -O /tmp/rhel-8.oval.xml.bz2
bunzip2 -f /tmp/rhel-8.oval.xml.bz2
oscap oval eval --results scan-oval-results.xml --report scan-oval-report.html /tmp/rhel-8.oval.xml

echo "****      Scaning with Stig definition    ****"
oscap xccdf eval --remediate -results-arf scan-stig-xccdf-arf-result.xml --report scan-stig-xccdf-report.html --profile "xccdf_org.globalnet_profile_stig-rhel8-disa_tailored" /home/ec2-user/ssg-rhel8-ds-tailoring.xml || echo "Seems the scan finished with non-zero error code:      $?"

[ -z $ami_name ] && DIR_NAME=${OS}-$(date +"%Y%m%d-%H%M%S") || DIR_NAME=$ami_name
reports=$(ls scan*.{html,xml})
for report in $reports;do
    echo "****      uploading generated report to s3:  $report      ****"
    su - root -c "/root/.local/bin/aws s3 cp $(pwd)/${report} s3://${bucket}/${DIR_NAME}/" 
done

# Disabling FIPS
dracut --force
grubby --update-kernel=ALL --remove-args=fips=1
dnf remove -y dracut-fips\*
sed -i 's/ fips=1//' /etc/default/grub

dnf remove -y epel-release wget
dnf clean all
