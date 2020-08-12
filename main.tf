provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# ------------------------------------------------------------------------------------------
# IAM
# ------------------------------------------------------------------------------------------

# S3_access

resource "aws_iam_instance_profile" "s3_access_profile" {
  name = "s3_access"
  role = aws_iam_role.s3_access_role.name
}

resource "aws_iam_role" "s3_access_role" {
  name = "s3_access_role"

  assume_role_policy = <<-ROLE_POLICY
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Effect": "Allow",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Sid": ""
        }
      ]
    }
  ROLE_POLICY
}

resource "aws_iam_role_policy" "s3_access_policy" {
  name = "s3_access_policy"
  role = aws_iam_role.s3_access_role.id

  policy = <<-POLICY
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "s3:*",
          "Effect": "Allow",
          "Resource": "*"
        }
      ]
    }
  POLICY
}

# ------------------------------------------------------------------------------------------
# VPC
# ------------------------------------------------------------------------------------------

resource "aws_vpc" "wp_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "wp_vpc"
  }
}

resource "aws_internet_gateway" "wp_internet_gateway" {
  vpc_id = aws_vpc.wp_vpc.id

  tags = {
    Name = "wp_igw"
  }
}

# Route tables

resource "aws_route_table" "wp_public_rt" {
  vpc_id = aws_vpc.wp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wp_internet_gateway.id
  }

  tags = {
    Name = "wp_public"
  }
}

resource "aws_default_route_table" "wp_private_rt" {
  default_route_table_id = aws_vpc.wp_vpc.default_route_table_id

  tags = {
    Name = "wp_private"
  }
}

# ------------------------------------------------------------------------------------------
# VPC - Subnets
# ------------------------------------------------------------------------------------------

# Public subnets

resource "aws_subnet" "wp_public1_subnet" {
  vpc_id                  = aws_vpc.wp_vpc.id
  cidr_block              = var.subnet_cidrs["public1"]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "wp_public1"
  }
}

resource "aws_subnet" "wp_public2_subnet" {
  vpc_id                  = aws_vpc.wp_vpc.id
  cidr_block              = var.subnet_cidrs["public2"]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "wp_public2"
  }
}

# Private subnets

resource "aws_subnet" "wp_private1_subnet" {
  vpc_id                  = aws_vpc.wp_vpc.id
  cidr_block              = var.subnet_cidrs["private1"]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "wp_private1"
  }
}

resource "aws_subnet" "wp_private2_subnet" {
  vpc_id                  = aws_vpc.wp_vpc.id
  cidr_block              = var.subnet_cidrs["private2"]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "wp_private2"
  }
}

# RDS subnets

resource "aws_subnet" "wp_rds1_subnet" {
  vpc_id                  = aws_vpc.wp_vpc.id
  cidr_block              = var.subnet_cidrs["rds1"]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "wp_rds1"
  }
}

resource "aws_subnet" "wp_rds2_subnet" {
  vpc_id                  = aws_vpc.wp_vpc.id
  cidr_block              = var.subnet_cidrs["rds2"]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "wp_rds2"
  }
}

resource "aws_subnet" "wp_rds3_subnet" {
  vpc_id                  = aws_vpc.wp_vpc.id
  cidr_block              = var.subnet_cidrs["rds3"]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[2]

  tags = {
    Name = "wp_rds3"
  }
}

# RDS subnet group

resource "aws_db_subnet_group" "wp_rds_subnetgroup" {
  name = "wp_rds_subnetgroup"

  subnet_ids = [
    aws_subnet.wp_rds1_subnet.id,
    aws_subnet.wp_rds2_subnet.id,
    aws_subnet.wp_rds3_subnet.id
  ]

  tags = {
    Name = "wp_rds_subnetgroup"
  }
}

# associate public subnets with public route table
# all other subnets will automatically associated with the default route table (the private one)

resource "aws_route_table_association" "wp_public1_assoc" {
  subnet_id      = aws_subnet.wp_public1_subnet.id
  route_table_id = aws_route_table.wp_public_rt.id
}

resource "aws_route_table_association" "wp_public2_assoc" {
  subnet_id      = aws_subnet.wp_public2_subnet.id
  route_table_id = aws_route_table.wp_public_rt.id
}

# ------------------------------------------------------------------------------------------
# VPC - Security Groups
# ------------------------------------------------------------------------------------------

