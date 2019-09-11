# Sample Packer json file to create a RHEL 7.7 AMI

This example packer file serves as a quick-start to creating a RHEL 7.7 AMI in AWS.   
As with any suitable first building block, a *Hello World* (with a twist) has been included.

## Prerequisites:

### **AWS API and SSH Access**
You will need to have a keypair created for accessing AWS instances. If you do not already have a keypair, you can create one by following the steps described here: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html

AWS API access must be configured. This includes the appropriate .aws/config and .aws/credentials files to provide valid entries.  
Note: the profile name can be changed as needed, and multiple profiles can be defined allowing deployment to different accounts.   

Examples:

`cat ~/.aws/config`
```
[profile cloud]
region=us-east-1
output=json
```

`cat ~/.aws/credentials`
```
[cloud]
aws_access_key_id = ACCESS_KEY_ID_HERE
aws_secret_access_key = SECRET_ACCESS_KEY_HERE
```

### **Packer** 
Packer must be installed: https://www.packer.io/intro/getting-started/install.html

## Usage:
Set your AWS profile environment variables to define the profile configuration and credentials that will be used: 
```
export AWS_PROFILE=cloud
export AWS_KEY_NAME=name_of_aws_key
export AWS_PROFILE=/path/to/private_key.pem
```
Check to verify that your packer file is properly formatted:
```
packer validate packer-ami.json
```
You can also inspect your packer file to get an overview of the various components:
```
packer inspect packer-ami.json
``` 
Finally, build your new ami: 
```
packer build packer-ami.json
```

Packer will perform these steps: 
- create an instance from the specified RHEL 7.7 AMI
- connect via ssh to the instance
- run the `hello.sh` script
- stop the instance
- create AMI
- terminate the instance

The output will look like this: 
```
packer build packer-ami.json 
amazon-ebs output will be in this color.

==> amazon-ebs: Prevalidating AMI Name: rhel7-hardened-1568210354
    amazon-ebs: Found Image ID: ami-0916c408cb02e310b
==> amazon-ebs: Using existing SSH private key
==> amazon-ebs: Creating temporary security group for this instance: packer_<Sec Group ID>
==> amazon-ebs: Authorizing access to port 22 from [0.0.0.0/0] in the temporary security groups...
==> amazon-ebs: Launching a source AWS instance...
==> amazon-ebs: Adding tags to source instance
    amazon-ebs: Adding tag: "Name": "Packer Builder"
    amazon-ebs: Instance ID: <Instance ID>
==> amazon-ebs: Waiting for instance <Instance ID> to become ready...
==> amazon-ebs: Using ssh communicator to connect: <IP Address of instance>
==> amazon-ebs: Waiting for SSH to become available...
==> amazon-ebs: Connected to SSH!
==> amazon-ebs: Provisioning with shell script: hello.sh
    amazon-ebs: Hello Kind World!
==> amazon-ebs: Stopping the source instance...
    amazon-ebs: Stopping instance
==> amazon-ebs: Waiting for the instance to stop...
==> amazon-ebs: Creating AMI rhel7-hardened-1568210354 from instance <Instance ID>
    amazon-ebs: AMI: <Image ID>
==> amazon-ebs: Waiting for AMI to become ready...
==> amazon-ebs: Terminating the source AWS instance...
==> amazon-ebs: Cleaning up any extra volumes...
==> amazon-ebs: No volumes to clean up, skipping
==> amazon-ebs: Deleting temporary security group...
Build 'amazon-ebs' finished.

==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs: AMIs were created:
us-east-1: <Image ID>

```

You now have an AMI that can be used to launch instances.  

