resource "aws_kms_key" "signer" {
  description              = "Used by AWS Auth JWT Exchange Lambda to Sign JWTs"
  multi_region             = true
  deletion_window_in_days  = 7
  customer_master_key_spec = "RSA_2048"
  key_usage                = "SIGN_VERIFY"
  policy = jsonencode({
    "Id" : "KeyPolicy",
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${local.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      }
    ]
  })
}
resource "aws_kms_alias" "signer" {
  name          = "alias/${local.name}"
  target_key_id = aws_kms_key.signer.key_id
}
