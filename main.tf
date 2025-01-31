provider "aws" {
  region = "us-east-1" # Change to your desired region
}

# Fetch the default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch the subnet with the specified CIDR block
data "aws_subnet" "selected" {
  vpc_id     = data.aws_vpc.default.id
  cidr_block = "172.31.16.0/20"
}

# Create an ECR repository
resource "aws_ecr_repository" "my_ecr_repo" {
  name = "my-ecr-repo" # Change to your desired repository name
}

# Create a security group for the EC2 instance
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere (for demonstration purposes)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from anywhere (for demonstration purposes)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }
}

# Create an EC2 instance in the specified subnet
resource "aws_instance" "my_ec2_instance" {
  ami                    = "ami-0c614dee691cbbf37" # Replace with the correct AMI ID for your region
  instance_type          = "t2.micro"              # Change to your desired instance type
  subnet_id              = data.aws_subnet.selected.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id] # Use vpc_security_group_ids instead of security_groups

  tags = {
    Name = "my-ec2-instance"
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.my_ecr_repo.repository_url
}

output "ec2_instance_public_ip" {
  value = aws_instance.my_ec2_instance.public_ip
}