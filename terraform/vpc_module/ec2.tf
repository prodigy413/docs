module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "3.1.0"

  name = "obi-dev"

  ami                    = "ami-0df99b3a8349462c6"
  instance_type          = "t2.micro"
  key_name               = "test-key"
  monitoring             = true
  vpc_security_group_ids = [module.security_group_01.security_group_id]
  subnet_id              = module.vpc.private_subnets[0]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
