# Set a provider
# Configure the AWS Provider
provider "aws" {
  region  = "eu-west-1"
}

# Create VPC
resource "aws_vpc" "app_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.name} - VPC"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "app_gw" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "${var.name} - igw"
  }
}

# Create subnet
resource "aws_subnet" "app_subnet" {
  vpc_id = aws_vpc.app_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "${var.name} - subnet"
  }
}

# Create route table
resource "aws_route_table" "app_route_table" {
  vpc_id = aws_vpc.app_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_gw.id
  }
  tags = {
    Name = "${var.name} - route"
  }
}

# Route table associations
resource "aws_route_table_association" "app_assoc" {
  subnet_id = aws_subnet.app_subnet.id
  route_table_id = aws_route_table.app_route_table.id
}

# Create security groups
resource "aws_security_group" "app_security_group" {
  name = var.name
  description = "Allow inbound traffic on port 80"
  vpc_id = aws_vpc.app_vpc.id
  ingress {
    from_port = 80
    to_port = 80
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.name} - sg"
  }
}

# Send template to sh file
data "template_file" "app_init" {
  template = "${file("./scripts/init_script.sh.tpl")}"
}

# Launch an instance
resource "aws_instance" "app_instance" {
  ami           = var.ami_id
  subnet_id = aws_subnet.app_subnet.id
  vpc_security_group_ids = [aws_security_group.app_security_group.id]
  instance_type = "t2.micro"
  associate_public_ip_address = true
  user_data = data.template_file.app_init.rendered
  tags = {
    Name = "${var.name} - instance"
  }
}
