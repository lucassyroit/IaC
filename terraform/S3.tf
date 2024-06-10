data "aws_iam_role" "LabRole" {
  name = "LabRole"
}


module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  providers = {
    aws = aws
  }


  bucket = var.s3_bucketname

  versioning = {
    enabled = true
  }

  replication_configuration = {
    role = data.aws_iam_role.LabRole.arn

    rules = [
      {
        id     = "replication"
        status = "Enabled"

        delete_marker_replication = false

        destination = {
          bucket        = module.s3_bucket_replica.s3_bucket_arn
          storage_class = "STANDARD"
        }
        depends_on = [module.s3_bucket_replica]
      },
    ]
  }
}

module "s3_bucket_replica" {
  source = "terraform-aws-modules/s3-bucket/aws"
  providers = {
    aws = aws.west
  }

  bucket = var.s3_bucketname_replica

  versioning = {
    enabled = true
  }

}

# Push sql.zip to the S3 bucket
resource "aws_s3_object" "object" {
  bucket     = module.s3_bucket.s3_bucket_id
  key        = "sql.zip"
  source     = "../data/sql.zip"
  depends_on = [module.s3_bucket]

}

# Push loop.sh to the S3 bucket
resource "aws_s3_object" "object2" {
  bucket     = module.s3_bucket.s3_bucket_id
  key        = "loop.sh"
  source     = "../scripts/loop.sh"
  depends_on = [module.s3_bucket]

}