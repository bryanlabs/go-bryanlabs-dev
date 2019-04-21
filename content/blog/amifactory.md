---
title: "AMI Factory"
date: 2019-02-07T10:47:55+06:00
description: "This AMI Factory solution will build AMIs based off a payload."
bgImage: "images/backgrounds/blog-banner.jpg"
bgImageAlt: "images/backgrounds/blog-banner.jpg"
image: "images/blog/amifactory/ami_factory.PNG"
author: "Dan Bryan"
postType: "Article"
type: "post"
draft: false
categories: 
  - "Cloudformation"
tags:
  - "AWS"
  - "Systems Manager"
  - "AMI"
  - "EC2"
---

>It's a two-syllable word that is pronounced ä-mē like mommy or salami<br><br> **Chuck Meyer**

An AMI Factory is a must have in any environment. It's important to know that all instances are using known images. AMIs can be shared with accounts in your environment or others. One common way to ensure users are only launching approved images is to use an IAM Policy to Deny access to non approved Images. 


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

The following Solution can be used to build shared Images for users in your Organization.


# HOW IT WORKS
Create JSON payloads to define one or more AMI(s). 


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

The payload defines all the key parts to an AMI .


1. imageName - The name of your image. EG 'webserver' _will result in AmiFactory_AMI_webserver_2019-04-21_00.12.51_
2. sourceImage - The trusted image to start from.
3. bootstrapUrl - the URL to a script which will configure your image.
4. accounts - A list of AWS accounts to share the AMI with.
5. Automation Document - Creates and configures the new AMI.  (_Based on [AWS-UpadateLinuxAmi](https://docs.aws.amazon.com/systems-manager/latest/userguide/automation-aws-updatelinuxami.html) and [AWS-UpadateWindowsAmi](https://docs.aws.amazon.com/systems-manager/latest/userguide/automation-aws-updatewindowsami.html)_)
   1. Launches sourceImage
   2. Installs Software and Patches
   3. Runs bootstrap code
   4. Creates the new Image
   5. retires any Old Images, and Shares the latest Image

## Invoke lambda function (buildAmi)
The function can be invoked multiple ways. In this article we will use both Lambda Test events, and Cloudwatch Events to invoke the buildAmi Function.

### Create a Test Event  
![Create Test Event](images/blog/amifactory/configure_test_event.PNG)

### Click Test Event  
![Click Test Event](images/blog/amifactory/test_event.PNG)

### Notice Automation Started  
![Notice Automation Started](images/blog/amifactory/automation_started.PNG)

### View Automation Steps  
![View Automation Steps](images/blog/amifactory/automation_steps.PNG)

### View Execution Details  
![View Execution Details](images/blog/amifactory/execution_details.PNG)

### View Image List  
![View Image List](images/blog/amifactory/image_list.PNG)



## Try it out

[![Launch Stack](https://cdn.rawgit.com/buildkite/cloudformation-launch-stack-button-svg/master/launch-stack.svg)](https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=AmiFactory&templateURL=https://s3.amazonaws.com/bryanlabs-public/bryanlabs.net_files/blog/amifactory/AmiFactory.yml)

Feel free to use bryanlabs defaults for lambda-code bucket/prefix and object versions.  
Or grab the [build scripts](https://github.com/bryanlabs/aws-amifactory) and [Template Source](https://s3.amazonaws.com/bryanlabs/blog/AmiFactory/AmiFactory.template) to use your own hosted version of the code.  
