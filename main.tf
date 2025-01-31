provider "aws" {
  region = "us-east-1" # Change the region if needed
}

# Create an Amazon ECR repository
resource "aws_ecr_repository" "my_ecr" {
  name = "my-container-repo"
}

# Get default VPC and a public subnet
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "public" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Security Group for EC2
resource "aws_security_group" "ec2_sg" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH (change to your IP for security)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role for EC2 to pull from ECR
resource "aws_iam_role" "ec2_role" {
  name = "ec2-ecr-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "ecr_access" {
  name       = "ecr-access-attachment"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# Create an EC2 instance in the public subnet
resource "aws_instance" "my_ec2" {
  ami                    = "ami-09e67e426f25ce0d7" # Amazon Linux 2 AMI (Update if needed)
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = "your-key-name" # Replace with your key pair

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras enable docker
    yum install -y docker
    service docker start
    usermod -aG docker ec2-user
    $(aws ecr get-login --no-include-email --region us-east-1)
  EOF

  tags = {
    Name = "MyEC2ContainerInstance"
  }
}
