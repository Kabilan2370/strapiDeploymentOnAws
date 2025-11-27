# aws vpc
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "main"
  }
}

# aws public subnet
resource "aws_subnet" "pub-sub" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-subnet"
  }
}
# aws internet gatway
resource "aws_internet_gateway" "gw-strapi" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "IG"
  }
}

# aws route table

resource "aws_route_table" "route1" {
  vpc_id                  = aws_vpc.main.id

  route {
    cidr_block            = "0.0.0.0/0"
    gateway_id            = aws_internet_gateway.gw-strapi.id
  }
  tags = {
    Name = "route-table-one"
  }
}

# aws subnet association
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.pub-sub.id
  route_table_id = aws_route_table.route1.id
}

# aws security group
resource "aws_security_group" "public_sg" {
  name                      = "public-sg"
  description               = "Allow web and ssh traffic"
  vpc_id                    = aws_vpc.main.id

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
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
# Subnet for postgresql
resource "aws_db_subnet_group" "db_subnet" {
  name       = "strapi-db-subnet"
  subnet_ids = [aws_subnet.public.id]
}

# RDS PostgreSql
resource "aws_db_instance" "postgresql" {

  cluster_identifier      = "aurora-cluster-strapi"
  engine                  = "aurora-postgresql"
  engine-version          =  17
  instance-class          = "db.t3.micro"
  availability_zones      = ["us-east-1a", "us-east-1b", "us-east-1c"]
  database_name           = "mydata"
  master_username         = "strapi"
  master_password         = "strapi6734!"
  publicly_accessible     = true
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids  = [aws_security_group.public_sg.id]
}

# user data values

data "template_file" "userdata" {
  template = file("${path.module}/userData.sh")

  vars = {
    db_host     = aws_db_instance.postgresql.address
    db_name     = "mydata"
    db_user     = "strapi"
    db_password = "strapi6734"
  }
}

resource "aws_instance" "strapi-production" {
  ami                    = "ami-0ecb62995f68bb549"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.pubsub.id
  key_name               = "Connection"
  vpc_security_group_ids = [aws_security_group.public_sg.id]

  user_data = data.template_file.userdata.rendered

  tags = {
    Name = "Strapi-Server"
  }
}
