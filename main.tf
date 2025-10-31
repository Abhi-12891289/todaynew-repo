resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = "terraform-windows-key"
  public_key = tls_private_key.this.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.this.private_key_pem
  filename = "windows-key.pem"
}
resource "aws_security_group" "rdp" {
  name        = "allow-rdp"
  description = "Allow RDP from anywhere"

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # change to your IP for better security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
}
resource "aws_instance" "windows" {
  ami                    = "ami-089e0600a8bb6d176"

  instance_type          = "t3.micro"
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = [aws_security_group.rdp.id]
  associate_public_ip_address = true

  tags = {
    Name = "Windows-EC2-instance"
  }
}

output "public_ip" {
  value = aws_instance.windows.public_ip
}

output "private_key_path" {
  value = local_file.private_key.filename
}