provider "aws" {
  region = "us-east-1"
  alias  = "east"
}

# Additional provider configuration for west coast region; resources can
# reference this as `aws.west`.
provider "aws" {
  alias  = "west"
  region = "us-west-1"
}

resource "aws_vpc" "east-vpc" {
  provider             = aws.east
  cidr_block           = "172.3.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "route53-east"
  }
}

resource "aws_vpc" "west-vpc" {
  provider             = aws.west
  cidr_block           = "172.9.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "route53-west"
  }
}

resource "aws_subnet" "east-1a" {
  provider          = aws.east
  vpc_id            = aws_vpc.east-vpc.id
  cidr_block        = "172.3.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "r53-lab-1a"
  }
}

resource "aws_subnet" "east-1b" {
  provider          = aws.east
  vpc_id            = aws_vpc.east-vpc.id
  cidr_block        = "172.3.1.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "r53-lab-1b"
  }
}

resource "aws_subnet" "west-1a" {
  provider          = aws.west
  vpc_id            = aws_vpc.west-vpc.id
  cidr_block        = "172.9.0.0/24"
  availability_zone = "us-west-1a"

  tags = {
    Name = "r53-lab-1a"
  }
}

resource "aws_subnet" "west-1c" {
  provider          = aws.west
  vpc_id            = aws_vpc.west-vpc.id
  cidr_block        = "172.9.1.0/24"
  availability_zone = "us-west-1c"

  tags = {
    Name = "r53-lab-1c"
  }
}

resource "aws_internet_gateway" "east-igw" {
  provider = aws.east
  vpc_id   = aws_vpc.east-vpc.id

  tags = {
    Name = "r53-lab-igw"
  }
}

resource "aws_internet_gateway" "west-igw" {
  provider = aws.west
  vpc_id   = aws_vpc.west-vpc.id

  tags = {
    Name = "r53-lab-igw"
  }
}

resource "aws_route_table" "east-rt" {
  provider = aws.east
  vpc_id   = aws_vpc.east-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.east-igw.id
  }

  tags = {
    Name = "r53-lab-rt"
  }
}

resource "aws_route_table" "west-rt" {
  provider = aws.west
  vpc_id   = aws_vpc.west-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.west-igw.id
  }

  tags = {
    Name = "r53-lab-rt"
  }
}

resource "aws_route_table_association" "east-route-a" {
  provider       = aws.east
  subnet_id      = aws_subnet.east-1a.id
  route_table_id = aws_route_table.east-rt.id
}

resource "aws_route_table_association" "east-route-b" {
  provider       = aws.east
  subnet_id      = aws_subnet.east-1b.id
  route_table_id = aws_route_table.east-rt.id
}

resource "aws_route_table_association" "west-route-a" {
  provider       = aws.west
  subnet_id      = aws_subnet.west-1a.id
  route_table_id = aws_route_table.west-rt.id
}

resource "aws_route_table_association" "west-route-c" {
  provider       = aws.west
  subnet_id      = aws_subnet.west-1c.id
  route_table_id = aws_route_table.west-rt.id
}

resource "aws_security_group" "east-sg" {
  provider    = aws.east
  name        = "r53-lab-sg"
  description = "Route53 Lab Security Group"
  vpc_id      = aws_vpc.east-vpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from my PC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [""]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "r53-lab-sg"
  }
}

resource "aws_security_group" "west-sg" {
  provider    = aws.west
  name        = "r53-lab-sg"
  description = "Route53 Lab Security Group"
  vpc_id      = aws_vpc.west-vpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from my PC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["82.23.31.222/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "r53-lab-sg"
  }
}

resource "aws_instance" "web1-east" {
  provider                    = aws.east
  ami                         = "ami-c710e7bd"
  instance_type               = "t2.micro"
  private_ip                  = "172.3.0.10"
  vpc_security_group_ids      = [aws_security_group.east-sg.id]
  subnet_id                   = aws_subnet.east-1a.id
  key_name                    = "chukky"
  associate_public_ip_address = "true"
  user_data                   = <<-EOT
    #! /bin/bash
    sudo docker run --rm -p 80:80 benpiper/r53-ec2-web
  EOT
  tags = {
    Name = "web1-east"
  }
}

