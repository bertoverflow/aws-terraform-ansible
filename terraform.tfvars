aws_profile = "" // set as environment variable
aws_region  = "eu-central-1"

//local_ip = "" // set as environment variable

//key_name        = "" // set as environment variable
//public_key_path = "" // set as environment variable

vpc_cidr = "10.0.0.0/16"
subnet_cidrs = {
  public1  = "10.0.1.0/24"
  public2  = "10.0.2.0/24"
  private1 = "10.0.3.0/24"
  private2 = "10.0.4.0/24"
  rds1     = "10.0.5.0/24"
  rds2     = "10.0.6.0/24"
  rds3     = "10.0.7.0/24"
}
//domain_name              = "" // set as environment variable
dev_server_ami           = "ami-0c115dbd34c69a004"
dev_server_instance_type = "t2.micro"

db_instance_class = "db.t2.micro"
//db_name           = "" // set as environment variable
//db_user           = "" // set as environment variable
//db_password       = "" // set as environment variable

alb_healthy_threshold   = 2
alb_unhealthy_threshold = 2
alb_timeout             = 3
alb_interval            = 30

userdata_filename           = "userdata"
launch_config_instance_type = "t2.micro"

asg_max                       = 2
asg_min                       = 1
asg_health_check_grace_period = 300
asg_health_check_type         = "EC2"
asg_desired_capacity          = 2

delegation_set = "N01305881RXA7DVRIVVIA"
