terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.45"
    }
  }

  backend "s3" {
    bucket = "dlplatform-dev-terraform-remote-state-storage"
    key    = "entity_lookup/prod/state.tfstate"
    region = "eu-west-2"
    dynamodb_table = "DLPlatform-Dev-terraform-state-lock-dynamo"
  }

  required_version = ">= 1.0.0"
}

variable "aws_region" {
  type = string
  default = "eu-west-2"
}

variable "aws_vault_profile" {
  type = string
  default = "dl-dev"
}

variable "aws_app_account_id" {
  type = number
  default = 955696714113
}

provider "aws" {
  profile = "${var.aws_vault_profile}"
  region  = "${var.aws_region}"

  assume_role {
    role_arn = "arn:aws:iam::${var.aws_app_account_id}:role/developer"
  }
}

resource "aws_rds_cluster" "aurora_cluster" {
    availability_zones                  = [
        "eu-west-2a",
        "eu-west-2b",
        "eu-west-2c",
    ]
    backtrack_window                    = 0
    backup_retention_period             = 1
    cluster_identifier                  = "database-1"
    cluster_members                     = [
        "database-1-instance-1",
    ]
    copy_tags_to_snapshot               = true
    db_cluster_parameter_group_name     = "default.aurora-mysql5.7"
    db_subnet_group_name                = "db-test-public-subnet-group"
    deletion_protection                 = false
    enable_http_endpoint                = false
    enabled_cloudwatch_logs_exports     = []
    engine                              = "aurora-mysql"
    engine_mode                         = "provisioned"
    engine_version                      = "5.7.mysql_aurora.2.07.2"
    iam_database_authentication_enabled = true
    iam_roles                           = []
    kms_key_id                          = "arn:aws:kms:eu-west-2:955696714113:key/6ba5cec2-50f3-4fa5-bc27-f2af90974c43"
    master_username                     = "admin"
    port                                = 3306
    preferred_backup_window             = "03:39-04:09"
    preferred_maintenance_window        = "sun:02:25-sun:02:55"
    skip_final_snapshot                 = true
    storage_encrypted                   = true
    tags                                = {}
    tags_all                            = {}
    vpc_security_group_ids              = [
        "sg-0e1d2463d26600ad1",
    ]

    timeouts {}
}

#resource "aws_vpc" "dl_web_vpc" {
#    cidr_block                       = "10.0.0.0/16"
#    enable_dns_hostnames             = true
#    instance_tenancy                 = "default"
#}

#resource "aws_internet_gateway" "dl_web_gw" {
#  vpc_id = aws_vpc.dl_web_vpc.id
#}

#data "aws_availability_zones" "available" {}

#resource "aws_subnet" "public" {
#  count                   = "${length(data.aws_availability_zones.available.names)}"
#  vpc_id                  = "${aws_vpc.dl_web_vpc.id}"
#  cidr_block              = "10.0.${count.index}.0/24"
#  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
#  map_public_ip_on_launch = true
#  tags                    = {}
#}
#resource "aws_subnet" "private" {
#  count                   = "${length(data.aws_availability_zones.available.names)}"
#  vpc_id                  = "${aws_vpc.dl_web_vpc.id}"
#  cidr_block              = "10.0.${10+count.index}.0/24"
#  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
#  map_public_ip_on_launch = false
#  tags                    = {}
#}

#resource "aws_route_table" "public" {
#    vpc_id = aws_vpc.dl_web_vpc.id

#    route {
#        cidr_block = "0.0.0.0/0"
#        gateway_id = aws_internet_gateway.dl_web_gw.id
#    }
#}

#resource "aws_route_table_association" "route_table_association" {
#    for_each = toset(aws_subnet.public.*.id)

#    subnet_id      = each.value
#    route_table_id = aws_route_table.public.id
#}

#resource "aws_route53_zone" "dl_web_dns_zone" {
#    name         = "digital-land.info"
#}

#resource "aws_route53_record" "dl_web_dns_record" {
#    name    = "www.test.digital-land.info"
#    type    = "A"
#    zone_id = aws_route53_zone.dl_web_dns_zone.id

#    alias {
#        evaluate_target_health = true
#        name                   = aws_lb.dl_web_lb.dns_name
#        zone_id                = aws_lb.dl_web_lb.zone_id
#    }
#}

