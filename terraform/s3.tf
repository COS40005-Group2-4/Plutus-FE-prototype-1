data "aws_s3_bucket" "backups" {
  bucket = var.s3_bucket_name
}
