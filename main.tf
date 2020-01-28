# Set a provider
# Configure the AWS Provider
provider "aws" {
  region  = "eu-west-1"
}

# Create VPC
resource "aws_vpc" "python_app_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.name} - VPC"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "python_app_gw" {
  vpc_id = aws_vpc.python_app_vpc.id
  tags = {
    Name = "${var.name} - igw"
  }
}

# Create subnet
resource "aws_subnet" "python_app_subnet" {
  vpc_id = aws_vpc.python_app_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "${var.name} - subnet"
  }
}

# Create route table
resource "aws_route_table" "python_app_rt" {
  vpc_id = aws_vpc.python_app_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.python_app_gw.id
  }
  tags = {
    Name = "${var.name} - route"
  }
}

# Route table associations
resource "aws_route_table_association" "python_app_assoc" {
  subnet_id = aws_subnet.python_app_subnet.id
  route_table_id = aws_route_table.python_app_rt.id
}

# Create security groups
resource "aws_security_group" "python_app_sg" {
  name = var.name
  description = "Allow inbound traffic on port 22 on Sparta IP and home IP"
  vpc_id = aws_vpc.python_app_vpc.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = ["212.161.55.68/32", "95.147.223.154/32"]
  }
  tags = {
    Name = "${var.name} - sg"
  }
}

# Send template to sh file
data "template_file" "python_app_init" {
  template = "${file("./scripts/init_script.sh.tpl")}"
}

# Launch an instance
resource "aws_instance" "python_app_instance" {
  ami           = var.ami_id
  subnet_id = aws_subnet.python_app_subnet.id
  vpc_security_group_ids = [aws_security_group.python_app_sg.id]
  instance_type = "t2.micro"
  associate_public_ip_address = true
  key_name = "shireen-eng-48-first-key"
  user_data = data.template_file.python_app_init.rendered
  tags = {
    Name = "${var.name} - instance"
  }
}