#resource "aws_iam_policy" "digital_land_collection_s3" {
#    description = "A policy to allow read and write access to the collection-dataset s3 bucket."
#    name        = "dl-web-policy-collection-s3"
#    path        = "/"
#    policy      = jsonencode(
#        {
#            Statement = [
#                {
#                    Action   = [
#                        "s3:ListBucket",
#                    ]
#                    Effect   = "Allow"
#                    Resource = [
#                        "arn:aws:s3:::collection-dataset",
#                    ]
#                },
#                {
#                    Action   = [
#                        "s3:PutObject",
#                        "s3:GetObject",
#                        "s3:DeleteObject",
#                    ]
#                    Effect   = "Allow"
#                    Resource = [
#                        "arn:aws:s3:::collection-dataset/*",
#                    ]
#                },
#            ]
#            Version   = "2012-10-17"
#        }
#    )
#}

#resource "aws_iam_policy" "ecs_cloudwatch_logs" {
#    description = "Allows ECS to log to CloudWatch"
#    name        = "dl-web-policy-CloudWatchLogs"
#    path        = "/"
#    policy      = jsonencode(
#        {
#            Statement = [
#                {
#                    Action   = [
#                        "logs:CreateLogGroup",
#                        "logs:CreateLogStream",
#                        "logs:PutLogEvents",
#                        "logs:DescribeLogStreams",
#                    ]
#                    Effect   = "Allow"
#                    Resource = [
#                        "arn:aws:logs:*:*:*",
#                    ]
#                },
#            ]
#            Version   = "2012-10-17"
#        }
#    )
#}

#resource "aws_iam_role" "dl_app_role" {
#    assume_role_policy    = jsonencode(
#        {
#            Statement = [
#                {
#                    Action    = "sts:AssumeRole"
#                    Effect    = "Allow"
#                    Principal = {
#                        Service = [
#                            "ec2.amazonaws.com",
#                            "ecs.amazonaws.com",
#                            "ecs-tasks.amazonaws.com",
#                        ]
#                    }
#                    Sid       = ""
#                },
#            ]
#            Version   = "2012-10-17"
#        }
#    )
#    force_detach_policies = false
#    managed_policy_arns   = [
#        aws_iam_policy.digital_land_collection_s3.arn,
#        aws_iam_policy.ecs_cloudwatch_logs.arn,
#        "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
#    ]
#    max_session_duration  = 3600
#    name                  = "DLPlatform-Dev-application"
#    path                  = "/"
#    tags                  = {}
#    tags_all              = {}

#    inline_policy {}
#}

#resource "aws_ecs_cluster" "dl_web_cluster" {
#    capacity_providers = []
#    name               = "dl-web-cluster"
#    tags               = {}
#    tags_all           = {}

#    setting {
#        name  = "containerInsights"
#        value = "enabled"
#    }
#}

#data "aws_ecr_repository" "dl_web_ecr" {
#    name = "dl-web"
#}

## if we let terraform manage ECR, we lost all images on destroy
## resource "aws_ecr_repository" "dl_web_ecr" {
##     image_tag_mutability = "MUTABLE"
##     name                 = "dl-web"
## }

#resource "aws_cloudwatch_log_group" "dl_web_log_group" {
#    name              = "/ecs/dl-web"
#}

