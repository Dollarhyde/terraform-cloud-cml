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

At that point run either `upload-images-to-aws-mac.sh` if on Linux or `upload-images-to-aws-mac.sh` if on MAC:

```
./upload-images-to-aws.sh [bucketname] [location such as /home/user/CML]
or
./upload-images-to-aws-mac.sh [bucketname] [location such as /Users/user/CML]
```

After upload is completed. Verify that the bucket contains similar structure. This will also verify credential access for deployment. 

```
aws s3 ls --recursive [bucketname]
```

```
aws s3 ls --recursive s3-bucket-asee
2024-01-22 18:16:28   85766356 cml2_2.6.1-11_amd64.deb
2024-01-22 18:16:39       1923 refplat/node-definitions/alpine-trex.yaml
2024-01-22 18:16:38       1915 refplat/node-definitions/alpine-wanem.yaml
2024-01-22 18:16:41       2191 refplat/node-definitions/alpine.yaml
2024-01-22 18:16:40       1725 refplat/node-definitions/asav.yaml
2024-01-22 18:16:48       2150 refplat/node-definitions/cat8000v.yaml
2024-01-22 18:16:47       5198 refplat/node-definitions/cat9000v-dd.yaml
2024-01-22 18:16:46       5189 refplat/node-definitions/cat9000v-s1.yaml
2024-01-22 18:16:44       2280 refplat/node-definitions/csr1000v.yaml
2024-01-22 18:16:48       1905 refplat/node-definitions/desktop.yaml
2024-01-22 18:16:42       1722 refplat/node-definitions/iosv.yaml
2024-01-22 18:16:45       1734 refplat/node-definitions/iosvl2.yaml
2024-01-22 18:16:35       3299 refplat/node-definitions/iosxrv9000.yaml
2024-01-22 18:16:37       4177 refplat/node-definitions/nxosv9000.yaml
2024-01-22 18:16:43       2372 refplat/node-definitions/server.yaml
2024-01-22 18:16:36       3159 refplat/node-definitions/ubuntu.yaml
2024-01-22 18:20:23   53673984 refplat/virl-base-images/alpine-3-16-2-base/alpine-3-16-2-base.qcow2
2024-01-22 18:20:23        263 refplat/virl-base-images/alpine-3-16-2-base/alpine-3-16-2-base.yaml
2024-01-22 18:19:47  394919936 refplat/virl-base-images/alpine-3-16-2-trex/alpine-3-16-2-trex.qcow2
2024-01-22 18:19:47        266 refplat/virl-base-images/alpine-3-16-2-trex/alpine-3-16-2-trex.yaml
2024-01-22 18:19:41   53215232 refplat/virl-base-images/alpine-3-16-2-wanem/alpine-3-16-2-wanem.qcow2
2024-01-22 18:19:41        290 refplat/virl-base-images/alpine-3-16-2-wanem/alpine-3-16-2-wanem.yaml
2024-01-22 18:20:07        320 refplat/virl-base-images/asav-9-18-2/asav-9-18-2.yaml
2024-01-22 18:20:07  340262912 refplat/virl-base-images/asav-9-18-2/asav9-18-2.qcow2
2024-01-22 18:24:50 1856634880 refplat/virl-base-images/cat8000v-17-09-01a/c8000v-universalk9_8G_serial.17.09.01a.qcow2
2024-01-22 18:24:50        282 refplat/virl-base-images/cat8000v-17-09-01a/cat8000v-17-09-01a.yaml
2024-01-22 18:23:06        329 refplat/virl-base-images/cat9000v-17-10-01prd7/cat9000v-dd-17.10.01prd7.yaml
2024-01-22 18:23:06        329 refplat/virl-base-images/cat9000v-17-10-01prd7/cat9000v-s1-17.10.01prd7.yaml
2024-01-22 18:23:06 2155806720 refplat/virl-base-images/cat9000v-17-10-01prd7/cat9kv-prd-17.10.01prd7.qcow2
2024-01-22 18:20:42        275 refplat/virl-base-images/csr1000v-17-03-06/csr1000v-17-03-06.yaml
2024-01-22 18:20:42 1422000128 refplat/virl-base-images/csr1000v-17-03-06/csr1000v-universalk9.17.03.06-serial.qcow2
2024-01-22 18:24:30  365138944 refplat/virl-base-images/desktop-3-16-2-xfce/desktop-3-16-2-xfce.qcow2
2024-01-22 18:24:30        264 refplat/virl-base-images/desktop-3-16-2-xfce/desktop-3-16-2-xfce.yaml
2024-01-22 18:20:30        258 refplat/virl-base-images/iosv-159-3-m6/iosv-159-3-m6.yaml
2024-01-22 18:20:30   57309696 refplat/virl-base-images/iosv-159-3-m6/vios-adventerprisek9-m.spa.159-3.m6.qcow2
2024-01-22 18:21:38        267 refplat/virl-base-images/iosvl2-2020/iosvl2-2020.yaml
2024-01-22 18:21:38   90409984 refplat/virl-base-images/iosvl2-2020/vios_l2-adventerprisek9-m.ssa.high_iron_20200929.qcow2
2024-01-22 18:16:49        264 refplat/virl-base-images/iosxrv9000-7-7-1/iosxrv9000-7-7-1.yaml
2024-01-22 18:16:49 1643905024 refplat/virl-base-images/iosxrv9000-7-7-1/xrv9k-fullk9-x-7.7.1.qcow2
2024-01-22 18:18:23 2097086464 refplat/virl-base-images/nxosv9300-10-3-1-f/nexus9300v64.10.3.1.F.qcow2
2024-01-22 18:19:38        269 refplat/virl-base-images/nxosv9300-10-3-1-f/nxosv9300-10-3-1-f.yaml
2024-01-22 18:20:37        242 refplat/virl-base-images/server-tcl-13-1/server-tcl-13-1.yaml
2024-01-22 18:20:37   21495808 refplat/virl-base-images/server-tcl-13-1/tcl-13-1.qcow2
2024-01-22 18:17:53  664862720 refplat/virl-base-images/ubuntu-22-04-20221028/jammy-server-cloudimg-amd64.img
2024-01-22 18:17:53        320 refplat/virl-base-images/ubuntu-22-04-20221028/ubuntu-22-04-20221028.yaml
```

## Initiate the CML instance 

The next step is to change directory to `cisco-cml` folder.

```
cd cisco-cml
```

The `config.yml` file needs to be modified. This information is directly for `cisco-cml` repository. 

- `aws.bucket`. This is the name of the bucket where the software and the reference platform files are stored. Must be accessible per the policy / role defined above
- `aws.region`. This defines the region of the bucket and typically matches the region of the AWS CLI as configured above. It also defines the region where the EC2 instances are created
- `aws.flavor`. The flavor / instance type to be used for the AWS CML instance. Typically a metal instance
- `aws.profile`. The name of the permission profile to be used for the instance. This needs to permit access to the S3 bucket with the software and reference platforms. In the example given above, this was named "s3-access-for-ec2"
- `aws.keyname`. SSH key name which needs to be installed on AWS EC2. This key will be injected into the instance using cloud-init.
- `aws.disk_size`. The size of the disk in gigabytes. 64 is a good starting value but this truly depends on the kind of nodes and the planned instance lifetime.

Key name `hostname`. Name of the instance, standard hostname rules apply.

Within the app section, the following keys must be set with the correct values:

- `app.user` username of the admin user (typically "admin") for UI access
- `app.pass` password of the admin user
- `app.deb` the filename of the Debian .deb package with the software, stored in the specified S3 bucket at the top level. In this case it should be `cml2_2.6.1-11_amd64.deb`
- `app.customize` a list of scripts, located in the `scripts` folder which will be run as part of the instance creation to customize the install

Within the sys section, the OS user and password are defined.

- `sys.user` username of the OS user (typically "sysadmin") for Cockpit and OS level maintenance access
- `sys.pass` the associated password

Within the license section, license flavor, token, and nodes are defined.

- `license.flavor`: either `CML_Enterprise`, `CML_Education`, `CML_Personal` or `CML_Personal40` are acceptable
- `license.token`: the Smart Licensing token
- `license.nodes`: the number of *additional* nodes, not applicable for the personal flavors.

Within the refplat section, images that were uploaded are selected. If all images were uploaded, no changes are necessary. 

- `refplat.definitions` lists the node definition IDs
- `refplat.images` lists the associated image definition IDs

Below is an example of a config.yml

