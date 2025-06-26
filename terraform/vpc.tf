resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr

  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc",
    Environment = var.env
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.project_name}-igw",
    Environment = var.env
  }
}


resource "aws_eip" "nat_eip" {
  count = length(aws_subnet.public)

  domain = "vpc"
  depends_on = [aws_internet_gateway.main_igw]

  tags = {
    Name        = "${var.project_name}-nat-eip-${count.index + 1}"
    Environment = var.env
  }
}

resource "aws_nat_gateway" "main_nat_gateway" {
  count = length(aws_subnet.public)

  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "${var.project_name}-nat-gateway-${count.index + 1}"
    Environment = var.env
  }

  depends_on = [aws_internet_gateway.main_igw]
}






