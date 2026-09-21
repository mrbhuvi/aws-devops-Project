output "vpc_id" {
  value = module.vpc.vpc_id
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "application_url" {
  value = "http://${module.alb.alb_dns_name}"
}

output "autoscaling_group_name" {
  value = module.asg.autoscaling_group_name
}