resource "aws_ecs_task_definition" "entity_lookup_task" {
    container_definitions    = jsonencode(
        [
            {
                cpu              = 0
                environment      = []
                essential        = true
                image            = "public.ecr.aws/l6z6v3j6/entity-lookup:latest"
                logConfiguration = {
                    logDriver = "awslogs"
                    options   = {
                        awslogs-group         = "/ecs/entity-lookup-task"
                        awslogs-region        = "eu-west-2"
                        awslogs-stream-prefix = "ecs"
                    }
                }
                memory           = 300
                mountPoints      = []
                name             = "entity-lookup"
                portMappings     = [
                    {
                        containerPort = 80
                        hostPort      = 0
                        protocol      = "tcp"
                    },
                ]
                volumesFrom      = []
            },
        ]
    )
    execution_role_arn       = "arn:aws:iam::955696714113:role/DLPlatform-Dev-application"
    family                   = "entity-lookup-task"
    requires_compatibilities = [
        "EC2",
    ]
    tags                     = {}
    tags_all                 = {}
    task_role_arn            = "arn:aws:iam::955696714113:role/DLPlatform-Dev-application"
}
#resource "aws_ecs_task_definition" "dl_web_task" {
#    container_definitions    = jsonencode(
#        [
#            {
#                cpu              = 0
#                environment      = []
#                essential        = true
#                image            = "${data.aws_ecr_repository.dl_web_ecr.repository_url}:latest"
#                logConfiguration = {
#                    logDriver = "awslogs"
#                    options   = {
#                        awslogs-group         = aws_cloudwatch_log_group.dl_web_log_group.name
#                        awslogs-region        = "eu-west-2"
#                        awslogs-stream-prefix = "ecs"
#                    }
#                }
#                mountPoints      = []
#                name             = "dl-web"
#                portMappings     = [
#                    {
#                        containerPort = 5000
#                        hostPort      = 0
#                        protocol      = "tcp"
#                    },
#                ]
#                volumesFrom      = []
#            },
#        ]
#    )
#    cpu                      = "1024"
#    execution_role_arn       = aws_iam_role.dl_app_role.arn
#    family                   = "dl-web"
#    memory                   = "1024"
#    requires_compatibilities = [
#        "EC2",
#    ]
#    tags                     = {}
#    tags_all                 = {}
#    task_role_arn            = aws_iam_role.dl_app_role.arn
#}

#resource "aws_lb" "dl_web_lb" {
#  name               = "dl-web-lb"
#  internal           = false
#  load_balancer_type = "application"
#  security_groups    = [aws_security_group.dl_web_lb_sg.id]
#  subnets            = aws_subnet.public.*.id
#  # subnets            = ["subnet-038a7b0a7893fc92f", "subnet-0efdd0db0301be5de"]

#  depends_on = [aws_internet_gateway.dl_web_gw]

#  # access_logs {
#  #   bucket  = aws_s3_bucket.lb_logs.bucket
#  #   prefix  = "test-lb"
#  #   enabled = true
#  # }
#}

#output "load_balancer_dns" {
#    value = aws_lb.dl_web_lb.dns_name
#}

data "aws_lb" "dl_web_lb" {
  name = "dl-web-lb"
}

data "aws_lb_listener" "dl_web_lb_listener" {
  load_balancer_arn = data.aws_lb.dl_web_lb.arn
  port              = 80
}

data "aws_lb_listener" "dl_web_lb_listener_https" {
  load_balancer_arn = data.aws_lb.dl_web_lb.arn
  port              = 443
}

resource "aws_lb_listener_rule" "entity_lookup_lb_listener_rule" {
    listener_arn = data.aws_lb_listener.dl_web_lb_listener.arn
    priority     = 1
    tags         = {}
    tags_all     = {}

    action {
        order            = 1
        target_group_arn = aws_lb_target_group.entity_lookup_target_group.arn
        type             = "forward"
    }

    condition {

        path_pattern {
            values = [
                "/entity*",
            ]
        }
    }
}

resource "aws_lb_listener_rule" "entity_lookup_lb_listener_rule_https" {
    listener_arn = data.aws_lb_listener.dl_web_lb_listener_https.arn
    priority     = 1
    tags         = {}
    tags_all     = {}

    action {
        order            = 1
        target_group_arn = aws_lb_target_group.entity_lookup_target_group.arn
        type             = "forward"
    }

    condition {

        path_pattern {
            values = [
                "/entity*",
            ]
        }
    }
}

#resource "aws_lb_listener" "dl_web_lb_listener" {
#  load_balancer_arn = aws_lb.dl_web_lb.arn
#  port              = "80"
#  protocol          = "HTTP"

#  default_action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.dl_web_lb_target_group.arn
#  }
#}

data "aws_vpc" "dl_web_vpc" {
  filter {
    name = "tag:Name"
    values = ["dl-web-vpc"]
  }
}

