# Using Packer to build a hardened AMI

The included packer files serve as a quick-start to creating a hardened AMI in AWS.  
Currently included are two variants that can be used:   
- _**[packer-rhel8-ami.pkr.hcl](packer-rhel8-ami.pkr.hcl)**_: Creates a RHEL 8.9 instance, installs and runs openscap to harden the image, and creates an AMI. Scan results are pushed to an S3 Bucket.
- _**[packer-rhel8-custom-auditd-ami.pkr.hcl](packer-rhel8-custom-auditd-ami.pkr.hcl)**_: Creates a RHEL 8.9 instance with auditd config tailored for less disruptive behavior, installs and runs openscap to harden the image, and creates an AMI in both us-east-1 and us-west-2. Scan results are pushed to an S3 Bucket. Adds an additional audit rule for staprun. This variation is appropriate for an EC2 instance where audit logs are fed to CloudWatch and aging them out via rotation is acceptable.

**Note: the RHEL 7 and Centos configs in JSON format are deprecated/untested and may not be supported by current versions of Packer.**

## Prerequisites:

### AWS API and SSH Access
You will need to have a keypair created for accessing AWS instances. If you do not already have a keypair, you can create one by following the steps described here: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html

AWS API access must be configured. This includes the appropriate .aws/config and .aws/credentials files to provide valid entries.  
Note: the profile name can be changed as needed, and multiple profiles can be defined allowing deployment to different accounts.   

### Packer
Packer must be installed: https://www.packer.io/intro/getting-started/install.html

## Usage:

Set your AWS profile environment variables to define the profile configuration and credentials that will be used: 

### Environment variables for packer template: packer-rhel7-ami.json
```
export REGION=us-east-1
export IAM_INSTANCE_PROFILE=hailstone-s3-upload
export BUCKET_NAME=hailstone-ami-scan-results
export INSTANCE_TYPE=t3.medium
export SSH_USERNAME=ec2-user
export AWS_ACCESS_KEY_ID='Your AWS access key ID'
export AWS_SECRET_ACCESS_KEY='Your AWS secret access key'
```
Initialize your packer environment to install the Amazon plugin:
```
packer init packer-rhel8-ami.pkr.hcl
```

Check to verify that your packer file is properly formatted:  
```
packer validate packer-rhel8-ami.pkr.hcl
```
You can also inspect your packer file to get an overview of the various components:  
```
packer inspect packer-rhel8-ami.pkr.hcl
``` 

### Build a hardened RHEL ami and publish the scan results to s3 bucket
```
packer build packer-rhel8-ami.pkr.hcl
```
or
```
packer build packer-rhel8-custom-auditd-ami.pkr.hcl
```

After the successful execution of above command, you should see the new AMI created under the AMI section of the EC2 service on AWS.

You should also see the scan reports under the S3 service of AWS within the bucket defined in your environment variables above (in this example `hailstone-ami-scan-results`).

===========================================
