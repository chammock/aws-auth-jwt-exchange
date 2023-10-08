output "dns" {
  description = "DNS Name and Value to API Gateway custom domain name"
  value = {
    "name" : var.domain_name,
    "value" : aws_api_gateway_domain_name.api.regional_domain_name
  }
}