resource "aws_instance" "web2-east" {
  provider                    = aws.east
  ami                         = "ami-c710e7bd"
  instance_type               = "t2.micro"
  private_ip                  = "172.3.1.20"
  vpc_security_group_ids      = [aws_security_group.east-sg.id]
  subnet_id                   = aws_subnet.east-1b.id
  key_name                    = "chukky"
  associate_public_ip_address = "true"
  user_data                   = <<-EOT
    #! /bin/bash
    sudo docker run --rm -p 80:80 benpiper/r53-ec2-web
  EOT
  tags = {
    Name = "web2-east"
  }
}

resource "aws_instance" "db-east" {
  provider                    = aws.east
  ami                         = "ami-c710e7bd"
  instance_type               = "t2.micro"
  private_ip                  = "172.3.1.100"
  vpc_security_group_ids      = [aws_security_group.east-sg.id]
  subnet_id                   = aws_subnet.east-1b.id
  key_name                    = "chukky"
  associate_public_ip_address = "true"
  tags = {
    Name = "db-east"
  }
}

resource "aws_instance" "web1-west" {
  provider                    = aws.west
  ami                         = "ami-04424264"
  instance_type               = "t2.micro"
  private_ip                  = "172.9.0.10"
  vpc_security_group_ids      = [aws_security_group.west-sg.id]
  subnet_id                   = aws_subnet.west-1a.id
  key_name                    = "west-chukky"
  associate_public_ip_address = "true"
  user_data                   = <<-EOT
    #! /bin/bash
    sudo docker run --rm -p 80:80 benpiper/r53-ec2-web
  EOT
  tags = {
    Name = "web1-west"
  }
}

resource "aws_instance" "web2-west" {
  provider                    = aws.west
  ami                         = "ami-04424264"
  instance_type               = "t2.micro"
  private_ip                  = "172.9.1.20"
  vpc_security_group_ids      = [aws_security_group.west-sg.id]
  subnet_id                   = aws_subnet.west-1c.id
  key_name                    = "west-chukky"
  associate_public_ip_address = "true"
  user_data                   = <<-EOT
    #! /bin/bash
    sudo docker run --rm -p 80:80 benpiper/r53-ec2-web
  EOT
  tags = {
    Name = "web2-west"
  }
}

output "west-1-public-ip" {
  value = "http://${aws_instance.web1-west.public_ip}"
}
output "west-2-public-ip" {
  value = "http://${aws_instance.web2-west.public_ip}"
}

output "east-1-public-ip" {
  value = "http://${aws_instance.web1-east.public_ip}"
}
output "east-2-public-ip" {
  value = "http://${aws_instance.web2-east.public_ip}"
}

# sample query on bash $ aws ec2 describe-images --region us-west-1 --filters "Name=name,Values=aws-elasticbeanstalk-amzn-2017.09.1.x86_64-ecs-hvm-*" --query 'Images[*].[Name, ImageId]'

resource "aws_route53_delegation_set" "main" {
  reference_name = "1047874"
}

resource "aws_route53_zone" "primary" {
  name              = "emmanuelojeah.xyz."
  delegation_set_id = aws_route53_delegation_set.main.id
}

resource "aws_route53_record" "web1-east" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "web1-east.emmanuelojeah.xyz"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.web1-east.public_ip]
}

resource "aws_route53_record" "web2-east" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "web2-east.emmanuelojeah.xyz"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.web2-east.public_ip]
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.emmanuelojeah.xyz"
  type    = "A"
  alias {
    name                   = aws_route53_record.web2-east.name
    zone_id                = aws_route53_zone.primary.id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "apex" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = ""
  type    = "A"
  alias {
    name                   = aws_route53_record.www.name
    zone_id                = aws_route53_zone.primary.id
    evaluate_target_health = true
  }
}

output "caller-reference" {
  value = aws_route53_delegation_set.main.name_servers
}

output "delegation-setid" {
  value = aws_route53_delegation_set.main.id
}
