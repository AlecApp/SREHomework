provider "aws" {
	access_key = var.access_key
	secret_key = var.secret_key
	region = var.region
}

module "vpc" {
	source = "terraform-aws-modules/vpc/aws"

	name = "homework_vpc"
	cidr = "10.0.0.0/16"

	azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
	private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
	public_subnets = ["10.0.101.0/24"]
	
	enable_nat_gateway = true
	enable_vpn_gateway = true

	tags = {
		Terraform = "true"
		Environment = "homework"
	}
}

module "vpc_sg" {
	#Encountered issue with count index on built-in security rules array. Attempted to use v3.1 as a fix
	source = "terraform-aws-modules/security-group/aws"
	version = "3.1"

	name = "homework_vpc_sg"
	description = "Security group for homework_vpc. Allows traffic only on port 80, 443, and 22."
	vpc_id = module.vpc.vpc_id

	#Old ingress rules that produced count index error
	#ingress_cidr_blocks = ["0.0.0.0/0"]
	#ingress_rules = ["https-443-tcp", "http-80-tcp", "http-22-ssh"]

	ingress_with_cidr_blocks = [
		{
			from_port = 80
			to_port = 80
			protocol = "tcp"
			description = "http"
			cidr_blocks = "0.0.0.0/0"
		},
		{
			from_port = 443
			to_port = 443
			protocol = "tcp"
			description = "https"
			cidr_blocks = "0.0.0.0/0"
		},
		{
			from_port = 22
			to_port = 22
			protocol = "tcp"
			description = "ssh"
			cidr_blocks = "0.0.0.0/0"
		}
	]
}

module "ec2_cluster" {
	source = "terraform-aws-modules/ec2-instance/aws"
	version = "~> 2.0"

	name = "homework_ec2_cluster"
	instance_count = 1

	#AMI is 64-bit AWS Linux 2 HVM
	ami = "ami-04bf6dcdc9ab498ca"
	instance_type = "t2.micro"
	key_name = "homework_key"
	monitoring = true
	vpc_security_group_ids = [module.ec2_sg.this_security_group_id]
	subnet_id = module.vpc.private_subnets[0]

	tags = {
		Terraform = "true"
		Environment = "homework"
	}

}


module "ec2_sg" {
	source = "terraform-aws-modules/security-group/aws"
	version = "3.1"

	name = "homework_ec2_sg"
	description = "Security group for homework_ec2. Allows traffic only from the ELB."
	vpc_id = module.vpc.vpc_id

	ingress_with_source_security_group_id = [
		{
			from_port = 0
			to_port = 65535
			protocol = "tcp"
			description = "Allow Traffic From ELB Only"
			source_security_group_id = module.elb_sg.this_security_group_id
		}
	]

	egress_with_cidr_blocks = [
		{
			from_port = 0
			to_port = 65535
			protocol = "tcp"
			description = "Allow All Out"
			cidr_blocks = "0.0.0.0/0"
		}
	]
}

module "elb" {
	source = "terraform-aws-modules/elb/aws"
	version = "~> 2.0"

	name = "homework-elb"

	subnets = [module.vpc.public_subnets[0]]
	security_groups = [module.elb_sg.this_security_group_id]
	internal = false

	listener = [
		{
			instance_port = "80"
			instance_protocol = "HTTP"
			lb_port = "80"
			lb_protocol = "HTTP"
		}
	]

	health_check = {
		target = "HTTP:80/"
		interval = 30
		healthy_threshold = 2
		unhealthy_threshold = 2
		timeout = 5
	}

	number_of_instances = 1
	instances = [module.ec2_cluster.id[0]]
}

module "elb_sg" {
	source = "terraform-aws-modules/security-group/aws"
	version = "3.1"

	name = "homework_elb_sg"
	description = "Security group for homework_elb. Allows traffic only on port 80."
	vpc_id = module.vpc.vpc_id

	ingress_with_cidr_blocks = [
		{
			from_port = 80
			to_port = 80
			protocol = "tcp"
			description = "Allow HTTP Traffic Only"
			cidr_blocks = "0.0.0.0/0"
		}
	]

	egress_with_cidr_blocks = [
		{
			from_port = 0
			to_port = 65535
			protocol = "tcp"
			description = "Allow All Out"
			cidr_blocks = "0.0.0.0/0"
		}
	]
}

module "db" {
	source = "terraform-aws-modules/rds/aws"
	version = "~> 2.0"

	identifier = "homeworkdb"
	
	engine = "postgres"
	engine_version = "9.6.9"
	instance_class = "db.t2.micro"
	allocated_storage = 5
	storage_encrypted = false
	
	name = "homeworkdb"
	username = "homework"
	password = "homework"
	port = "5432"

	#Setting authentication to false for now. Obviously not suitable for real deployment.
	iam_database_authentication_enabled = false

	vpc_security_group_ids = [module.db_sg.this_security_group_id]

	maintenance_window = "Mon:00:00-Mon:03:00"
	backup_window = "03:00-06:00"

	#Also not enabling monitoring for now.
	create_monitoring_role = false

	tags = {
		Owner = "homework"
		Environment = "homework"
	}

	subnet_ids = [module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
	
	family = "postgres9.6"
	
	major_engine_version = "9.6"
	
	deletion_protection = false
}


module "db_sg" {
	source = "terraform-aws-modules/security-group/aws"
	version = "3.1"

	name = "homework_db_sg"
	description = "Security group for homework_db. Allows traffic only from EC2."
	vpc_id = module.vpc.vpc_id

	ingress_with_source_security_group_id = [
		{
			from_port = 0
			to_port = 65535
			protocol = "tcp"
			description = "Allow Traffic From EC2 Only"
			source_security_group_id = module.ec2_sg.this_security_group_id
		}
	]
	
	egress_with_cidr_blocks = [
		{
			from_port = 0
			to_port = 65535
			protocol = "tcp"
			description = "Allow All Out"
			cidr_blocks = "0.0.0.0/0"
		}
	]
}
