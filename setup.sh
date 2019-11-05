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

echo "installing openscap utilities"
yum install -y openscap-utils scap-security-guide 

cd ~
OVAL_REPORT_NAME=${OS}-oval-report.html
REPORT_NAME=${OS}-${SCAP_TARGET}-report.html

# Remediation steps
firewall-cmd || yum install firewalld -y
systemctl start firewalld
firewall-cmd --set-default-zone public
firewall-cmd --zone=public --permanent --add-service=ssh
systemctl enable firewalld

# Installing required packages
yum install -y htop fail2ban aide

# scanning 
echo "Scaning with  SSG-OVAL definition"
oscap oval eval --results scan-oval-results.xml --report ${OVAL_REPORT_NAME} /usr/share/xml/scap/ssg/content/ssg-${OS}-ds.xml

echo "Scaning with Stig definition"
oscap xccdf eval --remediate --fetch-remote-resources --results-arf stig-arf.xml --report ${REPORT_NAME} --profile "xccdf_org.ssgproject.content_profile_${SCAP_TARGET}" "/usr/share/xml/scap/ssg/content/ssg-${OS}-ds.xml" || true

DIR_NAME=${OS}-$(date +"%Y%m%d-%H%M%S")

reports=$(ls *.{html,xml})
for report in $reports;do
    echo "uploading generated report to s3:  $report"
    su - root -c "aws s3 cp ./${report} s3://${bucket}/${DIR_NAME}/" 
done

# Disabling FIPS
yum remove -y dracut-fips\*
dracut --force
grubby --update-kernel=ALL --remove-args=fips=1
sed -i 's/ fips=1//' /etc/default/grub

yum remove -y epel-release wget awscli
yum clean all
