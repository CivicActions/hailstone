# Using Packer to build a hardened AMI

The included packer files serve as a quick-start to creating a hardened AMI in AWS.  
Currently included are two variants that can be used:   
- _**packer-rhel7-ami.json**_: Creates a RHEL 7.0 instance, installs and runs openscap to harden the image, and creates an AMI. Scan results are pushed to an S3 Bucket.
- _**packer-centos-ami.json**_: Creates a CentOS 7 instance, installs and runs openscap to harden the image, and creates an AMI. Scan results are pushed to an S3 Bucket.

## Prerequisites:

### **AWS API and SSH Access**
You will need to have a keypair created for accessing AWS instances. If you do not already have a keypair, you can create one by following the steps described here: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html

AWS API access must be configured. This includes the appropriate .aws/config and .aws/credentials files to provide valid entries.  
Note: the profile name can be changed as needed, and multiple profiles can be defined allowing deployment to different accounts.   

### **Packer** 
Packer must be installed: https://www.packer.io/intro/getting-started/install.html

## Usage:

Set your AWS profile environment variables to define the profile configuration and credentials that will be used: 

### Environment variables for packer template: packer-rhel7-ami.json
```
export REGION=us-east-1
export IAM_INSTANCE_PROFILE=hailstone-s3-upload
export BUCKET_NAME=hailstone-ami-scan-results
export INSTANCE_TYPE=t2.medium
export SSH_USERNAME=ec2-user
export AWS_ACCESS_KEY_ID='Your AWS access key ID'
export AWS_SECRET_ACCESS_KEY='Your AWS secret access key'
```
You can also optionally export a value for AMI_GROUPS to define what groups have permission to launch the AMI. Be default no groups have permissions, whereas setting to 'all' makes the AMI publicly accessible. 

Check to verify that your packer file is properly formatted:  
```
packer validate -var-file=variables.json packer-rhel7-ami.json
```
You can also inspect your packer file to get an overview of the various components:  
```
packer inspect -var-file=variables.json packer-rhel7-ami.json
``` 

### Build a hardened RHEL/CentOS ami and publish the scan results to s3 bucket
```
packer build -var-file=variables.json packer-rhel7-ami.json
```   
or   
```
packer build -var-file=variables.json packer-centos-ami.json
```

After the successful execution of above command, you should see the new AMI created under the AMI section of the EC2 service on AWS.  
You should also see the scan reports under the S3 service of AWS within the bucket defined in your environment variables above (in this example `hailstone-ami-scan-results`).


===========================================

### To create a new hardened AMI

Whenever a Pull Request is created with reference to master branch, All checks should pass before one can review the code.

After tests are successful, we should see Jenkins build running in our CA Jenkins (Hailstone folder) which will do all of the above steps ( Create an EC2 instance, Connect via SSH, Run security scans (OpenSCAP - OVAL and STIG), Push the reports to S3, Stop the Instance, Create an AMI, Terminate an EC2 instance )


### NOTE -

When you add some documentation to README file and ssg-rhel7-ds-justifications.yaml, Jenkins will run a build and create an AMI in AWS.

### To Do -
A shell script can be created to launch packer build to ease the process. The script can also check  before build if any required variable is missing and guide use for the same.