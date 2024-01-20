# README

This repository includes scripts, tooling and documentation to provision an instance of CML on Amazon Web Services (AWS) created for ASEE conference. 

## Installation

Clone the repository and recurse all of the submodules

```
git clone --recursive https://github.com/Dollarhyde/terraform-cloud-cml
```

### Terraform installation

Terraform can be downloaded for free from [here](https://developer.hashicorp.com/terraform/downloads). This site has also instructions how to install it on various supported platforms.

### AWS CLI installation

The AWS CLI can be downloaded from [here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). This was tested using the following AWS CLI version:

## AWS Configuration

This section outlines how to modify necessary variables and provisioning scripts for CML deployment on AWS. 

Generate a new SSH key and save it to a local directory

```
ssh-keygen -t rsa -b 4096
```

Copy the contents `*.pub` file and paste them in the field `public_key` within `config.yml` file. 

```
aws:
  username: cml_asee_terraform
  group_name: terraform
  s3_bucket_name: CHANGEME
  key_name: asee-deployer
  public_key : ""

```

Additionally, modify the `s3_bucket_name` to a unique bucket name. Note that S3 bucket names are globally unique.

Configuration of these permissions require an account able to modify IAM and S3 at the minimum. Root provisioning is acceptable as long as the keys are deleted immediately after this deployment. 

To enable programmatic deployment with the account go to `Account -> Security Credentials -> Access Keys -> Create New Access Key`

Use the access credentials obtained in one of the previous step to configure the AWS CLI. Ensure that you use the correct region and keys.

```plain
aws configure

AWS Access Key ID []: ********************
AWS Secret Access Key []: ********************
Default region name []: us-east-1
Default output format []: json
```

### Terraform Description

What Terraform in this case will do is following:

- Create IAM user
- Create IAM group
- Assign IAM user to the group
- Create an S3 bucket for node images
- Define S3 policy that allows uploading, downloading, and listing files in the bucket
- Associating IAM policy with the S3 policy
- Create IAM role that associates IAM policy with S3 access 
- Associate EC2 full access policy to the IAM group
- Associate S3 access policy policy to the IAM group
- Create a PassRole policy that allows passing of the IAM role to the EC2 instance
- Assign the PassRole policy to the IAM group
- Associate generated SSH key with all provisined EC2 instances
- Generate Access Key and Secret Key from the IAM user and store it in a .csv file

### Terraform Provisioning

Initialize Terraform

```
terraform init

Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/aws...
- Finding latest version of hashicorp/local...
- Installing hashicorp/aws v5.33.0...
- Installed hashicorp/aws v5.33.0 (signed by HashiCorp)
- Installing hashicorp/local v2.4.1...
- Installed hashicorp/local v2.4.1 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!
```

Observe changes that Terraform will make

```
terraform plan

data.aws_iam_policy_document.assume_role: Reading...
data.aws_iam_policy_document.cml_policy_doc: Reading...
data.aws_iam_policy_document.cml_policy_doc: Read complete after 0s [id=2872473840]
data.aws_iam_policy_document.assume_role: Read complete after 0s [id=2851119427]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create
 <= read (data resources)

Terraform will perform the following actions:

  # data.aws_iam_policy_document.pass_role_policy will be read during apply
  # (config refers to values not yet known)
 <= data "aws_iam_policy_document" "pass_role_policy" {
      + id   = (known after apply)
      + json = (known after apply)

      + statement {
          + actions   = [
              + "iam:PassRole",
            ]
          + resources = [
              + (known after apply),
            ]
        }
    }
[...]
Plan: 14 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + access_key_id     = (sensitive value)
  + secret_access_key = (sensitive value)

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
```

Apply Terraform

```
terraform apply
data.aws_iam_policy_document.cml_policy_doc: Reading...
data.aws_iam_policy_document.assume_role: Reading...
aws_s3_bucket.my_bucket: Refreshing state... [id=s3-bucket-asee]
data.aws_iam_policy_document.cml_policy_doc: Read complete after 0s [id=2872473840]
data.aws_iam_policy_document.assume_role: Read complete after 0s [id=2851119427]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create
 <= read (data resources)
[...]

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_iam_group.terraform: Creating...
aws_iam_user.cml_terraform: Creating...
aws_key_pair.deployer: Creating...
aws_iam_policy.cml-s3-access-policy: Creating...
aws_iam_role.s3-access-for-ec2: Creating...
aws_iam_user.cml_terraform: Creation complete after 0s [id=cml_asee_terraform]
aws_iam_group.terraform: Creation complete after 0s [id=terraform]
aws_iam_access_key.cml_terraform_access_key: Creating...
aws_iam_group_policy_attachment.group_ec2_full_access: Creating...
aws_iam_group_membership.cml_group_membership: Creating...
aws_key_pair.deployer: Creation complete after 0s [id=asee-deployer]
aws_iam_policy.cml-s3-access-policy: Creation complete after 0s [id=arn:aws:iam::X:policy/cml-s3-access]
aws_iam_group_policy_attachment.group_s3_access: Creating...
aws_iam_access_key.cml_terraform_access_key: Creation complete after 1s [id=X]
local_file.cml_terraform_keys: Creating...
local_file.cml_terraform_keys: Creation complete after 0s [id=102edc6f68f9a39b0c8624f35ad3b2c3ffc39654]
aws_iam_group_membership.cml_group_membership: Creation complete after 1s [id=cml_asee_terraform]
aws_iam_group_policy_attachment.group_ec2_full_access: Creation complete after 1s [id=terraform-20240120183222528000000001]
aws_iam_role.s3-access-for-ec2: Creation complete after 1s [id=s3-access-for-ec2]
data.aws_iam_policy_document.pass_role_policy: Reading...
aws_iam_role_policy_attachment.attachment: Creating...
data.aws_iam_policy_document.pass_role_policy: Read complete after 0s [id=2972360089]
aws_iam_instance_profile.s3-access-for-ec2: Creating...
aws_iam_group_policy_attachment.group_s3_access: Creation complete after 0s [id=terraform-20240120183222591100000002]
aws_iam_group_policy.pass_role_policy: Creating...
aws_iam_role_policy_attachment.attachment: Creation complete after 0s [id=s3-access-for-ec2-20240120183222743100000003]
aws_iam_group_policy.pass_role_policy: Creation complete after 0s [id=terraform:PassRolePolicy]
aws_iam_instance_profile.s3-access-for-ec2: Creation complete after 0s [id=s3-access-for-ec2]

Apply complete! Resources: 13 added, 0 changed, 0 destroyed.

Outputs:

access_key_id = <sensitive>
secret_access_key = <sensitive>
```

At this point the account has been fully provisioned where access key and secret key are located in `cml-terraform-keys.csv`.

AWS configure should be re-executed with these credentials and credentials provisined earlier should be disabled in AWS console. 

```plain
aws configure

AWS Access Key ID []: ********************
AWS Secret Access Key []: ********************
Default region name []: us-east-1
Default output format []: json
```

Add those two keys to `terraform.tfvars` file inside of the `cloud-cml` folder

```
vim cloud-cml/terraform.tfvars

access_key = "********************"
secret_key = "********************"
```

## Upload Software to S3 bucket

Download rfplat image and unzip it and ensure you have the following layout

```
ls -l CML/*/*
-rw-r--r--@ 1 user  user  169748480 Jan  8 19:22 /Users/user/CML/refplat/cml2_2.6.1-11_amd64-11.pkg

/Users/user/CML/refplat/node-definitions:
total 144
-rw-r--r--  1 user  user  1923 Oct 31  2022 alpine-trex.yaml
-rw-r--r--  1 user  user  1915 Oct 31  2022 alpine-wanem.yaml
-rw-r--r--  1 user  user  2191 Oct 31  2022 alpine.yaml
-rw-r--r--  1 user  user  1725 Oct 31  2022 asav.yaml
-rw-r--r--  1 user  user  2150 Oct 31  2022 cat8000v.yaml
-rw-r--r--  1 user  user  5198 Oct 31  2022 cat9000v-dd.yaml
-rw-r--r--  1 user  user  5189 Oct 31  2022 cat9000v-s1.yaml
-rw-r--r--  1 user  user  2280 Oct 31  2022 csr1000v.yaml
-rw-r--r--  1 user  user  1905 Oct 31  2022 desktop.yaml
-rw-r--r--  1 user  user  1722 Oct 31  2022 iosv.yaml
-rw-r--r--  1 user  user  1734 Oct 31  2022 iosvl2.yaml
-rw-r--r--  1 user  user  3299 Jan 17  2023 iosxrv9000.yaml
-rw-r--r--  1 user  user  4177 Oct 31  2022 nxosv9000.yaml
-rw-r--r--  1 user  user  2372 Oct 31  2022 server.yaml
-rw-r--r--  1 user  user  3159 Oct 31  2022 ubuntu.yaml

/Users/user/CML/refplat/virl-base-images:
total 0
drwx------  4 user  user  128 Oct 31  2022 alpine-3-16-2-base
drwx------  4 user  user  128 Jan 17  2023 alpine-3-16-2-trex
drwx------  4 user  user  128 Oct 31  2022 alpine-3-16-2-wanem
drwx------  4 user  user  128 Oct 31  2022 asav-9-18-2
drwx------  4 user  user  128 Oct 31  2022 cat8000v-17-09-01a
drwx------  5 user  user  160 Oct 31  2022 cat9000v-17-10-01prd7
drwx------  4 user  user  128 Oct 31  2022 csr1000v-17-03-06
drwx------  4 user  user  128 Oct 31  2022 desktop-3-16-2-xfce
drwx------  4 user  user  128 Jan  8 23:39 iosv-159-3-m6
drwx------  4 user  user  128 Oct 31  2022 iosvl2-2020
drwx------  4 user  user  128 Oct 31  2022 iosxrv9000-7-7-1
drwx------  4 user  user  128 Oct 31  2022 nxosv9300-10-3-1-f
drwx------  4 user  user  128 Oct 31  2022 server-tcl-13-1
drwx------  4 user  user  128 Oct 31  2022 ubuntu-22-04-20221028
```

