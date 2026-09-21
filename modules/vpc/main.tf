resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_support   = true
    enable_dns_hostnames = true
    
    tags = {
        Name        = "${var.project_name}-${var.environment}-vpc"
        Project     = var.project_name
        Environment = var.environment
    }
  
}

#Internet gateway

resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name        = "${var.project_name}-${var.environment}-igw"
    }
}

#public subnets AZ1

resource "aws_subnet" "public_1" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = var.public_subnet_1_cidr
    availability_zone = var.availability_zone_1
    map_public_ip_on_launch = true

    tags = {
        Name        = "${var.project_name}-${var.environment}-public-subnet-az1"
    }
}

#public subnets AZ2

resource "aws_subnet" "public_2" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = var.public_subnet_2_cidr
    availability_zone = var.availability_zone_2
    map_public_ip_on_launch = true

    tags = {
        Name        = "${var.project_name}-${var.environment}-public-subnet-az2"
    }
}

#private subnets AZ1

resource "aws_subnet" "private_1" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = var.private_subnet_1_cidr
    availability_zone = var.availability_zone_1
    map_public_ip_on_launch = false

    tags = {
        Name        = "${var.project_name}-${var.environment}-private-subnet-az1"
    }
}
#private subnets AZ2
resource "aws_subnet" "private_2" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = var.private_subnet_2_cidr
    availability_zone = var.availability_zone_2
    map_public_ip_on_launch = false

    tags = {
        Name        = "${var.project_name}-${var.environment}-private-subnet-az2"
    }
}

#public route table

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = {
        Name        = "${var.project_name}-${var.environment}-public-rt"
    }
}

resource "aws_route_table_association" "public_1" {
    subnet_id      = aws_subnet.public_1.id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
    subnet_id      = aws_subnet.public_2.id
    route_table_id = aws_route_table.public.id
}

# NAT Gateway AZ1


resource "aws_eip" "nat_1" {
    domain = "vpc"

    tags = {
        Name        = "${var.project_name}-${var.environment}-nat-eip-az1"
    }

}

resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_1.id
  subnet_id     = aws_subnet.public_1.id

  depends_on = [
    aws_internet_gateway.main
  ]

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-az1"
  }
}

# --------------------------------------------------
# NAT Gateway AZ2
# --------------------------------------------------

resource "aws_eip" "nat_2" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip-az2"
  }
}

resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_2.id
  subnet_id     = aws_subnet.public_2.id

  depends_on = [
    aws_internet_gateway.main
  ]

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-az2"
  }
}

# --------------------------------------------------
# Private Route Table AZ1
# --------------------------------------------------

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt-az1"
  }
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

# --------------------------------------------------
# Private Route Table AZ2
# --------------------------------------------------

resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt-az2"
  }
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_2.id
}