provider "aws" {
  region = var.aws_region
  profile = "default"
}

data "aws_vpc" "default" {
  default = true
}

# Lookup the default route table
data "aws_route_table" "default_rt" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name   = "association.main"
    values = ["true"]
  }
}

resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "multi-env-frontend-testing-${var.env}"
  force_destroy = true
}

# Create 3 public subnets in different AZs
resource "aws_subnet" "subnet_a" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = cidrsubnet(data.aws_vpc.default.cidr_block, 8, 1) # 1st subnet
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1a"
  }
}

resource "aws_security_group" "mysql_sg" {
  name        = "mysql-onprem-sg"
  description = "Allow SSH and MySQL access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open for demo; restrict in prod
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open for testing; adjust in prod
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Associate the subnet with the default route table
resource "aws_route_table_association" "default_subnet_assoc" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = data.aws_route_table.default_rt.id
}

# resource "aws_instance" "backend_instance" {
#   ami                    = var.ami_id
#   instance_type          = var.instance_type
#   key_name               = var.key_name
#   subnet_id              = aws_subnet.subnet_a.id 
#   vpc_security_group_ids = [aws_security_group.mysql_sg.id]

#   depends_on = [aws_route_table_association.default_subnet_assoc]

#   tags = {
#     Name = "backend-${var.env}"
#   }
# }

resource "aws_ecr_repository" "backend_repo" {
  name = "multi-env-backend-${var.env}"
}

resource "aws_ecs_cluster" "app_cluster" {
  name = "multi-env-cluster-${var.env}"
}
