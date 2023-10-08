variable "domain_name" {
  description = "Domain Name Used for Issuer & APIGW Custom Domain Name. Should be HOST only value"
  default     = "aws-auth-jwt-exchange.chammock.cloud"
}
variable "suffix" {
  description = "Apply a suffix to created resources"
  default = ""
}
