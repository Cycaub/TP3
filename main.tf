#Le reseau global
resource "aws_vpc" "VPC_main" {
  cidr_block       = var.vpc_cidr

  tags = {
    Name = "VPC_Main"
  }
}
#Deux subnet privé 10.0.1-2.0/24
resource "aws_subnet" "subnet1001private" {
  vpc_id     = aws_vpc.VPC_main.id
  cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

  tags = {
    Name = "subnet_10.0.1.0/24"
  }
}
resource "aws_subnet" "subnet1002private" {
  vpc_id     = aws_vpc.VPC_main.id
  cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1b"

  tags = {
    Name = "subnet_10.0.2.0/24"
  }
}
#Deux subnet public 10.0.3-4.0/24
resource "aws_subnet" "subnet1003public" {
  vpc_id     = aws_vpc.VPC_main.id
  cidr_block = "10.0.3.0/24"
    availability_zone = "us-east-1a"

  tags = {
    Name = "subnet_10.0.3.0/24"
  }
}
resource "aws_subnet" "subnet1004public" {
  vpc_id     = aws_vpc.VPC_main.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "subnet_10.0.4.0/24"
  }
}

#Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.VPC_main.id
  
  tags = {
    Name = "internet_gateway"
}
}
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.VPC_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public_Route_Table"
  }
}

#Association au subnet 10.0.3.0
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1003public.id
  route_table_id = aws_route_table.public_rt.id
}

#Association au subnet 10.0.4.0
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet1004public.id
  route_table_id = aws_route_table.public_rt.id
}
#Allocation d'une Elastic IP pour la NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "NAT_EIP"
  }
}

#Création de la NAT Gateway (placée dans le subnet public 10.0.3.0)
resource "aws_nat_gateway" "main_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.subnet1003public.id # On la met dans un subnet public

  tags = {
    Name = "Main_NAT_Gateway"
  }

#Pour s'assurer du bon ordre de création, on attend que l'IGW soit prête
  depends_on = [aws_internet_gateway.igw]
}

#Table de routage pour les subnets privés
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.VPC_main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main_nat.id
  }

  tags = {
    Name = "Private_Route_Table"
  }
}

#Association de la table aux deux subnets privés
resource "aws_route_table_association" "pri_assoc_1" {
  subnet_id      = aws_subnet.subnet1001private.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "pri_assoc_2" {
  subnet_id      = aws_subnet.subnet1002private.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Group pour le Load Balancer
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
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
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group pour les serveurs Web
resource "aws_security_group" "web_sg" {
  name   = "web-sg"
  vpc_id = aws_vpc.VPC_main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "web_server_1" {
  ami           = "ami-0f3caa1cf4417e51b" 
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet1001private.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data_base64 = base64encode("${path.module}/user_data.sh")
  user_data_replace_on_change = true
  
  tags = {
    Name = "Web_Server_CESI_1"
  }
}

resource "aws_instance" "web_server_2" {
  ami           = "ami-0f3caa1cf4417e51b"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet1002private.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data_base64 = base64encode("${path.module}/user_data.sh")
  user_data_replace_on_change = true 

  tags = {
    Name = "Web_Server_CESI_2"
  }
}
# Création de l'ALB
resource "aws_lb" "main_alb" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.subnet1003public.id, aws_subnet.subnet1004public.id]
}

# Target Group (Le groupe de destination)
resource "aws_lb_target_group" "web_tg" {
  name     = "web-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.VPC_main.id
}

# Attachement des instances au Target Group
resource "aws_lb_target_group_attachment" "tg_attach_1" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tg_attach_2" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server_2.id
  port             = 80
}

# Listener (L'écouteur qui reçoit le trafic 0.0.0.0/0)
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}