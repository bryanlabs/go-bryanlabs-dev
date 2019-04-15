---
title: "AMI Factory"
date: 2019-02-07T10:47:55+06:00
description: "This AMI Factory solution will build AMIs based off a payload."
bgImage: "images/slider/code.webp"
bgImageAlt: "images/slider/code.webp"
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

An AMI Factory is a must have in any environment. It's important to know that all instances are using a known image. AMIs should be shared with all accounts in your environment, and IAM should be use to lock down all images except those created by the AMI factory.


>It's a two-syllable word that is pronounced ä-mē like mommy or salami<br><br> by **Chuck Meyer**


### Components

The following components are involved.

1. JSON payload defining how to build an AMI.
2. SSM Automation Documents
3. Lambda Functions

### Payload

The payload defines all the key parts to an AMI .


1. Source Ami - The trusted image to start from.
2. Bootstrap URL - the URL to a script which will configure your image.
3. AWS Accounts - A list of accounts to share the AMI with
4. Automation Document - Orchestrates everything, Creates the image and shares it with customers.

### Automation Documents

The automation document is based off Amazons native UpdateAmi document. A few steps were added to handle rotating expired AMIs, and sharing AMIs with accounts.


### Lambda Function

After an Image is created, Lambda is invoked to share the new Image with defined accounts, and retire any historic AMIs.