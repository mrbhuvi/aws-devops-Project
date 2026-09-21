variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
  
}

variable "state_bucket_name" {
  description = "Global S3 bucket name for storing terraform state"
  type        = string
  default     = "terraform-state-bhuvi-2026-prod"
}