resource "aws_security_group" "wp_dev_sg" {
  vpc_id      = aws_vpc.wp_vpc.id
  name        = "wp_dev_sg"
  description = "Used for access to the dev instance"

  # ssh
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.local_ip]
  }

  # http
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = [var.local_ip]
  }

  // TODO
  # allow all outgoing
    egress {
      protocol = "-1"
      from_port = 0
      to_port = 0
      cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "wp_public_sg" {
  vpc_id      = aws_vpc.wp_vpc.id
  name        = "wp_public_sg"
  description = "Used for the elastic load balancer for public access"

  # http
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  // TODO
  # allow all outgoing
    egress {
      protocol = "-1"
      from_port = 0
      to_port = 0
      cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "wp_private_sg" {
  vpc_id      = aws_vpc.wp_vpc.id
  name        = "wp_private_sg"
  description = "Used for private access inside the vpc"

  # allow all incoming from vpc
  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.vpc_cidr]
  }

  // TODO
  # allow all outgoing
    egress {
      protocol = "-1"
      from_port = 0
      to_port = 0
      cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "wp_rds_sg" {
  vpc_id      = aws_vpc.wp_vpc.id
  name        = "wp_rds_sg"
  description = "Used for RDS instances"

  # SQL access from public and private security groups
  ingress {
    protocol  = "tcp"
    from_port = 3306
    to_port   = 3306

    security_groups = [
      aws_security_group.wp_dev_sg.id,
      aws_security_group.wp_public_sg.id,
      aws_security_group.wp_private_sg.id
    ]
  }
}

# ------------------------------------------------------------------------------------------
# VPC - Endpoints
# ------------------------------------------------------------------------------------------

resource "aws_vpc_endpoint" "wp_private-s3_endpoint" {
  vpc_id       = aws_vpc.wp_vpc.id
  service_name = "com.amazonaws.${var.aws_region}.s3"

  route_table_ids = [
    aws_vpc.wp_vpc.main_route_table_id,
    aws_route_table.wp_public_rt.id
  ]

  policy = <<-ENDPOINT_POLICY
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "*",
          "Effect": "Allow",
          "Resource": "*",
          "Principal": "*"
        }
      ]
    }
  ENDPOINT_POLICY
}

# ------------------------------------------------------------------------------------------
# S3
# ------------------------------------------------------------------------------------------

resource "random_id" "wp_code_bucket" {
  byte_length = 2
}

resource "aws_s3_bucket" "wp_code" {
  bucket        = "${var.domain_name}-${random_id.wp_code_bucket.dec}"
  acl           = "private"
  force_destroy = true

  tags = {
    Name = "wp_code_bucket"
  }
}

# ------------------------------------------------------------------------------------------
# RDS
# ------------------------------------------------------------------------------------------

resource "aws_db_instance" "wp_db" {
  instance_class         = var.db_instance_class
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "8.0.17"
  name                   = var.db_name
  username               = var.db_user
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.wp_rds_subnetgroup.name
  vpc_security_group_ids = [aws_security_group.wp_rds_sg.id]
  skip_final_snapshot    = true
}

# ------------------------------------------------------------------------------------------
# DEV - Server
# ------------------------------------------------------------------------------------------

# key pair

resource "aws_key_pair" "wp_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# dev server

