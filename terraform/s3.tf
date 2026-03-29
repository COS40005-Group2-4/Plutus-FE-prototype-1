data "aws_s3_bucket" "backups" {
  bucket = var.s3_bucket_name
}

resource "aws_s3_bucket_cors_configuration" "backups" {
  bucket = data.aws_s3_bucket.backups.id

  cors_rule {
    allowed_origins = var.cors_allow_origins
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_headers = ["*"]
    max_age_seconds = 3600
  }
}
