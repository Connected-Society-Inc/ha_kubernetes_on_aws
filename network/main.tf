provider "aws" {
    region = var.region
}

resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"   

    tags = {
        "Name": "kubernetes"
    }
}

data "aws_availability_zones" "azones" {
    state = "available"
}

resource "aws_subnet" "private_subnets" {
    count = length(data.aws_availability_zones.azones.names)

    vpc_id            = aws_vpc.vpc.id
    availability_zone = data.aws_availability_zones.azones.names[count.index]
    cidr_block        = "10.0.${count.index + 1}.0/24"
    
    tags = {
        "Name" = "kubernetes_private"
    }    
}

resource "aws_subnet" "public_subnets" {
    count = length(data.aws_availability_zones.azones.names)

    vpc_id            = aws_vpc.vpc.id
    availability_zone = data.aws_availability_zones.azones.names[count.index]
    cidr_block        = "10.0.${count.index + 100}.0/24"
    
    tags = {
        "Name" = "kubernetes_public"
    }    
}

resource "aws_internet_gateway" "gw" {
    vpc_id            = aws_vpc.vpc.id
    tags = {
        Name = "kubernetes"
    }
}

resource "aws_eip" "nat_ip" {
    count = length(aws_subnet.public_subnets)
}

resource "aws_nat_gateway" "nat_gws" {    
    count = length(aws_subnet.public_subnets)

    subnet_id     = aws_subnet.public_subnets[count.index].id
    allocation_id = aws_eip.nat_ip[count.index].id
    tags = {
        Name = "kubernetes"
    }
}

resource "aws_route_table" "public_route" {
    vpc_id     = aws_vpc.vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }
    tags = {
        "Name" = "kubernetes_public"
    }
}

resource "aws_route_table_association" "public" {
    count          = length(aws_subnet.public_subnets)
    subnet_id      = aws_subnet.public_subnets[count.index].id
    route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table" "private_routes" {
    vpc_id  = aws_vpc.vpc.id
    count   = length(aws_subnet.private_subnets)
    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gws[count.index].id
    }
    tags = {
        "Name" = "kubernetes_private"
    }
}

resource "aws_route_table_association" "private" {
    count          = length(aws_subnet.private_subnets)
    subnet_id      = aws_subnet.private_subnets[count.index].id
    route_table_id = aws_route_table.private_routes[count.index].id
}
