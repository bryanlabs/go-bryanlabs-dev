#!/bin/bash
# md2pdf -o resume.pdf -i resume.md
aws s3 sync . s3://bryanlabs-public/resume/ --exclude "*.log" --acl public-read