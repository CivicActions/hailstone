#!/bin/sh
export SCAP_TARGET='stig-rhel7-disa'
export TAILORING_SUFFIX='_basefile'

if [ -f "/etc/centos-release" ]
then
    OS=centos7
    yum install -y epel-release wget
    yum install -y python-pip
    pip install --user awscli==1.16.5

else
    OS=rhel7
    yum-config-manager --enable 'Red Hat Enterprise Linux Server 7 RHSCL (RPMs)'
    easy_install pip
    pip install --user awscli==1.16.5
    export PATH=~/.local/bin:$PATH
    
fi
echo "Update System"
yum-complete-transaction --cleanup-only
yum update -y

echo "Installing required packages"
yum install -y openscap-utils scap-security-guide htop fail2ban aide firewalld gdisk wget

cd ~
OVAL_REPORT_NAME=${OS}-oval-report.html
REPORT_NAME=${OS}-${SCAP_TARGET}-report.html

# Remediation steps
systemctl restart dbus # Per RHEL Bugzilla (https://bugzilla.redhat.com/show_bug.cgi?id=1575845) 
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --set-default-zone drop 
firewall-cmd --zone=drop --permanent --add-service=ssh

# Scanning 
echo "Scaning with  SSG-OVAL definition"

# Pull latest OVAL definitions
wget -q https://www.redhat.com/security/data/oval/Red_Hat_Enterprise_Linux_7.xml -O /tmp/Red_Hat_Enterprise_Linux_7.xml

oscap oval eval --results scan-oval-results.xml --report ${OVAL_REPORT_NAME} /tmp/Red_Hat_Enterprise_Linux_7.xml

echo "Scaning with Stig definition"
oscap xccdf eval --remediate --fetch-remote-resources --results-arf stig-arf.xml --report ${REPORT_NAME} --profile "xccdf_org.ssgproject.content_profile_${SCAP_TARGET}" "/usr/share/xml/scap/ssg/content/ssg-${OS}-ds.xml" || true

DIR_NAME=${OS}-$(date +"%Y%m%d-%H%M%S")

reports=$(ls *.{html,xml})
for report in $reports;do
    echo "Uploading generated report to s3:  $report"
    su - root -c "~/.local/bin/aws s3 cp ./${report} s3://${bucket}/${DIR_NAME}/" 
done

# Disabling FIPS
yum remove -y dracut-fips\*
dracut --force
grubby --update-kernel=ALL --remove-args=fips=1
sed -i 's/ fips=1//' /etc/default/grub

yum remove -y epel-release wget awscli
yum clean all