resource "aws_lb_target_group" "entity_lookup_target_group" {
    deregistration_delay          = 5
    load_balancing_algorithm_type = "round_robin"
    name                          = "entity-lookup-target-group-2"
    port                          = 80
    protocol                      = "HTTP"
    protocol_version              = "HTTP1"
    slow_start                    = 0
    tags                          = {}
    tags_all                      = {}
    target_type                   = "instance"
    vpc_id                        = data.aws_vpc.dl_web_vpc.id

    health_check {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
    }

    stickiness {
        cookie_duration = 86400
        enabled         = false
        type            = "lb_cookie"
    }
}
#    deregistration_delay          = 120
#    load_balancing_algorithm_type = "round_robin"
#    name                          = "dl-web-lb-target-group"
#    port                          = 5000
#    protocol                      = "HTTP"
#    protocol_version              = "HTTP1"
#    slow_start                    = 0
#    tags                          = {}
#    tags_all                      = {}
#    target_type                   = "instance"
#    vpc_id                        = aws_vpc.dl_web_vpc.id

#    health_check {
#        enabled             = true
#        healthy_threshold   = 5
#        interval            = 30
#        matcher             = "200"
#        path                = "/health"
#        port                = "traffic-port"
#        protocol            = "HTTP"
#        timeout             = 5
#        unhealthy_threshold = 2
#    }

#    stickiness {
#        cookie_duration = 86400
#        enabled         = false
#        type            = "lb_cookie"
#    }
#}

#data "aws_ecs_container_definition" "dl_web" {
#  task_definition = aws_ecs_task_definition.dl_web_task.id
#  container_name  = "dl-web"
#}

## resource "aws_lb_target_group_attachment" "dl_web_lb_target_group_attachement" {
##   target_group_arn = aws_lb_target_group.dl_web_lb_target_group.id
##   target_id        = data.aws_ecs_container_definition.dl_web.id
##   port             = 5000
## }

data "aws_ecs_cluster" "dl_web_cluster" {
  cluster_name = "dl-web-cluster"
}

resource "aws_ecs_service" "entity_lookup_service" {
    cluster                            = data.aws_ecs_cluster.dl_web_cluster.arn
    deployment_maximum_percent         = 100
    deployment_minimum_healthy_percent = 0
    desired_count                      = 2
    enable_ecs_managed_tags            = true
    enable_execute_command             = false
    health_check_grace_period_seconds  = 0
    iam_role                           = "ecsServiceRole"
    launch_type                        = "EC2"
    name                               = "entity-lookup-service"
    scheduling_strategy                = "REPLICA"
    tags                               = {}
    tags_all                           = {}
    task_definition                    = aws_ecs_task_definition.entity_lookup_task.arn

    deployment_circuit_breaker {
        enable   = false
        rollback = false
    }

    deployment_controller {
        type = "ECS"
    }

    load_balancer {
        container_name   = "entity-lookup"
        container_port   = 80
        target_group_arn = aws_lb_target_group.entity_lookup_target_group.arn
    }

    ordered_placement_strategy {
        field = "attribute:ecs.availability-zone"
        type  = "spread"
    }
    ordered_placement_strategy {
        field = "instanceId"
        type  = "spread"
    }

    timeouts {}
}
    # cluster                            = aws_ecs_cluster.dl_web_cluster.arn
    # deployment_maximum_percent         = 200
    # deployment_minimum_healthy_percent = 100
    # desired_count                      = 2
    # enable_ecs_managed_tags            = true
    # enable_execute_command             = false
    # health_check_grace_period_seconds  = 120
    # launch_type                        = "EC2"
    # name                               = "dl-web-service"
    # scheduling_strategy                = "REPLICA"
    # tags                               = {}
    # tags_all                           = {}
    # task_definition                    = aws_ecs_task_definition.dl_web_task.arn

    # deployment_circuit_breaker {
    #     enable   = false
    #     rollback = false
    # }

    # deployment_controller {
    #     type = "ECS"
    # }

    # load_balancer {
    #     container_name   = "dl-web"
    #     container_port   = 5000
    #     target_group_arn = aws_lb_target_group.dl_web_lb_target_group.arn
    # }

    # ordered_placement_strategy {
    #     field = "attribute:ecs.availability-zone"
    #     type  = "spread"
    # }
    # ordered_placement_strategy {
    #     field = "instanceId"
    #     type  = "spread"
    # }

    # timeouts {}
# }

