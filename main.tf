# aws vpc
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "main-vpc"
  }
}

# aws public subnet
resource "aws_subnet" "pub_sub" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public_subnet"
  }
}

# Private Subnet 1 for postgresql
resource "aws_subnet" "private_sub" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Private_subnet"
  }
}
# aws private subnet 2 for postgresql

resource "aws_subnet" "private_sub2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "Private_subnet2"
  }
}


# aws internet gatway
resource "aws_internet_gateway" "gw_strapi" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "IG"
  }
}

# Elastic IP
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# NAT gateway for private subnet

resource "aws_nat_gateway" "nat_net" {
  allocation_id                  = aws_eip.nat_eip.id
  subnet_id                      = aws_subnet.pub_sub.id

  tags = {
    Name = "nat_gateway"
  }
}

# aws route table

resource "aws_route_table" "pub_route1" {
  vpc_id                  = aws_vpc.main.id

  route {
    cidr_block            = "0.0.0.0/0"
    gateway_id            = aws_internet_gateway.gw_strapi.id
  }
  tags = {
    Name = "public-route-table"
  }
}

# aws subnet association
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.pub_sub.id
  route_table_id = aws_route_table.pub_route1.id
}

# Private route table

resource "aws_route_table" "private_route1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_net.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# aws subnet association
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.private_sub.id
  route_table_id = aws_route_table.private_route1.id
}

# Private route table 2

resource "aws_route_table" "private_route2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_net.id
  }

  tags = {
    Name = "private-route-table2"
  }
}

# aws subnet association
resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.private_sub2.id
  route_table_id = aws_route_table.private_route2.id
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

# aws security group for private subnet

resource "aws_security_group" "private_sg" {
  name                      = "private-sg"
  description               = "Allow web and ssh traffic"
  vpc_id                    = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks  = ["10.0.2.0/24"]
  }

  tags = {
    tag-key = "private_sg"
  }
}

#-------------------------
# create a s3 bucket
resource "aws_s3_bucket" "strapi_bucket" {
  bucket = "strapi-s3-bucket-2811"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

# iam role
resource "aws_iam_role" "ec2_role" {
  name = "ec2Access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}
# iam role policy
resource "aws_iam_policy" "ec2_s3_policy" {
  name = "strapi-ec2-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:*"]
        Resource = [
          aws_s3_bucket.strapi_bucket.arn,
          "${aws_s3_bucket.strapi_bucket.arn}/*"
        ]
      }
    ]
  })
}

# attach iam policy to role
resource "aws_iam_role_policy_attachment" "ec2_s3_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}

# aws instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "strapi-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

#----------------------------
resource "aws_db_subnet_group" "db_subnet" {
  name       = "strapi-db-subnet"
  subnet_ids = [aws_subnet.private_sub.id, aws_subnet.private_sub2.id]
}

# RDS PostgreSql
resource "aws_db_instance" "postgresql" {
  identifier              = "strapi-db"
  engine                  = "postgres"
  allocated_storage       = 20
  engine_version          =  "17.6"
  instance_class          = "db.t3.micro"
  name                    = "strapi"
  username                = "strapi"
  password                = "strapi6734!"
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids  = [aws_security_group.private_sg.id]

  tags = {
    Name = "Strapi-databaseserver"
  }
}


# user data values

data "template_file" "userdata" {
  template = file("${path.module}/userData.sh")

  vars = {
    db_host     = aws_db_instance.postgresql.address
    db_name     = "strapi"
    db_user     = "strapi"
    db_password = "strapi6734!"
    s3_bucket   = aws_s3_bucket.strapi_bucket.bucket
    region      = "us-east-1"
  }
}


resource "aws_instance" "strapi-production" {
  ami                    = "ami-0ecb62995f68bb549"
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.pub_sub.id
  key_name               = "Connection"
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_size = 20 
    volume_type = "gp3"
    delete_on_termination = true
  }

  user_data = data.template_file.userdata.rendered

  tags = {
    Name = "Strapi-Server"
  }
}
