# Le reseau global
resource "aws_vpc" "VPC_main" {
  cidr_block       = var.vpc_cidr [cite: 1]

  tags = {
    Name        = "VPC_Main_${var.client}"
    Environment = var.env
  }
}

# Subnets privés
resource "aws_subnet" "subnet1001private" {
  vpc_id            = aws_vpc.VPC_main.id [cite: 1]
  cidr_block        = "10.0.1.0/24" [cite: 1]
  availability_zone = "us-east-1a" [cite: 1]

  tags = {
    Name = "subnet_private_1_${var.env}"
  }
}

resource "aws_subnet" "subnet1002private" {
  vpc_id            = aws_vpc.VPC_main.id [cite: 1]
  cidr_block        = "10.0.2.0/24" [cite: 1]
  availability_zone = "us-east-1b" [cite: 1]

  tags = {
    Name = "subnet_private_2_${var.env}"
  }
}

# Subnets publics
resource "aws_subnet" "subnet1003public" {
  vpc_id            = aws_vpc.VPC_main.id [cite: 2]
  cidr_block        = "10.0.3.0/24" [cite: 2]
  availability_zone = "us-east-1a" [cite: 2]

  tags = {
    Name = "subnet_public_1_${var.env}"
  }
}

resource "aws_subnet" "subnet1004public" {
  vpc_id            = aws_vpc.VPC_main.id [cite: 2]
  cidr_block        = "10.0.4.0/24" [cite: 2]
  availability_zone = "us-east-1b" [cite: 2]

  tags = {
    Name = "subnet_public_2_${var.env}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.VPC_main.id [cite: 2]
  
  tags = {
    Name = "igw_${var.client}"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.VPC_main.id [cite: 2]

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
  allocation_id = aws_eip.nat_eip.id [cite: 4]
  subnet_id     = aws_subnet.subnet1003public.id [cite: 4]

  tags = {
    Name = "Main_NAT_${var.env}"
  }
  depends_on = [aws_internet_gateway.igw] [cite: 4]
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.VPC_main.id [cite: 4]

  route {
    cidr_block     = "0.0.0.0/0" [cite: 4]
    nat_gateway_id = aws_nat_gateway.main_nat.id [cite: 4]
  }

  tags = {
    Name = "Private_RT_${var.env}"
  }
}

resource "aws_route_table_association" "pri_assoc_1" {
  subnet_id      = aws_subnet.subnet1001private.id [cite: 5]
  route_table_id = aws_route_table.private_rt.id [cite: 5]
}

resource "aws_route_table_association" "pri_assoc_2" {
  subnet_id      = aws_subnet.subnet1002private.id [cite: 5]
  route_table_id = aws_route_table.private_rt.id [cite: 5]
}

# Security Groups
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg-${var.env}"
  vpc_id = aws_vpc.VPC_main.id [cite: 5]

  ingress {
    from_port   = 80 [cite: 5]
    to_port     = 80 [cite: 5]
    protocol    = "tcp" [cite: 5]
    cidr_blocks = ["0.0.0.0/0"] [cite: 5]
  }

  egress {
    from_port   = 0 [cite: 5]
    to_port     = 0 [cite: 6]
    protocol    = "-1" [cite: 6]
    cidr_blocks = ["0.0.0.0/0"] [cite: 6]
  }
}

resource "aws_security_group" "web_sg" {
  name   = "web-sg-${var.env}"
  vpc_id = aws_vpc.VPC_main.id [cite: 6]

  ingress {
    from_port       = 80 [cite: 6]
    to_port         = 80 [cite: 6]
    protocol        = "tcp" [cite: 6]
    security_groups = [aws_security_group.alb_sg.id] [cite: 6]
  }

  egress {
    from_port   = 0 [cite: 6]
    to_port     = 0 [cite: 7]
    protocol    = "-1" [cite: 7]
    cidr_blocks = ["0.0.0.0/0"] [cite: 7]
  }
}

# EC2 Instances
resource "aws_instance" "web_server_1" {
  ami                         = "ami-0f3caa1cf4417e51b" [cite: 7]
  instance_type               = "t2.micro" [cite: 7]
  subnet_id                   = aws_subnet.subnet1001private.id [cite: 7]
  vpc_security_group_ids      = [aws_security_group.web_sg.id] [cite: 7]
  user_data_base64            = base64encode("${path.module}/user_data.sh") [cite: 7]
  user_data_replace_on_change = true [cite: 7]
  
  tags = {
    Name = "Web_Server_${var.client}_1"
  }
}

resource "aws_instance" "web_server_2" {
  ami                         = "ami-0f3caa1cf4417e51b" [cite: 8]
  instance_type               = "t2.micro" [cite: 8]
  subnet_id                   = aws_subnet.subnet1002private.id [cite: 8]
  vpc_security_group_ids      = [aws_security_group.web_sg.id] [cite: 8]
  user_data_base64            = base64encode("${path.module}/user_data.sh") [cite: 8]
  user_data_replace_on_change = true [cite: 8]

  tags = {
    Name = "Web_Server_${var.client}_2"
  }
}

# ALB
resource "aws_lb" "main_alb" {
  name               = "alb-${var.env}"
  internal           = false [cite: 8]
  load_balancer_type = "application" [cite: 8]
  security_groups    = [aws_security_group.alb_sg.id] [cite: 8]
  subnets            = [aws_subnet.subnet1003public.id, aws_subnet.subnet1004public.id] [cite: 9]
}

resource "aws_lb_target_group" "web_tg" {
  name     = "tg-${var.env}"
  port     = 80 [cite: 9]
  protocol = "HTTP" [cite: 9]
  vpc_id   = aws_vpc.VPC_main.id [cite: 9]
}

resource "aws_lb_target_group_attachment" "tg_attach_1" {
  target_group_arn = aws_lb_target_group.web_tg.arn [cite: 9]
  target_id        = aws_instance.web_server_1.id [cite: 9]
  port             = 80 [cite: 9]
}

resource "aws_lb_target_group_attachment" "tg_attach_2" {
  target_group_arn = aws_lb_target_group.web_tg.arn [cite: 9]
  target_id        = aws_instance.web_server_2.id [cite: 10]
  port             = 80 [cite: 10]
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.main_alb.arn [cite: 10]
  port              = "80" [cite: 10]
  protocol          = "HTTP" [cite: 10]

  default_action {
    type             = "forward" [cite: 10]
    target_group_arn = aws_lb_target_group.web_tg.arn [cite: 10]
  }
}