```
aws:
  region: us-east-1
  bucket: s3-bucket-asee
  flavor: m5zn.metal
  profile: s3-access-for-ec2
  key_name: asee-deployer
  disk_size: 64

hostname: cml-controller

app:
  user: admin
  pass: ASEEASEE1!
  # need to escape special chars:
  # pass: '\"!@$%'
  deb: cml2_2.6.1-11_amd64.deb
  # list must have at least ONE element, this is what the dummy is for in case
  # 00- and 01- are commented out!
  customize:
    # - 00-patch_vmx.sh
    # - 01-patty.sh
    - 99-dummy.sh

sys:
  user: sysadmin
  pass: ASEEASEE1!

license:
  flavor: CML_Education
  token: MzQ2[...]D%0A
  # unless you have additional nodes, leave this at zero
  nodes: 0

# select the ones needed by un-/commenting them. The selected
# reference platforms will be copied from the specified bucket
# and must be available prior to starting an instance.
refplat:
  definitions:
    - alpine
    - alpine-trex
    - alpine-wanem
    - asav
    - cat8000v
    - cat9000v-s1
    - csr1000v
    - desktop
    - iosv
    - iosvl2
    - iosxrv9000
    - nxosv9000
    - server
    - ubuntu
  images:
    - alpine-3-16-2-base
    - alpine-3-16-2-trex
    - alpine-3-16-2-wanem
    - asav-9-18-2
    - cat8000v-17-09-01a
    - cat9000v-s1-17.10.01prd7
    - csr1000v-17-03-06
    - desktop-3-16-2-xfce
    - iosv-159-3-m6
    - iosvl2-2020
    - iosxrv9000-7-7-1
    - nxosv9300-10-3-1-f
    - server-tcl-13-1
    - ubuntu-22-04-20221028
```

### Starting an instance

Starting an instance is done via `terraform plan` and `terraform apply`. The instance will be deployed and fully configured based on the provided configuration. Terraform will wait until CML is up and running, this will take approximately 5-10 minutes and depends a bit on the flavor used.

At the end, the Terraform output shows the relevant information about the instance:

- The URL to access it
- The public IP address
- The CML software version running
- The command to automatically remove the license from the instance prior to destroying it (see below).

```
cml2info = {
  "address" = "54.162.98.41"
  "del" = "ssh -p1122 sysadmin@54.162.98.41 -i ../asee_rsa /provision/del.sh"
  "url" = "https://54.162.98.41"
  "version" = "2.6.1+build.11"
}
```

## Example run

To deploy a CML instance on AWS and after configuring the required variables and editing the `config.yaml` file, a `terraform plan` will show all the planned changes. After reviewing those, a `terraform apply` will start and configure a CML instance on AWS.

```plain
$ terraform apply -auto-approve
module.deploy.data.aws_ami.ubuntu: Reading...
module.deploy.data.aws_ami.ubuntu: Read complete after 1s [id=ami-0d497a49e7d359666]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create
 <= read (data resources)

Terraform will perform the following actions:

  # module.deploy.aws_instance.cml will be created
  + resource "aws_instance" "cml" {
      + ami                                  = "ami-0d497a49e7d359666"
      + arn                                  = (known after apply)
      + associate_public_ip_address          = (known after apply)
      + availability_zone                    = (known after apply)
      + cpu_core_count                       = (known after apply)
[...]

Plan: 3 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + cml2info = {}
module.deploy.random_id.id: Creating...
module.deploy.random_id.id: Creation complete after 0s [id=x1hR1Q]
module.deploy.aws_security_group.sg-tf: Creating...
module.deploy.aws_security_group.sg-tf: Creation complete after 2s [id=sg-04865f65e43aa917f]
module.deploy.aws_instance.cml: Creating...
module.deploy.aws_instance.cml: Still creating... [10s elapsed]
module.deploy.aws_instance.cml: Creation complete after 13s [id=i-0e7697766ca6c18e1]
module.ready.data.cml2_system.state: Reading...
module.ready.data.cml2_system.state: Still reading... [10s elapsed]
module.ready.data.cml2_system.state: Still reading... [20s elapsed]
[...]
module.ready.data.cml2_system.state: Still reading... [3m50s elapsed]
module.ready.data.cml2_system.state: Still reading... [4m0s elapsed]
module.ready.data.cml2_system.state: Read complete after 4m2s [id=dd68b604-8930-45c6-8d58-a1da578e02b4]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

cml2info = {
  "address" = "18.194.38.215"
  "del" = "ssh -p1122 sysadmin@18.194.38.215 -i ../asee_rsa /provision/del.sh"
  "url" = "https://18.194.38.215"
  "version" = "2.5.1+build.10"
}

$
```

