#creat the ec2 instance
terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "4.8.0"
      }
    }

  }

#configure the AWS provider
provider "aws" {
   region = "ap-south-1"

}
# creat vpc
resource "aws_vpc" "terraform-vpc" {
  cidr_block       = "10.10.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "TERRAFORM-VPC"
  }
}
# public subnet-1a
resource "aws_subnet" "public-subnet-1a" {
  vpc_id     = aws_vpc.terraform-vpc.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "public-subnet-1a"
  }
}
# public subnet-1b
resource "aws_subnet" "public-subnet-1b" {
  vpc_id     = aws_vpc.terraform-vpc.id
  cidr_block = "10.10.2.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "public-subnet-1b"
  }
}
# private subnet-1c
resource "aws_subnet" "private-subnet-1c" {
  vpc_id     = aws_vpc.terraform-vpc.id
  cidr_block = "10.10.3.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "private-subnet-1c"
  }
}
# prvate subnet-1d
resource "aws_subnet" "private-subnet-1d" {
  vpc_id     = aws_vpc.terraform-vpc.id
  cidr_block = "10.10.4.0/24"
  availability_zone = "ap-south-1b"
map_public_ip_on_launch = "true"
  tags = {
    Name = "private-subnet-1d"
  }
}

# creating the ec2

resource "aws_instance" "instance-1a" {
  ami           = "ami-062df10d14676e201"
  key_name      = "first-key"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public-subnet-1a.id
  vpc_security_group_ids = [aws_security_group.alllow_80_22.id]
# security_groups = [" security_demo_port"]

  tags = {
     Name            = "Instance-1a"
     App             = "frontend"
     Technical_Owner = "Prameela"

  }
    
}
# creating securtiy group

resource "aws_security_group" "alllow_80_22" {
  name        = "allow_port-80-and-22"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.terraform-vpc.id

  ingress {
    description      = "Allow port 22"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
    ingress {
    description      = "Allow port 80"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  
  }



  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "allow_22-80"
  }
}

# creating Internet GW
resource "aws_internet_gateway" "Terraform_IW" {
  vpc_id = aws_vpc.terraform-vpc.id

  tags = {
    Name = "Terraform_IW"
  }
}

# creating the route table
resource "aws_route_table" "terraform-route-table" {
  vpc_id = aws_vpc.terraform-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Terraform_IW.id
  }


  tags = {
    Name = "terraform-route-table"
  }
}
# creating the route table association
resource "aws_route_table_association" "Terraform-RT-association-1A" {
  subnet_id      = aws_subnet.public-subnet-1a.id
  route_table_id = aws_route_table.terraform-route-table.id
}


# creating the target group for LB

resource "aws_lb_target_group" "terraform-LB-target-group" {
  name     = "terraform-LB-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform-vpc.id
}

# Creating LB target group attachment

resource "aws_lb_target_group_attachment" "terraform-LB-target-group-attachment-1" {
  target_group_arn = aws_lb_target_group.terraform-LB-target-group.arn
  target_id        = aws_instance.instance-1a.id
  port             = 80
}

# creating the load balancer

resource "aws_lb" "Terraform-LB" {
  name               = "Terraform-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alllow_80.id]
  subnets            = [aws_subnet.public-subnet-1a.id,aws_subnet.public-subnet-1b.id]

  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}

# creating securtiy group for LB

resource "aws_security_group" "alllow_80" {
  name        = "allow_port-80"
  description = "Allow HTTP"
  vpc_id      = aws_vpc.terraform-vpc.id

  ingress {
    description      = "Allow port 80"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  
  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-80"
  }
}

# creating listener

resource "aws_lb_listener" "terraform-LB-listener" {
  load_balancer_arn = aws_lb.Terraform-LB.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform-LB-target-group.arn
  }
}