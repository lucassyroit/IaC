resource "aws_db_subnet_group" "subnet_group_east" {
  name       = "main"
  subnet_ids = module.vpc-east.private_subnets

  tags = {
    Name = "My DB subnet group"
  }
}

# Creating a database instance in us-east
resource "aws_db_instance" "db-east-1a" {
  provider                = aws
  identifier              = "db-east-1a"
  allocated_storage       = 10
  max_allocated_storage   = 25
  db_name                 = "phpbb"
  engine                  = "mysql"
  engine_version          = "5.7"
  instance_class          = "db.t3.micro"
  username                = var.rds_username
  password                = var.rds_password
  parameter_group_name    = "default.mysql5.7"
  skip_final_snapshot     = true
  backup_retention_period = 7
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]

  db_subnet_group_name = aws_db_subnet_group.subnet_group_east.name

  publicly_accessible = false
  availability_zone   = "us-east-1a"

  tags = {
    Name = "db-east-1a"
  }
}