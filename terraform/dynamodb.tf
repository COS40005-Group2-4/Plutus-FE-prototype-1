# T&C acceptance tracking table (moved from main.tf)
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

# Main data table (single-table design)
resource "aws_dynamodb_table" "plutus_data" {
  name         = var.data_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "GSI1SK"
    type = "S"
  }

  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }

  tags = {
    Project = "Plutus"
  }
}
