# Uncomment the backend block below after running:
#   cd ../../bootstrap && terraform init && terraform apply
#
# Then replace the placeholder values with the outputs from the Bootstrap module.

# terraform {
#   backend "s3" {
#     bucket         = "your-state-bucket-name"
#     key            = "dev/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-state-lock"
#     encrypt        = true
#   }
# }
