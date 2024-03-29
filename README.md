# image-iiif-s3
## This script is now maintained in the following repository
[vt-digital-libraries-platform/iiif_s3_docker](https://github.com/vt-digital-libraries-platform/iiif_s3_docker)

This repository contains Ruby script that can be used to generate IIIF level 0 compatible image presentation manifests and tiles, which can be uploaded to Amazon S3 bucket for static serving.

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
2. A CSV metadata file
```
e.g. Chadeayne_Ms1990_057_Box1.csv
```
3. A folder with image files 
```
e.g. Special collection folder example: Ms1990_057_Chadeayne/Edited/Ms1990_057_Box1/Ms1990_057_B001_F001_001_LHJClips_Ms/Access/
```
4. Run the Ruby script:
    * Print help (note that with -u or --upload_to_s3 boolean argument it will upload to S3, otherwise no argument turns the option off):
    ```
    $ ruby create_iiif_s3.rb -h
    ```
    * Examples:
    ```
    $ ruby create_iiif_s3.rb -m Chadeayne_Ms1990_057_Box1.csv -i Ms1990_057_Chadeayne/Edited/Ms1990_057_Box1/Ms1990_057_B001_F001_001_LHJClips_Ms/Access/ -b https://img.cloud.lib.vt.edu -r iiif_s3_test -u
    ```
    ```
    $ ruby create_iiif_s3.rb -m Chadeayne_Ms1990_057_Box1.csv -i Ms1990_057_Chadeayne/Edited/Ms1990_057_Box1/Ms1990_057_B001_F001_001_LHJClips_Ms/Access/ -b https://img.cloud.lib.vt.edu -r iiif_s3_test
    ```
