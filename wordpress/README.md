# Terraform
Build WordPress by Terraform

vi terraform.tfvars
```
region     = "us-east-1"
access_key = ""
secret_key = ""
# access_key = ""
# secret_key = ""
ami        = "ami-xxxxx"
username     = "db_user"
password     = "db_password"
key_name     = "[key_pair]"
ssh_key_file = "~/.ssh/[key_pair].pem"
```
