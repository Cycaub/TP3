# Le reseau global
resource "aws_vpc" "VPC_main" {
  cidr_block       = var.vpc_cidr

  tags = {
    Name        = "VPC_Main_${var.client}"
    Environment = var.env
  }
}

# Subnets privés
resource "aws_subnet" "subnet1001private" {
  vpc_id            = aws_vpc.VPC_main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet_private_1_${var.env}"
  }
}

resource "aws_subnet" "subnet1002private" {
  vpc_id            = aws_vpc.VPC_main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "subnet_private_2_${var.env}"
  }
}

# Subnets publics
resource "aws_subnet" "subnet1003public" {
  vpc_id            = aws_vpc.VPC_main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet_public_1_${var.env}"
  }
}

resource "aws_subnet" "subnet1004public" {
  vpc_id            = aws_vpc.VPC_main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "subnet_public_2_${var.env}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.VPC_main.id
  
  tags = {
    Name = "igw_${var.client}"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.VPC_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public_RT_${var.env}"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1003public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet1004public.id
  route_table_id = aws_route_table.public_rt.id
}

# NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "NAT_EIP_${var.client}"
  }
}

resource "aws_nat_gateway" "main_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.subnet1003public.id

  tags = {
    Name = "Main_NAT_${var.env}"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.VPC_main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main_nat.id
  }

  tags = {
    Name = "Private_RT_${var.env}"
  }
}

resource "aws_route_table_association" "pri_assoc_1" {
  subnet_id      = aws_subnet.subnet1001private.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "pri_assoc_2" {
  subnet_id      = aws_subnet.subnet1002private.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Groups
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg-${var.env}"
  vpc_id = aws_vpc.VPC_main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol