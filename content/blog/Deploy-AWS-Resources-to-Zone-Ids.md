---
title: "Deploy AWS Resources to Zone Ids"
date: 2019-06-05T10:30:55-05:00
description: "Deploy AWS Resources to Zone Ids."
bgImage: "images/backgrounds/blog-banner.jpg"
bgImageAlt: "images/backgrounds/blog-banner.jpg"
image: "images/blog/Deploy-AWS-Resources-to-Zone-Ids/Deploy-AWS-Resources-to-Zone-Ids.PNG"
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
---

>we independently map Availability Zones to names for each AWS account. For example, the Availability Zone us-east-1a for your AWS account might not be the same location as us-east-1a for another AWS account<br><br> **[AWS Docs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html)**

### Understanding AWS Availability Zones Ids and Zone Names. 

I recently learned that each AWS account independently maps Physical Zone IDs to Zone names. Meaning us-east-1a in 1 account is not necessarily in the same physical zone Id as us-east-1a in another account. This can become challenging when a service like AWS Workspaces is only supported in specific physical zone Ids. 

For example, in the us-east-1 region, workspaces is only supported in.  

````
use1-az2, use1-az4, use1-az6
````    

but not:  

````
use1-az1, use1-az3, use1-az5
````    

Here is a list of all supported Physical Zone Ids for the Workspaces service in each region.  

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

When creating subnets in CloudFormation, the AvailabilityZone Name must be used.  For example us-east-1a is ok, but you cannot use the Zone Id use1-az2.
````
Type: AWS::EC2::Subnet
Properties: 
  AvailabilityZone: us-east-1a
  CidrBlock: 10.0.0.0/24
  VpcId: String
  ````
The following command can be used to determine which zone names map to the workspace supported physical zone Ids.

````
aws ec2 describe-availability-zones --region us-east-1 | jq .[] |grep Zone
````    

````
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

This mapping shows that us-east-1b, us-east-1c, us-east-1d are the valid Zone Names when creating subnets for the workspaces service in this account. However, this mapping is random for each AWS Account. To make this more automation friendly, I created a CloudFormation Custom Resource that puts the AWS account specific Zone Id to Zone Name mappings in the SSM parameter Store. This allows one to take advantage of CloudFormations [SSM Parameter Types](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html#aws-ssm-parameter-types) to resolve to the proper Zone Name. This custom resource places all Zone mappings in the /azinfo path.


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
Resources:
    VPC:
      Type: AWS::EC2::VPC
      Properties:
          CidrBlock: 10.0.0.0/16
    Subnet1:
      Type: AWS::EC2::Subnet
      Properties: 
        AvailabilityZone: !Ref AvailabilityZone1
        CidrBlock: 10.0.1.0/24
        VpcId: !Ref VPC
    Subnet2:
      Type: AWS::EC2::Subnet
      Properties: 
        AvailabilityZone: !Ref AvailabilityZone2
        CidrBlock: 10.0.2.0/24
        VpcId: !Ref VPC
````

# HOW IT WORKS  

### Deploy the Custom Resource  

[![Launch Stack](https://cdn.rawgit.com/buildkite/cloudformation-launch-stack-button-svg/master/launch-stack.svg)](https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=ec2zoneids&templateURL=https://bryanlabs-public.s3.amazonaws.com/bryanlabs.net_files/blog/Deploy-AWS-Resources-to-Zone-Ids/ec2ZoneIds.yml)

Feel free to use bryanlabs defaults for CodeBucket Key and object versions.  
Or grab the [Source](https://github.com/bryanlabs/cloudformation-custom-resources/tree/master/python/ec2ZoneIds) to use your own hosted version of the code.  


### Reference Zone Ids  

After the custom resource has been deployed, zone Ids can be referenced in templates as seen below.  


````
AWSTemplateFormatVersion: 2010-09-09
Description: Subnet Demo.
Parameters:
    AvailabilityZone1:
        Description: The Physical Availability Zone ID
        Type : 'AWS::SSM::Parameter::Value<AWS::EC2::AvailabilityZone::Name>'
        Default: /azinfo/use1-az2
````
![Reference Zone Ids](../../images/blog/Deploy-AWS-Resources-to-Zone-Ids/Reference-Zone-Ids.PNG)


### Zone Name to Zone Id Mappings  

Each Zone Id has a direct mapping to the independently mapped Zone Name. These mappings can be seen in the SSM Parameter Store.  

![Zone Name to Zone Id Mappings](../../images/blog/Deploy-AWS-Resources-to-Zone-Ids/Zone-Name-to-Zone-Id-Mappings.PNG)


### Resolved Values  

During deployment, the Zone Id resolves to the independently map Availability Zone Name for each AWS Account the stack is deployed to. This allows you to truly ensure all your resources across accounts are in the same physical locations.  

![Resolved Values](../../images/blog/Deploy-AWS-Resources-to-Zone-Ids/Resolved-Values.PNG)

### Summary  

Now you can ensure resources are deployed to specific physical Zone Ids. If you know of any other service specific zone restrictions, please comment below and I'll keep a list going. Thanks for reading! 