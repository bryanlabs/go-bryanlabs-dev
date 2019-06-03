---
title: "Availability Zone Names and Ids"
date: 2019-02-07T10:47:55+06:00
description: "When to use Availability Zones Ids instead of Zone Names."
bgImage: "images/backgrounds/blog-banner.jpg"
bgImageAlt: "images/backgrounds/blog-banner.jpg"
image: "images/blog/amifactory/ami_factory.PNG"
author: "Dan Bryan"
postType: "Article"
type: "post"
draft: true
comments: true
categories: 
  - "Cloudformation"
tags:
  - "AWS"
  - "Availability Zones"
  - "cloudformation"
  - "custom resources"
  - "EC2"
---

>we independently map Availability Zones to names for each AWS account. For example, the Availability Zone us-east-1a for your AWS account might not be the same location as us-east-1a for another AWS account<br><br> **AWS Docs**

### Understanding AWS Availability Zones Ids and Zone Names. 

I ran into an interesting problem while creating some code to deploy an AWS Environment for hosting WorkSpaces. I kept getting errors saying that WorkSpaces was not available for the AZ my subnet was using. At first it was saying that WorkSpaces was only available in us-east-1a, us-east-1c, and us-east-1d. Then when I tested on another account it was saying that it's only available in 'us-east-1c, us-east-1d, and us-east-1f'. Each account was different. After chatting with AWS Support, I learned that each AWS account independently maps Zones to names. Meaning us-east-1a in 1 account is not the same physical location as us-east-1a in another account. This becomes problematic when a service isn't supported in all zones. So the first step I needed to do, was to find out which zone ids WorkSpaces will work in.  The following list was provided by AWS support.

#### Workspaces Zone Mappings

````
ap-northeast-1: apne1-az4, apne1-az1
ap-northeast-2: apne2-az1, apne2-az3
ap-southeast-1: apse1-az2, apse1-az1
ap-southeast-2: apse2-az1, apse2-az3
ca-central-1: cac1-az1, cac1-az2
eu-central-1: euc1-az2, euc1-az3
eu-west-1: euw1-az3, euw1-az1, euw1-az2
eu-west-2: euw2-az2, euw2-az3
sa-east-1: sae1-az1, sae1-az3
us-east-1: use1-az6, use1-az2, use1-az4
us-west-2: usw2-az1, usw2-az2, usw2-az3
````

### Creating Subnets with CloudFormation.  

The next step was to create the subnets in CloudFormation.  
````
Type: AWS::EC2::Subnet
Properties: 
  AssignIpv6AddressOnCreation: Boolean
  AvailabilityZone: String
  CidrBlock: String
  Ipv6CidrBlock: String
  MapPublicIpOnLaunch: Boolean
  Tags: 
    - Tag
  VpcId: String
  ````
The AvailabilityZone property must be a Zone Name, not a Zone Id. In order to know which zone names to use I had to first describe the Availability Zones in the cli. Comparing this output to the WorkSpaces zone mappings, I learned that I had to build my subnets in us-east-1b, us-east-1c, us-east-1d.

````
aws ec2 describe-availability-zones --region us-east-1 | jq .[] |grep Zone
    "ZoneName": "us-east-1a",
    "ZoneId": "use1-az1"
    "ZoneName": "us-east-1b",
    "ZoneId": "use1-az2"
    "ZoneName": "us-east-1c",
    "ZoneId": "use1-az4"
    "ZoneName": "us-east-1d",
    "ZoneId": "use1-az6"
    "ZoneName": "us-east-1e",
    "ZoneId": "use1-az3"
    "ZoneName": "us-east-1f",
    "ZoneId": "use1-az5"
````

Being that I have to deploy this on many accounts, I do not want to have to describe Availability Zones in each one, and pass the param to the correct zone name. So the next step was to create a Custom Resource that puts the Zone ID to Zone Name mappings in the SSM parameter Store, allowing me to use code like this in CloudFormation.


````
AWSTemplateFormatVersion: 2010-09-09
Description: Subnet Demo.
Parameters:
    AvailabilityZone1:
        Description: The Physical Availability Zone ID
        Type : 'AWS::SSM::Parameter::Value<AWS::EC2::AvailabilityZone::Name>'
        Default: /azinfo/use1-az2
    AvailabilityZone2:
        Description: The Physical Availability Zone ID
        Type : 'AWS::SSM::Parameter::Value<AWS::EC2::AvailabilityZone::Name>'
        Default: /azinfo/use1-az4
    VpcId:
        Description: The VpcId
        Type : 'AWS::EC2::VPC::Id'