#resource "aws_security_group" "dl_web_lb_sg" {
#    description = "Load Balancer Allowed Ports"
#    egress      = [
#        {
#            cidr_blocks      = [
#                "0.0.0.0/0",
#            ]
#            description      = "Allow egress to ECS instance security group"
#            from_port        = 32768
#            ipv6_cidr_blocks = []
#            prefix_list_ids  = []
#            protocol         = "tcp"
#            self             = false
#            to_port          = 65535
#            security_groups  = [
#                aws_security_group.ecs_instance_sg.id
#            ]
#        },
#    ]
#    ingress     = [
#        {
#            cidr_blocks      = [
#                "0.0.0.0/0",
#            ]
#            description      = ""
#            from_port        = 80
#            ipv6_cidr_blocks = []
#            prefix_list_ids  = []
#            protocol         = "tcp"
#            security_groups  = []
#            self             = false
#            to_port          = 80
#        },
#    ]
#    name        = "dl_web_lb_sg"
#    tags        = {}
#    tags_all    = {}
#    vpc_id      = aws_vpc.dl_web_vpc.id

#    timeouts {}
#}

## this rule depends on both security groups so separating it allows it
## to be created after both
#resource "aws_security_group_rule" "lb_ingress" {
#  security_group_id        = "${aws_security_group.ecs_instance_sg.id}"
#  description              = "ephemeral port range for Load Balancer ingress"
#  from_port                = 32768
#  to_port                  = 65535
#  protocol                 = "tcp"
#  type                     = "ingress"
#  source_security_group_id = "${aws_security_group.dl_web_lb_sg.id}"
#}

#resource "aws_security_group_rule" "all_egress" {
#  security_group_id        = "${aws_security_group.ecs_instance_sg.id}"
#  description              = "allow any egress"
#  from_port                = 0
#  to_port                  = 0
#  protocol                 = "-1"
#  type                     = "egress"
#  cidr_blocks      = [
#    "0.0.0.0/0",
#  ]
#}

#resource "aws_security_group_rule" "ssh_ingress" {
#  security_group_id        = "${aws_security_group.ecs_instance_sg.id}"
#  description              = "allow ssh access to ECS instances"
#  from_port                = 22
#  to_port                  = 22
#  protocol                 = "tcp"
#  type                     = "ingress"
#  cidr_blocks      = [
#    "0.0.0.0/0",
#  ]
#}

#resource "aws_security_group" "ecs_instance_sg" {
#    description = "ECS instance security group"
#    name        = "dl_web_ecs_instance_sg"
#    vpc_id      = aws_vpc.dl_web_vpc.id
#}

#resource "aws_autoscaling_group" "dl_web_asg" {
#    capacity_rebalance        = false
#    default_cooldown          = 300
#    desired_capacity          = 2
#    enabled_metrics           = []
#    health_check_grace_period = 0
#    health_check_type         = "EC2"
#    launch_configuration      = aws_launch_configuration.ecs_launch_config.name
#    load_balancers            = []
#    max_instance_lifetime     = 0
#    max_size                  = 2
#    metrics_granularity       = "1Minute"
#    min_size                  = 0
#    name                      = "dl_web_asg"
#    protect_from_scale_in     = false
#    service_linked_role_arn   = "arn:aws:iam::955696714113:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
#    suspended_processes       = []
#    target_group_arns         = []
#    termination_policies      = []
#    vpc_zone_identifier       = aws_subnet.public.*.id

#    timeouts {}
#}

#resource "aws_launch_configuration" "ecs_launch_config" {
#    associate_public_ip_address      = true
#    ebs_optimized                    = false
#    enable_monitoring                = true
#    iam_instance_profile             = "arn:aws:iam::955696714113:instance-profile/ecsInstanceRole"
#    image_id                         = "ami-05db1ea966500fa94"
#    instance_type                    = "t2.medium"
#    key_name                         = "jb-test"
#    name                             = "dl_web_launch_config"
#    security_groups                  = [
#        aws_security_group.ecs_instance_sg.id,
#    ]
#    user_data                        = <<-USERDATA
#                                       #!/bin/bash
#                                       echo ECS_CLUSTER=${aws_ecs_cluster.dl_web_cluster.name} >> /etc/ecs/ecs.config;
#                                       echo ECS_BACKEND_HOST= >> /etc/ecs/ecs.config;
#                                       USERDATA

#    vpc_classic_link_security_groups = []

#    root_block_device {
#        delete_on_termination = false
#        encrypted             = false
#        iops                  = 0
#        throughput            = 0
#        volume_size           = 30
#        volume_type           = "gp2"
#    }
#}
