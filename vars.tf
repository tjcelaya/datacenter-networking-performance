# the vpc module doesn't allow passing these directly so just use
# the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY envs

variable "aws_ssh_user" {}

variable "aws_instance_type" {}

variable "aws_ssh_key_path" {}

# variable "aws_access_key" {}

# variable "aws_secret_key" {}
