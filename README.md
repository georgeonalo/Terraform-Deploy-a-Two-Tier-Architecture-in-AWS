# Terraform-Deploy-a-Two-Tier-Architecture-in-AWS

![image](https://user-images.githubusercontent.com/115881685/213696496-132ed366-59a4-4f81-97d1-45e4e694b06d.png)

In this project, we will dive into Terraform. Terraform is a open-source Infrastructure as code tool. It enables you to build, change, and version resources in the cloud. You can work with multiple clouds using Terraform. For this article, we will be focusing on the AWS cloud. We will architect a 2-Tier Architecture that consists of the following:

*A VPC with 2 public subnets and 2 private subnets.

*A load balancer that will direct traffic to the public subnets and 1 EC2
instance in each public subnet.

*An RDS MySQL instance in one of the subnets.
