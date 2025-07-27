# Terraform configuration file for AWS VPC
provider "aws" {
  region = "us-west-2"
}
# create VPC 
resource "aws_vpc" "MyVPC" {
  cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "website_vpc"
    }   
}

#create a subnet
resource "aws_subnet" "MySubnet" {
  vpc_id            = aws_vpc.MyVPC.id
  cidr_block        = "10.0.0.0/16"
  availability_zone = "us-west-2a"  
  map_public_ip_on_launch = true
  tags = {
    Name = "website_subnet"
  }
}

# create an internet gateway
resource "aws_internet_gateway" "MyInternetGateway" {
  vpc_id = aws_vpc.MyVPC.id
  tags = {
    Name = "website_gateway"
  }
}
# create a route table
resource "aws_route_table" "MyRouteTable" {
  vpc_id = aws_vpc.MyVPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.MyInternetGateway.id  
  }  
}

resource "aws_route_table_association" "MyRouteTableSubnetAssociation" {
    subnet_id      = aws_subnet.MySubnet.id
    route_table_id = aws_route_table.MyRouteTable.id
    # Associate the route table with the subnet
    # This allows the subnet to use the route table for routing traffic
    # to the internet gateway  
}

# create 4 ec2 instances
resource "aws_instance" "MyInstances" {
  count         = 4
  ami           = "ami-0c55b159cbfafe1f0" #AMI ID for Ubantu Server
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.MySubnet.id
  associate_public_ip_address = true

  tags = {
    Name = "web_server_${count.index + 1}"
  }

  # Optional: Add a security group to allow HTTP traffic
  vpc_security_group_ids = [aws_security_group.MySecurityGroup.id]

  ## Security_groups = ["MySecurityGroup"] 
}

#create a security group
resource "aws_security_group" "MySecurityGroup" {
  vpc_id = aws_vpc.MyVPC.id
  description = "Security group for web servers"

  tags = {
    Name = "MyProjectSG"
  } 
  ingress {
    description = "Allow SSH traffic"
    from_port   = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic

  }

 }