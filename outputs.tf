# Output values
output "ns" {
  value = aws_route53_zone.main.name_servers
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.app_distribution.domain_name
}

output "lambda_invocation_result" {
  description = "Invocation result of Lambda execution"
  value       = data.aws_lambda_invocation.invoke_update_security_group_lambda.result
}
