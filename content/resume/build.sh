#!/bin/bash
if ! command -v /usr/local/go/bin/go ; then
    wget https://github.com/jgm/pandoc/releases/download/2.7.2/pandoc-2.7.2-1-amd64.deb
    sudo dpkg -i pandoc-2.7.2-1-amd64.deb 
fi
make
AWS_PROFILE=BRYANLABS aws s3 sync output/ s3://bryanlabs-public/resume/ --exclude "*.log" --acl public-read