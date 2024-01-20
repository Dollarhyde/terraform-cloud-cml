# Author: Erwin Karincic
# Project: ASEE

locals {
  cfg_file = file("config.yml")
  cfg      = yamldecode(local.cfg_file)
  username = local.cfg.aws.username
  group_name = local.cfg.aws.group_name
  s3_bucket_name = local.cfg.aws.s3_bucket_name
  key_name = local.cfg.aws.key_name
  public_key = local.cfg.aws.public_key
}


# Create S3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "${local.s3_bucket_name}"
}

# Create IAM user
resource "aws_iam_user" "cml_terraform" {
  name = local.username
}

# Create IAM group
resource "aws_iam_group" "terraform" {
  name = local.group_name
}

# Assign the user to the group
resource "aws_iam_group_membership" "cml_group_membership" {
  name = aws_iam_user.cml_terraform.name
  users = [aws_iam_user.cml_terraform.name]
  group = aws_iam_group.terraform.name
}

# Define policy document for S3 access
data "aws_iam_policy_document" "cml_policy_doc" {
  version = "2012-10-17"
  statement {
    sid = "VisualEditor0"
    effect = "Allow"
    actions   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.s3_bucket_name}", "arn:aws:s3:::${local.s3_bucket_name}/*"]
  }
}

# Create IAM policy for S3 access
resource "aws_iam_policy" "cml-s3-access-policy" {
  name        = "cml-s3-access"
  policy = data.aws_iam_policy_document.cml_policy_doc.json
}

# Define policy document for role assumption by EC2
data "aws_iam_policy_document" "assume_role" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Create IAM role for EC2 S3 access
resource "aws_iam_role" "s3-access-for-ec2" {
  name = "s3-access-for-ec2"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_instance_profile" "s3-access-for-ec2" {
  name = "s3-access-for-ec2"
  role = aws_iam_role.s3-access-for-ec2.name
}

# Attach the S3 access policy to the role
resource "aws_iam_role_policy_attachment" "attachment" {
  role       = aws_iam_role.s3-access-for-ec2.name
  policy_arn = aws_iam_policy.cml-s3-access-policy.arn
}

# Attach AmazonEC2FullAccess policy to the group
resource "aws_iam_group_policy_attachment" "group_ec2_full_access" {
  group      = aws_iam_group.terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# Attach the S3 access policy to the group
resource "aws_iam_group_policy_attachment" "group_s3_access" {
  group      = aws_iam_group.terraform.name
  policy_arn = aws_iam_policy.cml-s3-access-policy.arn
}

# Define policy document to allow passing the role
data "aws_iam_policy_document" "pass_role_policy" {
  statement {
    actions = ["iam:PassRole"]
    resources = [aws_iam_role.s3-access-for-ec2.arn]
  }
}

# Create the PassRole policy as an inline policy and attach it to the group
resource "aws_iam_group_policy" "pass_role_policy" {
  name   = "PassRolePolicy"
  group  = aws_iam_group.terraform.name
  policy = data.aws_iam_policy_document.pass_role_policy.json
}

# Create access key for the IAM user
resource "aws_iam_access_key" "cml_terraform_access_key" {
  user = aws_iam_user.cml_terraform.name
}

# Output the access key ID and secret access key (sensitive information)
output "access_key_id" {
  value     = aws_iam_access_key.cml_terraform_access_key.id
  sensitive = true
}

output "secret_access_key" {
  value     = aws_iam_access_key.cml_terraform_access_key.secret
  sensitive = true
}

# Create a CSV string with the access key ID and secret access key
locals {
  cml_terraform_keys_csv = "access_key,secret_key\n${aws_iam_access_key.cml_terraform_access_key.id},${aws_iam_access_key.cml_terraform_access_key.secret}"
}

# Save the CSV string to a file
resource "local_file" "cml_terraform_keys" {
  content  = local.cml_terraform_keys_csv
  filename = "${path.module}/cml-terraform-keys.csv"
}

resource "aws_key_pair" "deployer" {
  key_name   = local.key_name
  public_key = local.public_key
}

