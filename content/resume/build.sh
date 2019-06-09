#!/bin/bash
make
AWS_PROFILE=BRYANLABS aws s3 sync output/ s3://bryanlabs-public/resume/ --exclude "*.log" --acl public-read