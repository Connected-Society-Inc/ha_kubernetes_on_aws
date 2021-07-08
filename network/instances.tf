resource "aws_iam_role" "ssm_role" {
    name = "ssm_role"

    assume_role_policy = jsonencode({
        "Version" = "2012-10-17"
        "Statement" = [
            {
            "Effect" = "Allow"
            "Principal" =  {
                "Service" = "ec2.amazonaws.com"
            }
            "Action" = "sts:AssumeRole"
            }
        ]
    })

    managed_policy_arns = [
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ]
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
    name = "ssm_profile"
    role = aws_iam_role.ssm_role.name
}

resource "aws_instance" "etcd_instances" {
    count                = length(aws_subnet.private_subnets)
    ami                  = "ami-0721c9af7b9b75114"
    instance_type        = "t3.medium"
    subnet_id            = aws_subnet.private_subnets[count.index].id
    iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
    
    user_data = <<EOF
        #!/bin/bash
        yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    EOF
    
    tags = {
        "Name" = "etcd"
    }
}
