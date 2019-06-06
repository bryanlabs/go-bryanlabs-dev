---
title: "Availability Zone Names and Ids"
date: 2019-06-05T10:30:55-05:00
description: "Using Availability Zones Ids instead of Zone Names."
bgImage: "images/backgrounds/blog-banner.jpg"
bgImageAlt: "images/backgrounds/blog-banner.jpg"
image: "images/blog/ec2zoneids/ec2zoneids.png"
author: "Dan Bryan"
postType: "Article"
type: "post"
draft: false
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

I ran into an interestering problem while creating some code to deploy an AWS Environment for hosting workspaces. I kept getting errors saying that workspaces was not available for the AZ my subnet was using. At first it was saying that workspaces was only available in us-east-1a, us-east-1c, and us-east-1d. Then when i tested on another account it was saying that it's only available in 'us-east-1c, us-east-1d, and us-east-1f'. Each account was different. After chatting with AWS Support, I learned that each AWS account independently maps Zones to names. Meaning us-east-1a in 1 account is not the same physical location as us-east-1a in another account. This becomes problematic when a service isn't supported in all zones. So the first step i needed to do, was to find out which zone ids workspaces will work in.  The following list was provided by AWS support.

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

### Creating Subnets with Cloudformation.  

The next step was to create the subnets in Cloudformation.  
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
The AvailabilityZone property must be a Zone Name, not a Zone Id. In order to know which zone names to use I had to first describe the availability zones in the cli. Comparing this output to the workspaces zone mappings, I learned that i had to build my subnets in us-east-1b, us-east-1c, us-east-1d.

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

Being that I have to deploy this on many accounts, i do not want to have to describe availability zones in each one, and pass the param to the correct zone name. So the next step was to create a Custom Resource that puts the Zone ID to Zone Name mappings in the SSM parameter Store, allowing me to use code like this in Cloudformation.


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

![Reference Zone Ids](../../images/blog/ec2zoneids/Reference-Zone-Ids.PNG)

### Reference Zone Ids  

After the custom resource has been deployed, zone Ids can be referenced in templates like this.  


````
AWSTemplateFormatVersion: 2010-09-09
Description: Subnet Demo.
Parameters:
    AvailabilityZone1:
        Description: The Physical Availability Zone ID
        Type : 'AWS::SSM::Parameter::Value<AWS::EC2::AvailabilityZone::Name>'
        Default: /azinfo/use1-az2
````

![Zone Name to Zone Id Mappings](../../images/blog/ec2zoneids/Zone-Name-to-Zone-Id-Mappings.PNG)

### Zone Name to Zone Id Mappings  

Each Zone Id as a direct mapping to Zone Names. These mappings can be seen in the SSM Parameter Store.  

![Resolved Values](../../images/blog/ec2zoneids/Resolved-Values.PNG)

### Resolved Values  

The Zone Id resolves to the independently map Availability Zone Name for each AWS Account the stack is deployed to. This allows you to truely ensure all your resources across accounts are in the same physical locations.  