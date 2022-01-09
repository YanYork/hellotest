/*Cloud provider*/
#++++++++++++++++++
provider "aws"{
region = "us-east-2"
}

/*project vpc*/
#+++++++++++++++
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags   = {
    Name = "main"
  }
}

/*Public Subnet*/
#+++++++++++++++++
resource "aws_subnet" "main_public_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2b"
  tags   = {
    Name = "Main_Public_Subnet"
  }
}

/*Private subnet*/
#++++++++++++++++++
resource "aws_subnet" "main_private_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-2a"
  tags   = {
    Name = "Main_Private_Subnet"
  }
}

/*VPC Internet gateway*/
#++++++++++++++++++++++++
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = {
    Name = "main"
  }
}

/*Route table for public subnet */
#++++++++++++++++++++++++++++++++++
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

   route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }
  tags   = {
    Name = "Public_Route_Table"
  }
}

/*Attached route table to subnet */
#+++++++++++++++++++++++++++++++++++
resource "aws_route_table_association" "Main_public_Assoc"{
    subnet_id      = aws_subnet.main_public_subnet.id
    route_table_id = aws_route_table.public_rt.id
}

/*Main SG*/
#++++++++++
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
 }

 ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
 }

 ingress {
    description = "TLS from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
 }

 ingress {
    description = "TLS from VPC"
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

 tags    = {
    Name = "allow_tls"
  }
}

/*Create key pair for loggin into ec2*/
#++++++++++++++++++++++++++++++++++++++
resource "aws_key_pair" "project_key"{
  key_name   = "mywebserver"
  public_key = file(var.ssh_key_public)
}

/*Create ec2 instance*/
#++++++++++++++++++++++
resource "aws_instance" "main"{
    instance_type               = "t2.micro"
    ami                         = "ami-0fb653ca2d3203ac1"
    vpc_security_group_ids      = [aws_security_group.allow_tls.id] 
    subnet_id                   = aws_subnet.main_public_subnet.id
    associate_public_ip_address = true
    iam_instance_profile        = "${aws_iam_instance_profile.EC2_role_profile.name}"
    key_name                    = aws_key_pair.project_key.key_name

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt upgrade -y",
      "sudo apt full-upgrade -y",
      "sudo apt install mysql-client-core-8.0 -y",
      "sudo apt install python3-pip -y",
      "sudo apt install python3-flask -y",
      "sudo apt install python3-pymysql -y",
      "sudo apt install python3-boto3 -y",
      "git clone https://github.com/hshar94/aws-live.git",
    ]
  }
    connection {
       type        = "ssh"
       user        = "ubuntu"
       private_key = file(var.ssh_key_private)
       host        = self.public_ip 
    }   
 tags    = {
    Name = "Main_Project_Instance"
    }
}

/*Create S3 bucket*/
#+++++++++++++++++++
resource "aws_s3_bucket" "main" {
  bucket   = "my-project-bucket7412"
  acl      = "private"
  tags     = {
      Name = "My_main_Bucket"
  }
}

/*Create EC2 IAM role */
#+++++++++++++++++++++++
resource "aws_iam_role" "ec2_main_role" {
  name = "EC2_Admin_Access_S3"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags      = {
    tag-key = "EC2_FullAcess_S3"
  }
}

/*Create EC2 Instance profile*/
#+++++++++++++++++++++++++++++
resource "aws_iam_instance_profile" "EC2_role_profile" {
  name = "EC2_Profile"
  role = "${aws_iam_role.ec2_main_role.id}"
}

/*EC2 Admin Access Policy */
#+++++++++++++++++++++++++++
resource "aws_iam_role_policy" "EC2_policy" {
  name = "EC2_S3_policy"
  role = "${aws_iam_role.ec2_main_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

/*DB Subnet group*/
#++++++++++++++++++
resource "aws_db_subnet_group" "main" {
    name        = "db subnets"
    subnet_ids  = [aws_subnet.main_public_subnet.id,aws_subnet.main_private_subnet.id]
    description = "db subnets for db instance"
    tags   = {
      Name = "Database Subnets"
    }
  }

/*Create DB*/
#++++++++++++
resource "aws_db_instance" "main" {
  allocated_storage     = 10
  engine                = "mysql"
  engine_version        = "5.7"
  instance_class        = "db.t3.micro"
  name                  = "mydb"
  username              = "pro"
  password              = "Password1"
  parameter_group_name  = "default.mysql5.7"
  skip_final_snapshot   = true
  multi_az              = false
 identifier             = "mysql157db"
 db_subnet_group_name   = aws_db_subnet_group.main.name
 vpc_security_group_ids = [aws_security_group.allow_tls.id]
 publicly_accessible    = true
 
}