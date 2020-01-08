echo "install awscli if not install"
aws || pip install awscli
ami_id=` cat manifest.json | grep artifact_id | awk -F":" '{print $3}' | tr -d '",'`
kernel_version=`cat kernel-info`
aws ec2 create-tags --resources $ami_id --tags Key=kernel_version,Value=$kernel_version --region $REGION




