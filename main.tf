terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.10.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

# Key Pair
resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins-key" 
  public_key = file("~/.ssh/jenkins-key.pem.pub") 
}

# Security Group
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH and Jenkins Web UI"

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Jenkins Web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}

# # EBS Volume for Persistent Data
# resource "aws_ebs_volume" "jenkins_data" {
#   availability_zone = "eu-north-1"
#   size              = 20 
#   tags = {
#     Name = "Jenkins-Data"
#   }
# }

# EC2 Instance with EBS Volume Attached
resource "aws_instance" "jenkins" {
  ami                         = "ami-0bd5c36aab14982b0" # Ubuntu 20.04
  instance_type               = "t3.small"             
  associate_public_ip_address = true
  key_name                    = aws_key_pair.jenkins_key.key_name 
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]

#   root_block_device {
#     volume_size = 16 # Root volume size
#   }

  tags = {
    Name = "Jenkins-Master-Agent"
  }

  # Provisioner for Ansible
  provisioner "local-exec" {
    command = <<-EOT
      sleep 30
      echo "[jenkins_master]
      ${self.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/jenkins-key.pem" > inventory.ini
      ansible-playbook -i inventory.ini main.yaml
    EOT
  }
}

# # Volume Attachment
# resource "aws_volume_attachment" "jenkins_volume_attachment" {
#   device_name = "/dev/xvdf"
#   volume_id   = aws_ebs_volume.jenkins_data.id
#   instance_id = aws_instance.jenkins.id
  
# }

# Output Public IP
output "jenkins_public_ip" {
  value       = aws_instance.jenkins.public_ip
  description = "Public IP of the Jenkins EC2 instance (Master and Agent)"
}
