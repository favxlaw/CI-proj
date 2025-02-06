provider "aws" {
  region = "eu-north-1"
}

# Create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "ci-cd-vpc"
  }
}

# Create a subnet within the VPC
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# Create an Internet Gateway for external access
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "ci-cd-igw"
  }
}

# Create a route table for the public subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate the subnet with the route table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group
resource "aws_security_group" "jenkins_sg" {
  vpc_id = aws_vpc.main_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "jenkins-security-group" }
}

# EC2 Instances
resource "aws_instance" "ansible_controller" {
  ami           = "ami-0bd5c36aab14982b0"  
  instance_type = "t3.small"
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = "CI"
  security_groups = [aws_security_group.jenkins_sg.name]

  tags = {
    Name = "Ansible-Controller"
  }
}

resource "aws_instance" "jenkins_agent" {
  ami           = "ami-0bd5c36aab14982b0"
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = "CI"
  security_groups = [aws_security_group.jenkins_sg.name]

  tags = {
    Name = "Jenkins-Agent"
  }
}

# Create inventory.ini file dynamically
resource "local_file" "ansible_inventory" {
  filename = "inventory.ini"
  content  = <<EOT
[ansible_controller]
${aws_instance.ansible_controller.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/CI.pem

[jenkins_agents]
${aws_instance.jenkins_agent.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/CI.pem
EOT
}

# Run Ansible Playbook
resource "null_resource" "run_ansible" {
  depends_on = [local_file.ansible_inventory]

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini setup.yml"
  }
}
