data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_kms_alias" "lambda" {
  name = "alias/aws/lambda"
}

data "aws_kms_public_key" "signer" {
  key_id = aws_kms_key.signer.arn
}
data "jwks_from_key" "signer" {
  key = data.aws_kms_public_key.signer.public_key
  kid = aws_kms_key.signer.id
  use = "sig"
  alg = "RS256"
}

# Using an externally managed certificate for parent domain
data "aws_acm_certificate" "domain" {
  domain      = "*.${local.parent_domain}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

locals {
  name          = "aws-auth-jwt-exchange${var.suffix}"
  account_id    = data.aws_caller_identity.current.account_id
  region        = data.aws_region.current.name
  issuer        = "https://${var.domain_name}/"
  domain_split  = split(".", var.domain_name)
  parent_domain = join(".", slice(local.domain_split, 1, length(local.domain_split)))
}
