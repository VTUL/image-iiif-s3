# image-iiif-s3
This repository contains Ruby script that can be used to generate IIIF level 0 compatible image presentation manifests and tiles, and then to upload them to Amazon S3 bucket for static serving.

# Local Development Installation
The development environment can be set up using [VTUL/iiif_s3-vagrant](https://github.com/VTUL/iiif_s3-vagrant). To deploy on your local machine, first install Vagrant, Ansible, and VirtualBox, then follow the steps below.
```
$ git clone https://github.com/VTUL/iiif_s3-vagrant.git
$ cd iiif_s3-vagrant
$ vagrant up
$ vagrant ssh
$ cd /vagrant
$ git clone https://github.com/VTUL/image-iiif-s3.git
$ cd image-iiif-s3
```
# Usage
1. To upload manifests and tiles to Amazon S3, you need to provide AWS credentials:
```
$ export AWS_ACCESS_KEY_ID=""
$ export AWS_SECRET_ACCESS_KEY=""
$ export AWS_BUCKET_NAME=""
$ export AWS_REGION=""
```
2. Run Ruby script:
```
$ ruby img_iiif_s3.rb
```
