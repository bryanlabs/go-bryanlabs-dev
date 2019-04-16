---
title: "AMI Factory"
date: 2019-02-07T10:47:55+06:00
description: "This AMI Factory solution will build AMIs based off a payload."
bgImage: "images/backgrounds/blog-banner.jpg"
bgImageAlt: "images/backgrounds/blog-banner.jpg"
image: "images/blog/post-1.jpg"
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

An AMI Factory is a must have in any environment. It's important to know that all instances are using a known image. AMIs can be shared with accounts in your environment or others. One common way to ensure users are only spinning up approved AMIs is to use IAM to Deny access to non approved Images.

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


>It's a two-syllable word that is pronounced ä-mē like mommy or salami<br><br> by **Chuck Meyer**


# HOW IT WORKS
Create JSON payloads to define one or more AMI(s). 


````
{
	"json": {
		"amis": [{
			"name": "Amazon2",
			"amiid": "ami-b3bcd4d2",
			"document": "DefaultLinuxAmiDocument",
			"bootstrap": "https://raw.githubusercontent.com/bryanlabs/amifactory/master/bootstraps/Amazon2.sh",
			"accounts": ["123456789012"]
		}, {
			"name": "Windows2016",
			"amiid": "ami-23ff9542",
			"document": "DefaultWindowsAmiDocument",
			"bootstrap": "https://raw.githubusercontent.com/bryanlabs/amifactory/master/bootstraps/Windows.ps1",
			"accounts": ["123456789012"]
		}]
	}
}
````

## Payload

The payload defines all the key parts to an AMI .


1. Source Ami - The trusted image to start from.
2. Bootstrap URL - the URL to a script which will configure your image.
3. AWS Accounts - A list of accounts to share the AMI with
4. Automation Document - Orchestrates everything, Creates the image and shares it with customers.

## Invocation
The payload can be invoked multiple ways. In this article we will use Cloudwatch Events to build some AMIs daily, and quarterly.

Cloudwatch Event Details here.

Once the event is triggered, it will pass the payload to the LambdaFunction.

The Lambda Function start an SSM Automation using values from the Payload. It will do the following steps

* Launch the sourceAmiId
* Install the latest version of SSM
* Verify SSM installed Ok
* Install Amazon Cloudwatch
* Bake in an AuthorizedKey
* Update the OS Patches
* Install any code from the bootstrap.
* Stop the Instance
* Create an Image
* Invoke ShareAMI

## Try it out

[![Launch Stack](https://cdn.rawgit.com/buildkite/cloudformation-launch-stack-button-svg/master/launch-stack.svg)](https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=AmiFactory&templateURL=https://s3.amazonaws.com/bryanlabs/blog/AmiFactory/AmiFactory.template)

Or download the
[Template Source](https://s3.amazonaws.com/bryanlabs/blog/AmiFactory/AmiFactory.template)  