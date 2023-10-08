resource "aws_iam_role" "lambda" {
  name        = local.name
  description = "AWS Auth JWT Exchange Lambda"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda" {
  name = "Required"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "KMSSigner",
        "Effect" : "Allow",
        "Action" : "kms:Sign",
        "Resource" : "${aws_kms_key.signer.arn}"
      },
      {
        "Sid" : "CloudWatchLogs"
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${aws_lambda_function.lambda.function_name}",
          "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${aws_lambda_function.lambda.function_name}:*"
        ]
      }
    ]
  })
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "../src/lambda_function.py"
  output_path = "../src/lambda_function.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name    = local.name
  description      = "AWS Auth JWT Excahnge"
  role             = aws_iam_role.lambda.arn
  filename         = data.archive_file.lambda.output_path
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.11"

  environment {
    variables = {
      KMS_KEY_ALIAS = aws_kms_alias.signer.name
      KID           = aws_kms_key.signer.id
      ISSUER        = local.issuer
    }
  }
}

resource "aws_lambda_permission" "api" {
  statement_id  = "AllowAPIGwInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}
