# Route Tables - Public
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.env
  }
}

# Route Tables - Private
resource "aws_route_table" "private_route_table" {
  count = length(aws_subnet.private)

  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main_nat_gateway[count.index].id
  }

  tags = {
    Name        = "${var.project_name}-private-rt-${count.index + 1}"
    Environment = var.env
  }
}

resource "aws_route_table_association" "public_association" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Route Table Associations - Private
resource "aws_route_table_association" "private_association" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