Resources:
    Subnet1:
      Type: AWS::EC2::Subnet
      Properties: 
        AvailabilityZone: !Ref AvailabilityZone1
        CidrBlock: 10.0.0.0/24
        VpcId: !Ref VpcId
    Subnet2:
      Type: AWS::EC2::Subnet
      Properties: 
        AvailabilityZone: !Ref AvailabilityZone2
        CidrBlock: 10.0.1.0/24
        VpcId: !Ref VpcId
````


## Ready to Try it out?

[![Launch Stack](https://cdn.rawgit.com/buildkite/cloudformation-launch-stack-button-svg/master/launch-stack.svg)](https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=ec2zoneids&templateURL=https://bryanlabs-public.s3.amazonaws.com/bryanlabs.net_files/blog/ec2zoneids/ec2ZoneIds.yml)

Feel free to use bryanlabs defaults for CodeBucket Key and object versions.  
Or grab the [Source](https://github.com/bryanlabs/cloudformation-custom-resources/tree/master/python/ec2ZoneIds) to use your own hosted version of the code.  


# HOW IT WORKS
After you have deployed the stack, you should create JSON payloads to define one or more AMI(s). 


````
{
    "amis": [
        {
            "imageName": "Webserver",
            "sourceImage": "ami-0de53d8956e8dcf80",
            "bootstrapUrl": "https://raw.githubusercontent.com/bryanlabs/aws-amifactory/master/bootstrap/webserver.sh",
            "accounts": [
                "CHANGEME"
            ],
            "automationDocument": "DefaultLinuxAmiDocument"
        }
    ]
}
````

## Payload schema

1. imageName - The name of your image.
2. sourceImage - The trusted image to start from.
3. bootstrapUrl - the URL to a script which will configure your image.
4. accounts - A list of AWS account numbers to share the AMI with.
5. Automation Document - Creates and configures the new AMI.

# Build AMIs
Now that you have a payload defining your AMIs, you can use them to invoke the Lambda function. This Lambda function can be triggered multiple ways. In this article we will use both a Lambda Test event and CloudWatch Schedule Events to invoke the buildAmi Function.

## Create a Lambda Test Event  
From within Lambda, click the buildAmi function click 'select a test event', then click configure test events. Choose an Event name like webserverTest, paste in the json payload example and click create.  

![Create Test Event](../../images/blog/amifactory/configure_test_event.PNG)

### Click Test Event  
Now that the test event is created, we can invoke it from the Lambda console. Make sure to select the WebserverTest event, and click Test.  

![Click Test Event](../../images/blog/amifactory/test_event.PNG)  

### Notice Automation Started  
If all goes well, you should see a green dialog box that says Execution result: succeeded. In the Log output below, you will see which AMIs have started building.  

![Notice Automation Started](../../images/blog/amifactory/automation_started.PNG)

### View Automation Steps  
From the main services page, click Systems Manager, then automation. You should see one in progress. Click the execution ID to watch it build.  

![View Automation Steps](../../images/blog/amifactory/automation_steps.PNG)

### View Execution Details  
You can further inspect each step and see the details such as which software packages were updated.  

![View Execution Details](../../images/blog/amifactory/execution_details.PNG)

### View Image List  
Once the Automation completes, you can verify the Image exists by going to the services page, then EC2, then Images/Amis. You should see your image at the top of the list. If you click it, you can see the permissions of which accounts are allowed to access that Image.   
![View Image List](../../images/blog/amifactory/image_list.PNG)


## Use CloudWatch to Schedule builds of AMIs.

We recommend building images on a schedule with CloudWatch Events. 

### Create Rule  
From the services page, click CloudWatch, Rules, then Create Rule.  Choose Schedule for the Event source, Fixed rate of 7 days, or whatever your preference is. Add a Target to the build ami lambda function. Configure input of constant JSON text and paste in the example payload. Next Configure details.

![Create Rule](../../images/blog/amifactory/create_rule.PNG)

### Configure Rule Details  
Choose a name and description for the rule, then click create. Now your Images will build according to the schedule you defined.

![Configure Rule Details](../../images/blog/amifactory/configure_rule_details.PNG)

## Lock Down the IAM Policies to only allow AMI Factory Images

The last step is an optional one. One common way to ensure users are only launching approved images is to use an IAM Policy to Deny access to non approved Images. The example below is a simple IAM policy that can be attached to an IAM user to prevent them from running instances not created by the Amazon Factory.


````
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyAMIAccess",
            "Effect": "Deny",
            "Action": [
                "ec2:RunScheduledInstances",
                "ec2:RunInstances"
            ],
            "Resource": "arn:aws:ec2:*::image/ami-*",
            "Condition": {
                "StringNotEquals": {
                    "ec2:Owner": [
                        "AMIFactory_account_id_here"
                    ]
                }
            }
        }
    ]
}
````