resource "aws_instance" "wp_dev" {
  ami           = var.dev_server_ami
  instance_type = var.dev_server_instance_type

  key_name               = aws_key_pair.wp_auth.id // TODO name vs. id?
  vpc_security_group_ids = [aws_security_group.wp_dev_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.s3_access_profile.id
  subnet_id              = aws_subnet.wp_public1_subnet.id

  tags = {
    Name = "wp_dev"
  }

  # create the hosts file which we will be using for ansible
  provisioner "local-exec" {
    command = <<-CREATE_HOSTS
      cat <<-ANSIBLE_HOSTS > aws_hosts
      [dev]
      ${aws_instance.wp_dev.public_ip}
      [dev:vars]
      s3code=${aws_s3_bucket.wp_code.bucket}
      domain=${var.domain_name}
      ANSIBLE_HOSTS
    CREATE_HOSTS
  }

  # provision the the dev server with ansible
  provisioner "local-exec" {
    command = <<-PROVISION_DEV_SERVER
      aws ec2 wait instance-status-ok --instance-ids ${aws_instance.wp_dev.id} \
        && ansible-playbook -i aws_hosts wordpress.yml
    PROVISION_DEV_SERVER
  }
}

# ------------------------------------------------------------------------------------------
# ELB
# ------------------------------------------------------------------------------------------

// TODO replace with an application load balancer

resource "aws_elb" "wp_elb" {
  name = "wp-${var.domain_name}-elb"

  subnets = [
    aws_subnet.wp_public1_subnet.id,
    aws_subnet.wp_public2_subnet.id
  ]

  security_groups = [aws_security_group.wp_public_sg.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = var.elb_healthy_threshold
    unhealthy_threshold = var.elb_unhealthy_threshold
    timeout             = var.elb_timeout
    interval            = var.elb_interval
    target              = "TCP:80"
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "wp-${var.domain_name}-elb"
  }
}

# ------------------------------------------------------------------------------------------
# Golden AMI
# ------------------------------------------------------------------------------------------

# random ami id

resource "random_id" "golden_ami" {
  byte_length = 4
}

# AMI

resource "aws_ami_from_instance" "wp_golden" {
  name               = "wp_ami-${random_id.golden_ami.b64}"
  source_instance_id = aws_instance.wp_dev.id

  # create a userdata-script that will then be used/executed in every ec2-instance that we spin up from this AMI
  # via the corresponding launch configuration
  provisioner "local-exec" {
    command = <<-CREATE_USERDATA
      cat <<-USERDATA > ${var.userdata_filename}
      #!/bin/bash
      /usr/bin/aws s3 sync s3://${aws_s3_bucket.wp_code.bucket} /var/www/html/
      /bin/touch /var/spool/cron/root
      sudo /bin/echo '*/5 * * * * aws s3 sync s3://${aws_s3_bucket.wp_code.bucket} /var/www/html/' >> /var/spool/cron/root
      USERDATA
    CREATE_USERDATA
  }
}

# ------------------------------------------------------------------------------------------
# Launch Configuration
# ------------------------------------------------------------------------------------------

resource "aws_launch_configuration" "wp_launch_config" {
  image_id             = aws_ami_from_instance.wp_golden.id
  instance_type        = var.launch_config_instance_type
  name_prefix          = "wp_lc-"
  security_groups      = [aws_security_group.wp_private_sg.id]
  iam_instance_profile = aws_iam_instance_profile.s3_access_profile.id
  key_name             = aws_key_pair.wp_auth.id
  user_data            = file(var.userdata_filename)

  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------------------------------------------------------------------
# Auto Scaling Group
# ------------------------------------------------------------------------------------------

resource "aws_autoscaling_group" "wp_asg" {
  name                      = "asg-${aws_launch_configuration.wp_launch_config.id}"
  max_size                  = var.asg_max
  min_size                  = var.asg_min
  health_check_grace_period = var.asg_health_check_grace_period
  health_check_type         = var.asg_health_check_type
  desired_capacity          = var.asg_desired_capacity
  force_delete              = true
  load_balancers            = [aws_elb.wp_elb.id]

  vpc_zone_identifier = [
    aws_subnet.wp_private1_subnet.id,
    aws_subnet.wp_private2_subnet.id
  ]

  launch_configuration = aws_launch_configuration.wp_launch_config.name // TODO id vs. name

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "wp_asg-instance"
    propagate_at_launch = true
  }
}

# ------------------------------------------------------------------------------------------
# Route 53
# ------------------------------------------------------------------------------------------

resource "aws_route53_zone" "primary" {
  name              = "${var.domain_name}.net"
  delegation_set_id = var.delegation_set
}

resource "aws_route53_record" "www" {
  name    = "www.${var.domain_name}.net"
  zone_id = aws_route53_zone.primary.zone_id
  type    = "A"

  alias {
    name                   = aws_elb.wp_elb.dns_name
    zone_id                = aws_elb.wp_elb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "dev" {
  name    = "dev.${var.domain_name}.net"
  zone_id = aws_route53_zone.primary.zone_id
  type    = "A"
  ttl     = 300
  records = [aws_instance.wp_dev.public_ip]
}

# private zone

resource "aws_route53_zone" "secondary" {
  name = "${var.domain_name}.net"

  vpc {
    vpc_id = aws_vpc.wp_vpc.id
  }
}

resource "aws_route53_record" "db" {
  name    = "db.${var.domain_name}.net"
  zone_id = aws_route53_zone.secondary.zone_id
  type    = "CNAME"
  ttl     = 300
  records = [aws_db_instance.wp_db.address]
}

