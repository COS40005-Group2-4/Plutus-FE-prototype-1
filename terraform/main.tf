resource "aws_dynamodb_table" "tc_acceptance" {
  name         = var.tc_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "email"

  attribute {
    name = "email"
    type = "S"
  }

  tags = {
    Project = "Plutus"
    Purpose = "Terms and Conditions acceptance tracking"
  }
}
