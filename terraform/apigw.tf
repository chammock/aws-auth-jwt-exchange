resource "aws_api_gateway_domain_name" "api" {
  domain_name              = var.domain_name
  regional_certificate_arn = data.aws_acm_certificate.domain.arn
  security_policy          = "TLS_1_2"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}
resource "aws_api_gateway_base_path_mapping" "api" {
  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.api.stage_name
  domain_name = aws_api_gateway_domain_name.api.domain_name
}

resource "aws_api_gateway_rest_api" "api" {
  name = local.name
  body = templatefile("apigw.tftpl", {
    "REGION"     = local.region,
    "LAMBDA_ARN" = aws_lambda_function.lambda.arn,
    "ISSUER"     = local.issuer,
    "JWKS"       = jsonencode(data.jwks_from_key.signer.jwks)
  })
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_stage" "api" {
  deployment_id = aws_api_gateway_deployment.api.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "v1"
}

resource "aws_api_gateway_method_settings" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.api.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
  }
}

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api.body))
  }
  lifecycle {
    create_before_destroy = true
  }
}
