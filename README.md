# Terraform-Deploy-a-Two-Tier-Architecture-in-AWS

![image](https://user-images.githubusercontent.com/115881685/213696496-132ed366-59a4-4f81-97d1-45e4e694b06d.png)

In this project, we will dive into Terraform. Terraform is a open-source Infrastructure as code tool. It enables you to build, change, and version resources in the cloud. You can work with multiple clouds using Terraform. For this article, we will be focusing on the AWS cloud. We will architect a 2-Tier Architecture that consists of the following:

* A VPC with 2 public subnets and 2 private subnets.

* A load balancer that will direct traffic to the public subnets and 1 EC2
  instance in each public subnet.

* An RDS MySQL instance in one of the subnets.

![image](https://user-images.githubusercontent.com/115881685/213697103-7457f4b3-5b8c-4799-98dd-903f898d5f9f.png)

#### Prerequisites

* AWS account with credentials and a keypair.

* IDE, I will be using Visual Studio Code.

* You will need Terraform installed and AWS installed and configured.

The project we are creating will be considered a monolith, we will have a single main configuration file in a single directory. This is a small project to practice working with and understanding Terraform. At some point it may be safer and more logical to break up the monolith. But for now let’s move forward with the monolith.

#### Write
First we need to create the code by using HashiCorp Configuration Language (HCL). I will be using VSCode IDE to input my code. You will need to create a new directory for your Terraform project, I called mine **Two-tier-project**. Navigate into that directory using the terminal in VSCode type in cd <directory>. Then create a new file **main.tf** in that directory. You can copy and paste from my code gists below to create a single file. You can also modify or create your own. I used the terraform registry to help build my code. Now lets break up the code to explain each part in detail.
  
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
  
```  
# Create ec2 instances

resource "aws_key_pair" "MyKey_auth" {
  key_name = "MyKey"
  public_key = file("~/.ssh/MyKey.pub")
}

resource "aws_instance" "web1" {
  ami           = "ami-0cff7528ff583bf9a"
  instance_type = "t2.micro"
  key_name          = "MyKey"
  availability_zone = "us-east-1a"
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  subnet_id                   = aws_subnet.public_1.id
  associate_public_ip_address = true
  user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        systemctl start httpd
        systemctl enable httpd
        echo "<html><body><h1>Hi there</h1></body></html>" > /var/www/html/index.html
        EOF

  tags = {
    Name = "web1_instance"
  }
}
resource "aws_instance" "web2" {
  ami           = "ami-0cff7528ff583bf9a"
  instance_type = "t2.micro"
  key_name          = "MyKey"
  availability_zone = "us-east-1b"
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  subnet_id                   = aws_subnet.public_2.id
  associate_public_ip_address = true
  user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        systemctl start httpd
        systemctl enable httpd
        echo "<html><body><h1>Hi there again</h1></body></html>" > /var/www/html/index.html
        EOF

  tags = {
    Name = "web2_instance"
  }
}
```
    
Here we create the EC2 instances that will be launched into each public subnet. The EC2 instances have Amazon Linuz AMI and instance type t2.micro. I attached my keypair and associated a public IP address in order to SSH into the instance. I also added a bootstrap in the user_data section. This will install an Apache webserver upon launch. That will conclude the web tier.
  
```  
# Database subnet group
resource "aws_db_subnet_group" "db_subnet"  {
    name       = "db-subnet"
    subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

# Create database instance
resource "aws_db_instance" "project_db" {
  allocated_storage    = 5
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  identifier           = "db-instance"
  db_name              = "project_db"
  username             = "admin"
  password             = "password"
  db_subnet_group_name = aws_db_subnet_group.db_subnet.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]  
  publicly_accessible = false
  skip_final_snapshot  = true
}
```

The final piece is the database tier. We will create an RDS MYSQL database instance in one of the private subnets. In order to do this we need to add a database subnet group and put in our 2 private subnets. Then associate it with our database instance as well as the private security group. Notice the “identifier” names the database instance and “db_name” actually prompts it to create a database. You need to add a username and password to access the database. The way I have it is not secure. You could put the secrets in a *    tfvars file and reference it when applying the code. And that concludes the creation of the main file.
  
I am going to add one more file to our project. Create a file called **outputs.tf** in the same directory as the main file. Here we can indicate what outputs we want to see. They are used as a way to share data with other tools or automation. I will just use it to gather the information needed to access the instances. Copy and paste the gist below into your file.
  
```  
# Outputs
# Ec2 instance public ipv4 address
output "ec2_public_ip" {
  value = aws_instance.web1.public_ip
}

# Db instance address
output "db_instance_address" {
    value = aws_db_instance.project_db.address
}

# Getting the DNS of load balancer
output "lb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = "${aws_lb.project_alb.dns_name}"
}
```
  
#### Plan
Now that our code is written we can move on to the terminal. Input the command **terraform init**. To download libraries and modules needed, initialize the working directory that contains your Terraform code and set up the backend.
  
![2](https://user-images.githubusercontent.com/115881685/213705141-647e5264-f055-4466-8cd7-63881a1cdc7b.png)

Next input **terraform plan**. This will read the code, create and show you a plan of action.
  
 ![4](https://user-images.githubusercontent.com/115881685/213705421-f1d22c28-7beb-437a-9a93-e21c32602523.png)
  
Review the plan carefully. Once you decide it is just right move on to the next stage.
  
#### Apply
When you apply the code it deploys and provisions your infrastructure. Terraform also updates a deployment state tracking mechanism called a “state file”. This file will appear in your directory as **terraform.tfstate**. To apply the code enter the command **terraform apply**. You will be prompted to accept the actions that will be performed by Terraform, enter “yes”. It will take some time to provision your resources.
  
![image](https://user-images.githubusercontent.com/115881685/213711994-e5d42488-e7f9-4940-9f69-30adad797d7b.png)

  
 ![6](https://user-images.githubusercontent.com/115881685/213706085-361a7311-8b72-44f8-8535-073ecb440947.png)
  
 
 And it worked! Believe me this was not the first attempt, I had many errors. You can check out all of your newly created resources in the AWS console!
  
 ![5](https://user-images.githubusercontent.com/115881685/213712556-152aa809-624e-4b5a-aba2-86a7b8bcff59.png)
 ![7](https://user-images.githubusercontent.com/115881685/213712823-138256f0-4e31-4570-b86c-2ac26b3ec1f1.png)
 ![8](https://user-images.githubusercontent.com/115881685/213712933-1b76d1fe-fd26-4adf-86d0-641db7994b08.png)
 ![9](https://user-images.githubusercontent.com/115881685/213713061-22324b8d-802e-4dfa-ac78-458f3aa356a4.png)
                                     Target for ALB with 2 healthy instances
 ![rds](https://user-images.githubusercontent.com/115881685/213713729-33bff9f0-5617-4824-8b51-947acabdc570.png)
 ![rds1](https://user-images.githubusercontent.com/115881685/213713845-ca3c8af6-b8d1-4813-bdec-920bc0f75180.png)
 ![rds2](https://user-images.githubusercontent.com/115881685/213713942-e796c27d-d145-4161-8f8d-5b001ebf6cbf.png)

 

  


 
