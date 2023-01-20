# Terraform-Deploy-a-Two-Tier-Architecture-in-AWS

![image](https://user-images.githubusercontent.com/115881685/213696496-132ed366-59a4-4f81-97d1-45e4e694b06d.png)

In this project, we will dive into Terraform. Terraform is a open-source Infrastructure as code tool. It enables you to build, change, and version resources in the cloud. You can work with multiple clouds using Terraform. For this article, we will be focusing on the AWS cloud. We will architect a 2-Tier Architecture that consists of the following:

* A VPC with 2 public subnets and 2 private subnets.

* A load balancer that will direct traffic to the public subnets and 1 EC2
  instance in each public subnet.

* An RDS MySQL instance in one of the subnets.

![image](https://user-images.githubusercontent.com/115881685/213697103-7457f4b3-5b8c-4799-98dd-903f898d5f9f.png)

### Prerequisites

* AWS account with credentials and a keypair.

* IDE, I will be using Visual Studio Code.

* You will need Terraform installed and AWS installed and configured.

The project we are creating will be considered a monolith, we will have a single main configuration file in a single directory. This is a small project to practice working with and understanding Terraform. At some point it may be safer and more logical to break up the monolith. But for now let’s move forward with the monolith.

### Write
First we need to create the code by using HashiCorp Configuration Language (HCL). I will be using VSCode IDE to input my code. You will need to create a new directory for your Terraform project, I called mine Two-tier-project. Navigate into that directory using the terminal in VSCode type in cd <directory>. Then create a new file main.tf in that directory. You can copy and paste from my code gists below to create a single file. You can also modify or create your own. I used the terraform registry to help build my code. Now lets break up the code to explain each part in detail.
  
```  
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

# Configure provider
provider "aws" {
  region  = "us-east-1"
}

# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name        = "vpc-project"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    Name        = "ig-project"
  }
}

# Create 2 public subnets
resource "aws_subnet" "public_1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-2"
  }
}

# Create 2 private subnets
resource "aws_subnet" "private_1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-2"
  }
}
```

In this first snippet of code we are letting Terraform know what cloud provider we will be using and configuring to that provider, AWS. Next we are creating resources. The first resource is creating a custom VPC with CIDR 10.0.0.0/16. Next it creates an internet gateway to attach to the VPC. Following that we create 2 public subnets with CIDR 10.0.1.0/24 and 10.0.2.0/24. Each subnet is in a different availability zone; us-east-1a and us-east-1b. For high availability. Then we create 2 private subnets with CIDR 10.0.3.0/24 and 10.0.4.0/24, also in 2 different availability zones. Notice the public subnets map public IP on launch where as the private subnets do not, this is why they are “private”.
  
```  
# Create route table to internet gateway
resource "aws_route_table" "project_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }
    tags = {
    Name = "project-rt"
  }
}

# Associate public subnets with route table
resource "aws_route_table_association" "public_route_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.project_rt.id
}

resource "aws_route_table_association" "public_route_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.project_rt.id
}

# Create security groups
resource "aws_security_group" "public_sg" {
  name        = "public-sg"
  description = "Allow web and ssh traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

  }
}

resource "aws_security_group" "private_sg" {
  name        = "private-sg"
  description = "Allow web tier and ssh traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.0/16"]
    security_groups = [ aws_security_group.public_sg.id ]
  }
  ingress {
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

  }
}
```
  
Here we are creating a route table to route traffic through the internet gateway to have internet access to the VPC. We then need to associate our subnets with the route table. Only granting access to the public subnets. Next we create security groups. The first security group is for the public subnets. It will allow incoming web access on port 80 (HTTP) as well as SSH access. The second security group will be for the private subnets to only allow access from the security group via the web tier and SSH access. The port 3306, being the default port for MYSQL.
  
```
# Security group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "security group for alb"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create ALB
resource "aws_lb" "project_alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

# Create ALB target group
resource "aws_lb_target_group" "project_tg" {
  name     = "project-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  depends_on = [aws_vpc.vpc]
}

# Create target attachments
resource "aws_lb_target_group_attachment" "tg_attach1" {
  target_group_arn = aws_lb_target_group.project_tg.arn
  target_id        = aws_instance.web1.id
  port             = 80

  depends_on = [aws_instance.web1]
}

resource "aws_lb_target_group_attachment" "tg_attach2" {
  target_group_arn = aws_lb_target_group.project_tg.arn
  target_id        = aws_instance.web2.id
  port             = 80

  depends_on = [aws_instance.web2]
}

# Create listener
resource "aws_lb_listener" "listener_lb" {
  load_balancer_arn = aws_lb.project_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.project_tg.arn
  }
}
```
  
This gist is all about the load balancer. This was tricky to figure out. I kept getting health check errors on my EC2 instances. So I add a security group for my load balancer. Then we create a application load balancer that is internet facing. With the load balancer you need the following:
  
* Target group.
  
* Target attachments, your EC2 instances.
  
* A listener on port 80.
  
  
