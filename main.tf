provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "terraformstate-1234"
    key            = "ansible/terraform.tfstate"
    region         = "us-east-1"
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  key_name      = "bayer"

  security_groups = [aws_security_group.web_sg.name]

  # Add a provisioner to use Ansible
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y ansible",
      "echo '[webserver]' > /etc/ansible/hosts",
      "echo $(hostname -i) >> /etc/ansible/hosts",
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/bayer.pem")
      host        = self.public_ip
    }
  }

  tags = {
    Name = "Terraform-Ansible-EC2"
  }
}

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP and SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
