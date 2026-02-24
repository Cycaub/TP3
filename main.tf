# --- DÉCLARATION DES VARIABLES --- 
variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block pour le VPC"
}

variable "client" {
  type        = string
  description = "Nom du client (passé par Jenkins)"
}

variable "env" {
  type        = string
  description = "Environnement (passé par Jenkins)"
}

# --- RESSOURCES ---

# Le reseau global 
resource "aws_vpc" "VPC_main" {
  cidr_block       = var.vpc_cidr

  tags = {
    Name        = "VPC_Main_${var.client}"
    Environment = var.env
  }
}

# Deux subnet privé 10.0.1-2.0/24 
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

# Deux subnet public 10.0.3-4.0/24 [cite: 1, 2]
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

# Internet Gateway [cite: 2]
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
    gateway_id = aws_internet_gateway.igw.id [cite: 3]
  }

  tags = {
    Name = "Public_RT_${var.env}"
  }
}

# Associations Route Table Public [cite: 3]
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1003public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet1004public.id
  route_table_id = aws_route_table.public_rt.id
}

# NAT Gateway & EIP [cite: 3, 4]
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "NAT_EIP_${var.client}"
  }
}

resource "aws_nat_gateway" "main_nat" {
  allocation_id = aws_eip.nat_eip.id [cite: 4]
  subnet_id     = aws_subnet.subnet1003public.id

  tags = {
    Name = "Main_NAT_${var.env}"
  }
  depends_on = [aws_internet_gateway.igw]
}

# Table de routage privée [cite: 4]
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

# Associations Route Table Privée [cite: 5]
resource "aws_route_table_association" "pri_assoc_1" {
  subnet_id      = aws_subnet.subnet1001private.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "pri_assoc_2" {
  subnet_id      = aws_subnet.subnet1002private.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Groups [cite: 5, 6]
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
    to_port     = 0 [cite: 6]
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_sg" {
  name   = "web-sg-${var.env}"
  vpc_id = aws_vpc.VPC_main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0 [cite: 7]
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Instances EC2 [cite: 7, 8]
resource "aws_instance" "web_server_1" {
  ami                         = "ami-0f3caa1cf4417e51b" [cite: 7]
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet1001private.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  user_data_base64            = base64encode("${path.module}/user_data.sh")
  user_data_replace_on_change = true
  
  tags = {
    Name = "Web_Server_${var.client}_1_${var.env}"
  }
}

resource "aws_instance" "web_server_2" {
  ami                         = "ami-0f3caa1cf4417e51b" [cite: 8]
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet1002private.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  user_data_base64            = base64encode("${path.module}/user_data.sh")
  user_data_replace_on_change = true 

  tags = {
    Name = "Web_Server_${var.client}_2_${var.env}"
  }
}

# Load Balancer & Target Group [cite: 8, 9, 10]
resource "aws_lb" "main_alb" {
  name               = "alb-${var.client}-${var.env}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.subnet1003public.id, aws_subnet.subnet1004public.id] [cite: 9]
}

resource "aws_lb_target_group" "web_tg" {
  name     = "tg-${var.client}-${var.env}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.VPC_main.id
}

resource "aws_lb_target_group_attachment" "tg_attach_1" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tg_attach_2" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server_2.id
  port             = 80 [cite: 10]
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}