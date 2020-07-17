resource "aws_iam_role" "iam_for_lambda" {
  name     = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "archive_file" "update_security_groups_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/update_security_groups.py"
  output_path = "${path.module}/.artifacts/update_security_groups.zip"
}

resource "aws_lambda_function" "update_security_groups_lambda" {
  filename         = "${path.module}/.artifacts/update_security_groups.zip"
  function_name    = "update_security_groups"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "update_security_groups.lambda_handler"
  source_code_hash = data.archive_file.update_security_groups_lambda_zip.output_base64sha256
  runtime          = "python3.6"
  timeout          = 15

  environment {
    variables = {
      DEBUG = "true"
    }
  }
}

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.update_security_groups_lambda.function_name}"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
# Lambda Policy
data "template_file" "lambda_iam_policy" {
  template = file("${path.module}/templates/lambda_iam_policy.json")
  vars = {
    region = var.aws_region
    account_id = data.aws_caller_identity.current.account_id
  }
}

resource "aws_iam_policy" "lambda_iam_policy" {
  name        = "lambda_iam_policy"
  path        = "/"
  description = "IAM policy for logging and update SGs from a lambda"

  policy = data.template_file.lambda_iam_policy.rendered
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}

# Lambda Permission
# aws lambda add-permission --function-name <Lambda ARN> --statement-id lambda-sns-trigger --action lambda:InvokeFunction --principal sns.amazonaws.com --source-arn arn:aws:sns:us-east-1:806199016981:AmazonIpSpaceChanged
resource "aws_lambda_permission" "lambda_sns_invoke_permission" {
  statement_id  = "lambda-sns-trigger"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_security_groups_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = "arn:aws:sns:us-east-1:806199016981:AmazonIpSpaceChanged"
}

# aws sns subscribe --topic-arn arn:aws:sns:us-east-1:806199016981:AmazonIpSpaceChanged --protocol lambda --notification-endpoint <Lambda ARN>
resource "aws_sns_topic_subscription" "sns_ip_space_changed_subscription" {
  provider  = aws.us_east_1
  topic_arn = "arn:aws:sns:us-east-1:806199016981:AmazonIpSpaceChanged"
  protocol  = "lambda"
  endpoint  = aws_lambda_function.update_security_groups_lambda.arn
}

# Lambda for calculating the hash of https://ip-ranges.amazonaws.com/ip-ranges.json
data "archive_file" "hash_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/hash.py"
  output_path = "${path.module}/.artifacts/hash.zip"
}

resource "aws_lambda_function" "hash_lambda" {
  filename         = "${path.module}/.artifacts/hash.zip"
  function_name    = "hash"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "hash.lambda_handler"
  source_code_hash = data.archive_file.hash_lambda_zip.output_base64sha256
  runtime          = "python3.6"
  timeout          = 15
}

data "aws_lambda_invocation" "hash_invocation" {
  function_name = aws_lambda_function.hash_lambda.function_name
  input = <<JSON
{
}
JSON
  depends_on = [aws_lambda_function.hash_lambda]
}

data "template_file" "invoke_lambda_payload" {
  template = file("${path.module}/lambda/payload.json")

  vars = {
    hash = jsondecode(data.aws_lambda_invocation.hash_invocation.result)["result"]
  }
}

data "aws_lambda_invocation" "invoke_update_security_group_lambda" {
  function_name = aws_lambda_function.update_security_groups_lambda.function_name

  input = data.template_file.invoke_lambda_payload.rendered

  depends_on = [data.aws_lambda_invocation.hash_invocation]
}

# output "hash_output" {
#   value = jsondecode(data.aws_lambda_invocation.hash_invocation.result)["result"]
# }

# output "update_security_group_output" {
#   value = jsondecode(data.aws_lambda_invocation.invoke_update_security_group_lambda.result)
# }
