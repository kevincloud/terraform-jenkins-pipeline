variable "aws_access_key" {
    description = "AWS Access Key"
}

variable "aws_secret_key" {
    description = "AWS Secret Key"
}

variable "aws_region" {
    description = "AWS Region"
    default = "us-east-1"
}

variable "key_pair" {
    description = "Key pair used to login to the instance"
}

variable "instance_type" { 
    description = "Instance type for the Jenkins server"
    default = "t3.medium"
}

variable "tfe_api_token" {
    description = "The token used for Jenkins to interact with TFE"
}

variable "bucket" {
    description = "The bucket used for accessing artifacts"
}

variable "org_name" {
    description = "The name of the TFE Organization"
}

variable "workspace_name" {
    description = "The name of the TFE workspace"
}

variable "prefix" {
    description = "Unique prefix for naming"
}
