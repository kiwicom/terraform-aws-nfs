resource "gzip_me" "bin_ddns_route53" {
    input = "${file("bin/ddns_route53")}"
}
resource "gzip_me" "bin_attach_volume" {
    input = "${file("bin/attach_volume")}"
}
resource "gzip_me" "bin_ebs_snapshot" {
    input = "${file("bin/ebs_snapshot")}"
}
resource "gzip_me" "cron_ebs_snapshot" {
    input = "${file("bin/cron_ebs_snapshot")}"
}
data "template_file" "cloud_init" {
	template = "${file("cloud-init.yml.tpl")}"

	vars {
		bin_ddns_route53 = "${gzip_me.bin_ddns_route53.output}"
		bin_attach_volume = "${gzip_me.bin_attach_volume.output}"
		bin_ebs_snapshot = "${gzip_me.bin_ebs_snapshot.output}"
		cron_ebs_snapshot = "${gzip_me.cron_ebs_snapshot.output}"
	}
}

resource "aws_autoscaling_group" "platform-nfs" {
	name_prefix = "${var.name}-"
	max_size = 1
	desired_capacity = 1
	min_size = 0
	launch_configuration = "${aws_launch_configuration.platform_nfs.name}"
	vpc_zone_identifier = [
		"${data.terraform_remote_state.base.nated_subnet_a}",
	]

	termination_policies = ["OldestInstance"]

	tag {
		key = "Name"
		value = "${var.name}"
		propagate_at_launch = true
	}
	tag {
		key = "team"
		value = "platform"
		propagate_at_launch = true
	}
}

resource "aws_launch_configuration" "platform_nfs" {
	name_prefix = "${var.name}-"
	key_name = "DUMMY"
	image_id = "ami-add175d4" # AWS's own Ubuntu 16.04 image
	instance_type = "i3.xlarge"
	user_data = "${data.template_file.cloud_init.rendered}"
	ebs_optimized = true

	iam_instance_profile = "${var.nfs_instance_profile[data.aws_caller_identity.current.account_id]}"

	root_block_device {
		volume_type = "gp2"
		volume_size = 100
		delete_on_termination  = true
	}

	security_groups = [
		"${data.terraform_remote_state.base.private_security_group}"
	]
	lifecycle {
		create_before_destroy = true
	}
}


resource "aws_ebs_volume" "platform_nfs_data1" {
    availability_zone = "eu-west-1a"
    size = 1000
	iops = 8000
	type = "io1"
	tags {
		Name = "platform-nfs-data1"
		team = "platform"
	}
}
resource "aws_ebs_volume" "platform_nfs_data2" {
    availability_zone = "eu-west-1a"
    size = 1000
	iops = 8000
	type = "io1"
	tags {
		Name = "platform-nfs-data2"
		team = "platform"
	}
}
