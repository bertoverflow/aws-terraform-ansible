variable "aws_profile" {}
variable "aws_region" {}

variable "key_name" {}
variable "public_key_path" {}

variable "local_ip" {}

variable "vpc_cidr" {}
variable "subnet_cidrs" {
  type = map(string)
}
variable "domain_name" {}
variable "dev_server_ami" {}
variable "dev_server_instance_type" {}

variable "db_instance_class" {}
variable "db_name" {}
variable "db_user" {}
variable "db_password" {}

variable "alb_healthy_threshold" {}
variable "alb_unhealthy_threshold" {}
variable "alb_timeout" {}
variable "alb_interval" {}

variable "userdata_filename" {}
variable "launch_config_instance_type" {}

variable "asg_max" {}
variable "asg_min" {}
variable "asg_health_check_grace_period" {}
variable "asg_health_check_type" {}
variable "asg_desired_capacity" {}

variable "delegation_set" {}

data "aws_availability_zones" "available" {}
