provider "aws" {
  region = var.aws_region
  profile = "default"
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


resource "aws_security_group" "backend_sg" {
  name        = "backend-sg-${var.env}"
  vpc_id      = data.aws_vpc.default.id
  description = "Allow HTTP traffic to backend"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open for demo; restrict in prod
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
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

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "backend_task" {
  family                   = "backend-task-${var.env}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend-app"
      image     = "${aws_ecr_repository.backend_repo.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "backend_service" {
   name            = "backend-service-${var.env}"
   cluster         = aws_ecs_cluster.app_cluster.id
   task_definition = aws_ecs_task_definition.backend_task.arn
   launch_type     = "FARGATE"
   desired_count   = 1

   network_configuration {
     subnets          = [
       data.aws_subnets.default.ids[0],
       data.aws_subnets.default.ids[1],
       data.aws_subnets.default.ids[2]
     ]
     assign_public_ip = true
     security_groups  = [aws_security_group.backend_sg.id]
   }

   deployment_minimum_healthy_percent = 50
   deployment_maximum_percent         = 200
 }
