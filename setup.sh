#!/bin/sh
cd /usr/local/bin
PATH=${PATH}:/usr/local/bin

yum install -y epel-release wget
export SCAP_TARGET='stig-rhel7-disa'
export TAILORING_SUFFIX='_basefile'

echo "installing openscap utilities"
yum install -y openscap-utils scap-security-guide 

echo "install python if not exist"
cd ~
rpm -aq python && true || yum install python
python -m pip && true || wget https://bootstrap.pypa.io/get-pip.py; python get-pip.py --user
python -m pip install awscli --user
export PATH=~/.local/bin/:$PATH

[ -f "/etc/centos-release" ] && OS=centos7 || OS=rhel7


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
    aws s3 cp ./${report} s3://${bucket}/${DIR_NAME}/
done

yum remove -y epel-release wget awscli
yum clean all

