provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_vpc" "main" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-WordPress"
  }
}

resource "aws_subnet" "public-a" {
  availability_zone       = "us-east-1a"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.11.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "WP-PublicSubnet-A"
  }
}

resource "aws_subnet" "private-a" {
  availability_zone = "us-east-1a"
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.12.0/24"
  tags = {
    Name = "WP-PrivateSubnet-A"
  }
}

resource "aws_subnet" "public-c" {
  availability_zone       = "us-east-1c"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.31.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "WP-PublicSubnet-C"
  }
}

resource "aws_subnet" "private-c" {
  availability_zone = "us-east-1c"
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.32.0/24"

  tags = {
    Name = "WP-PrivateSubnet-C"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "WP-InternetGateway"
  }
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "vpc-WordPress"
  }
}

resource "aws_main_route_table_association" "a" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.r.id
}

resource "aws_security_group" "app" {
  name        = "WP-Web-DMZ"
  description = "WordPress Web APP Security Group"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "WP-Web-DMZ"
  }
}

resource "aws_security_group" "db" {
  name        = "WP-DB"
  description = "WordPress MySQL Security Group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "WP-DB"
  }
}

resource "aws_security_group_rule" "ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "web" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "all" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "db" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.db.id
}

resource "aws_db_subnet_group" "dbsbg" {
  name        = "wp-db-subnet-group"
  description = "WordPress DB Subnet"
  subnet_ids  = ["${aws_subnet.private-a.id}", "${aws_subnet.private-c.id}"]
}

resource "aws_db_instance" "default" {
  identifier              = "wp-mysql"
  allocated_storage       = 5
  engine                  = "mysql"
  engine_version          = "8.0.36"
  instance_class          = "db.t3.micro"
  storage_type            = "gp2"
  username                = var.username
  password                = var.password
  skip_final_snapshot     = true
  apply_immediately       = true
  backup_retention_period = 0
  vpc_security_group_ids  = ["${aws_security_group.db.id}"]
  db_subnet_group_name    = aws_db_subnet_group.dbsbg.name
  lifecycle {
    ignore_changes = [password]
    # terraformではパスワード変更無視。セキュリティ観点からインスタンス構築手動でパスワードを変更するため。
  }
}

resource "aws_instance" "web" {
  ami                         = var.ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public-a.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.app.id]
  key_name                    = var.key_name
  tags                        = { Name = "WP-WebAPP" }

  provisioner "file" {
    source      = "prepareWordPress.sql"
    destination = "/home/ec2-user/prepareWordPress.sql"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = self.public_ip
      private_key = file("${var.ssh_key_file}")
    }

    # }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo dnf -y localinstall  https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm",
      "sudo dnf -y update",
      # "sudo dnf install php php-mysql php-gd php-mbstring -y",
      "sudo dnf install -y httpd wget php-fpm php-mysqli php-json php php-devel",
      "sudo dnf -y install mysql",
      # "sudo dnf -y install mysql-server mysql-community-client",
      "wget -O /tmp/wordpress-6.4-ja.tar.gz https://ja.wordpress.org/wordpress-6.4-ja.tar.gz",
      "sudo tar zxf /tmp/wordpress-6.4-ja.tar.gz -C /opt",
      "sudo ln -s /opt/wordpress /var/www/html/",
      "sudo chown -R apache:apache /opt/wordpress",
      "sudo systemctl enable httpd",
      "sudo killall -9 httpd",
      "sudo rm -f /var/lock/subsys/httpd",
      "sudo systemctl start httpd",
      # "sudo systemctl status httpd",
      "mysql -u ${var.username} -p${var.password} -h ${aws_db_instance.default.address} < /home/ec2-user/prepareWordPress.sql"
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = self.public_ip
      private_key = file(var.ssh_key_file)
    }
  }
}