As can be seen above, a public IPv4 address has been assigned to the instance which can be used to access it via SSH and the provided SSH key pair (if this does not connect right away then the system isn't ready, yet and more wait is needed):

```plain
$ ssh -p1122 sysadmin@18.194.38.215 -i ../asee_rsa 
The authenticity of host '[18.194.38.215]:1122 ([18.194.38.215]:1122)' can't be established.
ED25519 key fingerprint is SHA256:dz7GcRGzcWiyHbPb++NyQykP9r7UoG0rNiACi5ft1lQ.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '[18.194.38.215]:1122' (ED25519) to the list of known hosts.
Welcome to Ubuntu 20.04.6 LTS (GNU/Linux 5.15.0-1033-aws x86_64)
[...]
sysadmin@rschmied-aws-2023042001:~$ 
```

At this point, the status of the system can be checked:

```plain
sysadmin@rschmied-aws-2023042001:~$ systemctl status | head
● rschmied-aws-2023042001
    State: running
     Jobs: 0 queued
   Failed: 0 units
    Since: Fri 2023-04-21 14:45:00 UTC; 4min 34s ago
   CGroup: /
           ├─23120 bpfilter_umh
           ├─user.slice 
           │ └─user-1001.slice 
           │   ├─user@1001.service 
sysadmin@rschmied-aws-2023042001:~$ systemctl status virl2.target
● virl2.target - CML2 Network Simulation System
     Loaded: loaded (/lib/systemd/system/virl2.target; enabled; vendor preset: enabled)
     Active: active since Fri 2023-04-21 14:47:58 UTC; 2min 13s ago

Warning: some journal files were not opened due to insufficient permissions.
sysadmin@rschmied-aws-2023042001:~$ 
```

The system is running and the VIRL2 target (CML) is active!

Prior to stopping the instance, the licensing token must be removed via the UI. Otherwise it's still considered "in use" in Smart Licensing. This is done via the UI or using the `del.sh` script / SSH command which is provided as part of the deploy output (see above). Then run the destroy command.

> **Note:** The `del.sh` has no output if the command is successful.

```plain
$ ssh -p1122 sysadmin@18.194.38.215 -i ../asee_rsa /provision/del.sh
The authenticity of host '[18.194.38.215]:1122 ([18.194.38.215]:1122)' can't be established.
ED25519 key fingerprint is SHA256:4QxgLv9zzKR5gJP4rWE41STdnAHufBYkTKBpp/VA+k8.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '[18.194.38.215]:1122' (ED25519) to the list of known hosts.

$ terraform destroy -auto-approve
module.deploy.random_id.id: Refreshing state... [id=x1hR1Q]
module.deploy.data.aws_ami.ubuntu: Reading...
module.deploy.aws_security_group.sg-tf: Refreshing state... [id=sg-04865f65e43aa917f]
module.deploy.data.aws_ami.ubuntu: Read complete after 1s [id=ami-0d497a49e7d359666]
module.deploy.aws_instance.cml: Refreshing state... [id=i-0e7697766ca6c18e1]
module.ready.data.cml2_system.state: Reading...
module.ready.data.cml2_system.state: Read complete after 0s [id=cf22e2e6-7ef2-420b-8191-404f3f7f3600]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # module.deploy.aws_instance.cml will be destroyed
  - resource "aws_instance" "cml" {
      - ami                                  = "ami-0d497a49e7d359666" -> null
[...]

Plan: 0 to add, 0 to change, 3 to destroy.

Changes to Outputs:
  - cml2info = {
      - address = "18.194.38.215"
      - del     = "ssh -p1122 sysadmin@18.194.38.215 -i ../asee_rsa /provision/del.sh"
      - url     = "https://18.194.38.215"
      - version = "2.5.1+build.10"
    } -> null
module.deploy.aws_instance.cml: Destroying... [id=i-0e7697766ca6c18e1]
module.deploy.aws_instance.cml: Still destroying... [id=i-0e7697766ca6c18e1, 10s elapsed]
module.deploy.aws_instance.cml: Still destroying... [id=i-0e7697766ca6c18e1, 20s elapsed]
module.deploy.aws_instance.cml: Still destroying... [id=i-0e7697766ca6c18e1, 30s elapsed]
module.deploy.aws_instance.cml: Destruction complete after 30s
module.deploy.aws_security_group.sg-tf: Destroying... [id=sg-04865f65e43aa917f]
module.deploy.aws_security_group.sg-tf: Destruction complete after 0s
module.deploy.random_id.id: Destroying... [id=x1hR1Q]
module.deploy.random_id.id: Destruction complete after 0s

Destroy complete! Resources: 3 destroyed.

$
```

At this point, the compute resources have been released / destroyed. Images in the S3 bucket are still available for bringing up new instances.

> **Note:** Metal instances take significantly longer to bring up and to destroy. The `m5zn.metal` instance type takes about 5-10 minutes for both. Deployment times also depend on the number and size of reference platform images that should be copied to the instance.

