variable "region" {
	description = "The AWS region."
	default = "eu-west-1"
}

variable "name" {
	description = "Name used to prefix all resources names"
	default = "platform-nfs"
}

variable "nfs_instance_profile" {
	description = "NFS instance profile ARNs"
	default = {
		"DUMMY_ACCOUNTID" = "DUMMY_ARN"
		"DUMMY_ACCOUNTID" = "DUMMY_ARN"
	}
}
