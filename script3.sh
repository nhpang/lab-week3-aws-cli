#!/usr/bin/env bash

set -eu

# Variables
region="us-west-2"
vpc_cidr="10.0.0.0/16"
subnet_cidr="10.0.1.0/24"
key_name="bcitkey"

# Create VPC
vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr --query 'Vpc.VpcId' --output text --region $region)
aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=MyVPC --region $region

# enable dns hostname
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-hostnames Value=true

# Create public subnet
subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id \
  --cidr-block $subnet_cidr \
  --availability-zone ${region}a \
  --query 'Subnet.SubnetId' \
  --output text --region $region)

aws ec2 create-tags --resources $subnet_id --tags Key=Name,Value=PublicSubnet --region $region

# Create internet gateway
igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
  --output text --region $region)

aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id --region $region

# Create route table
route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id \
  --query 'RouteTable.RouteTableId' \
  --region $region \
  --output text)

# Associate route table with public subnet
aws ec2 associate-route-table --subnet-id $subnet_id --route-table-id $route_table_id --region $region

# Create route to the internet via the internet gateway
aws ec2 create-route --route-table-id $route_table_id \
  --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id --region $region

# Write infrastructure data to a file
echo "vpc_id=${vpc_id}" > infrastructure_data
echo "subnet_id=${subnet_id}" >> infrastructure_data

region="us-west-2"
key_name="bcitkey"

source ./infrastructure_data

# Get Ubuntu 23.04 image id owned by amazon
ubuntu_ami=$(aws ec2 describe-images --region $region \
 --owners amazon \
 --filters Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-lunar-23.04-amd64-server* \
 --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text)

# Create security group allowing SSH and HTTP from anywhere
security_group_id=$(aws ec2 create-security-group --group-name MySecurityGroup \
 --description "Allow SSH and HTTP" --vpc-id $vpc_id --query 'GroupId' \
 --region $region \
 --output text)

aws ec2 authorize-security-group-ingress --group-id $security_group_id \
 --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $region

aws ec2 authorize-security-group-ingress --group-id $security_group_id \
 --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $region

# Launch an EC2 instance in the public subnet
# COMPLETE THIS PART
instance_id=$(aws ec2 run-instances \
 --image-id $ubuntu_ami \
 --count 1 \
 --instance-type t2.micro \
 --key-name $key_name \
 --security-group-ids $security_group_id \
 --subnet-id $subnet_id \
 --query 'Instances[0].InstanceId' \
 --region $region \
 --output text)

# Wait for EC2 instance to be running
aws ec2 wait instance-running --instance-ids $instance_id --region $region

# Get the public IP address of the EC2 instance
# COMPLETE THIS PART
public_ip=$(aws ec2 describe-instances \
 --instance-ids $instance_id \
 --query 'Reservations[0].Instances[0].PublicIpAddress' \
 --region $region \
 --output text)

# Write instance data to a file
# COMPLETE THIS PART
echo "Public IP: $public_ip" > instance_data.txt