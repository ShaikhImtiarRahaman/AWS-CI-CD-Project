provider "aws" {
  region = "us-east-1"  # Set the preferred region
}

# Create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main_vpc"
  }
}

# Create Subnet A (Public Subnet)
resource "aws_subnet" "main_subnet_a" {
  vpc_id                   = aws_vpc.main_vpc.id
  cidr_block               = "10.0.1.0/24"
  availability_zone        = "us-east-1a"
  map_public_ip_on_launch  = true  # Enable public IPs for instances in this subnet

  tags = {
    Name = "main_subnet_a"
  }
}

# Create Subnet B (Public Subnet)
resource "aws_subnet" "main_subnet_b" {
  vpc_id                   = aws_vpc.main_vpc.id
  cidr_block               = "10.0.2.0/24"
  availability_zone        = "us-east-1b"
  map_public_ip_on_launch  = true  # Enable public IPs for instances in this subnet

  tags = {
    Name = "main_subnet_b"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main_igw"
  }
}

# Create a Route Table
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main_route_table"
  }
}

# Create a Route to the Internet
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.main_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw.id
}

# Associate Route Table with Subnet A
resource "aws_route_table_association" "subnet_a_assoc" {
  subnet_id      = aws_subnet.main_subnet_a.id
  route_table_id = aws_route_table.main_route_table.id
}

# Associate Route Table with Subnet B
resource "aws_route_table_association" "subnet_b_assoc" {
  subnet_id      = aws_subnet.main_subnet_b.id
  route_table_id = aws_route_table.main_route_table.id
}

# Create a Security Group for SSH Access and Jenkins
resource "aws_security_group" "main_sg" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from anywhere (restrict to your IP for security)
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP traffic to Jenkins
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "main_sg"
  }
}

# Create an IAM Role for EKS
resource "aws_iam_role" "eks_role" {
  name = "eks_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
      },
    ],
  })
}

# Attach IAM Policies to EKS Role
resource "aws_iam_role_policy_attachment" "eks_role_policy_attachment_cluster" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_role_policy_attachment_vpc" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# Create an IAM Role for Jenkins (EC2 instance)
resource "aws_iam_role" "jenkins_ec2_role" {
  name = "jenkins_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      },
    ],
  })
}

# Attach policies to allow Jenkins to interact with EKS, EC2, and S3
resource "aws_iam_role_policy_attachment" "jenkins_ec2_policy_attachment" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "ec2_full_access" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Create the EKS Cluster
resource "aws_eks_cluster" "main_eks" {
  name     = "main-eks-cluster"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.main_subnet_a.id,
      aws_subnet.main_subnet_b.id
    ]
    endpoint_private_access = false  # Change to true if only private access is needed
    endpoint_public_access  = true   # Change to true if public access is needed
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_role_policy_attachment_cluster,
    aws_iam_role_policy_attachment.eks_role_policy_attachment_vpc,
    aws_route_table_association.subnet_a_assoc,
    aws_route_table_association.subnet_b_assoc
  ]
}

# Create EKS Node Group IAM Role
resource "aws_iam_role" "eks_node_group_role" {
  name = "eks_node_group_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
      },
    ],
  })
}

# Attach IAM Policies to Node Group Role
resource "aws_iam_role_policy_attachment" "node_group_role_policy_attachment" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy_attachment" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_policy_attachment" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Create the EKS Node Group with t2.micro Instances
resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.main_eks.name
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = [aws_subnet.main_subnet_a.id, aws_subnet.main_subnet_b.id]

  instance_types  = ["t2.micro"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  depends_on = [
    aws_eks_cluster.main_eks,
    aws_iam_role_policy_attachment.node_group_role_policy_attachment,
    aws_iam_role_policy_attachment.cni_policy_attachment,
    aws_iam_role_policy_attachment.ec2_container_policy_attachment,
    aws_route_table_association.subnet_a_assoc,
    aws_route_table_association.subnet_b_assoc
  ]
}
