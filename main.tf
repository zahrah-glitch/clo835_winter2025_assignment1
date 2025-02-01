# Step 1 - Define the provider
provider "aws" {
  region = "us-east-1"
}

# Fetch the default VPC
data "aws_vpc" "default" {
  default = true
}

# Step 5 - Adding SSH key to Amazon EC2
resource "aws_key_pair" "week3" {
  key_name   = "week3"
  public_key = file("week3.pub") # Ensure week3.pub exists in the working directory
}

# Step 3 - Create a security group for the EC2 instance
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere (for testing)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from anywhere (for testing)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }
}

# Step 2 - Deploy EC2 instance in the default VPC
resource "aws_instance" "my_amazon" {
  ami               = "ami-08e4e35cccc6189f4"
  instance_type     = "t2.micro"
  key_name          = aws_key_pair.week3.key_name
  availability_zone = "us-east-1b" # Ensure it's in the same AZ as the EBS volume

  security_groups = [aws_security_group.ec2_sg.name] # Attach Security Group

  tags = {
    "Name"  = "Week3-Amazon-Linux"
    "Owner" = "acs_730"
    "App"   = "Web"
  }
}

# Step 4 - Create another EBS volume
resource "aws_ebs_volume" "week3" {
  availability_zone = "us-east-1b"
  size              = 40

  tags = {
    Name = "Week3"
  }
}

# Step 4.1 - Attach EBS Volume to the EC2 Instance
resource "aws_volume_attachment" "week3_attach" {
  device_name = "/dev/xvdf" # Adjust as needed
  volume_id   = aws_ebs_volume.week3.id
  instance_id = aws_instance.my_amazon.id
}

# Step 6 - Create ECR Repository for SQL
resource "aws_ecr_repository" "sql_repo" {
  name = "sql-repo" # Fixed: Lowercase with valid characters

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name  = "SQL Repo"
    Owner = "acs_730"
  }
}

# Step 7 - Create ECR Repository for App
resource "aws_ecr_repository" "app_repo" {
  name = "app-repo" # Fixed: Lowercase with valid characters

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name  = "App Repo"
    Owner = "acs_730"
  }
}


output "ecr_repository_url" {
  value = aws_ecr_repository.sql_repo.repository_url
}

output "ecr_repository_url2" {
  value = aws_ecr_repository.app_repo.repository_url
}
output "ec2_instance_public_ip" {
  value = aws_instance.my_amazon.public_ip
}