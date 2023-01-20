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
