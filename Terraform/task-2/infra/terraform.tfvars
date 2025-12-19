region = "eu-west-1"

vpc_cidr = "10.0.0.0/16"

public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

instance_type = "t2.micro"
ami_id        = "ami-0c55b159cbfafe1f0"
alb_name      = "nti-alb"
s3_bucket_name = "nti-html-bucket-unique-id"
