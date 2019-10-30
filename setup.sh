#!/bin/sh
export SCAP_TARGET='stig-rhel7-disa'
export TAILORING_SUFFIX='_basefile'

if [ -f "/etc/centos-release" ]
then
    OS=centos7
    yum install -y epel-release wget
    yum install -y python-pip
    pip install awscli==1.16.5

else
    OS=rhel7
    yum-config-manager --enable 'Red Hat Enterprise Linux Server 7 RHSCL (RPMs)'
    easy_install pip
    pip install awscli==1.16.5
    bash remediate-rhel7.sh

fi

echo "installing openscap utilities"
yum install -y openscap-utils scap-security-guide 

cd ~
OVAL_REPORT_NAME=${OS}-oval-report.html
REPORT_NAME=${OS}-${SCAP_TARGET}-report.html

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

yum remove -y epel-release wget awscli
yum clean all
