data "aws_ami" "ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "instance" {
  count                       = var.ec2_count
  ami                         = data.aws_ami.ami.id
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc-east.public_subnets[0]
  associate_public_ip_address = true

  security_groups = [aws_security_group.instance_sg.id]
  user_data       = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install mysql -y
    sudo yum install unzip -y

    export AWS_ACCESS_KEY_ID=${var.aws_access_key}
    export AWS_SECRET_ACCESS_KEY=${var.aws_secret_key}
    export AWS_SESSION_TOKEN=${var.aws_token}
    export AWS_DEFAULT_REGION="us-east-1"
    export AWS_DEFAULT_OUTPUT="json"

    aws s3 cp s3://${module.s3_bucket.s3_bucket_id}/loop.sh .
    aws s3 cp s3://${module.s3_bucket.s3_bucket_id}/sql.zip .
  
    sudo unzip sql.zip
    
    sudo chmod +x loop.sh
    sudo ./loop.sh ${var.rds_password} ${var.rds_username} ${aws_db_instance.db-east-1a.address}
    EOF

  depends_on = [module.vpc-east, module.s3_bucket]
}