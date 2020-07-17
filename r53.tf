resource "aws_route53_zone" "main" {
  name = var.zone_name

  tags = {
    Environment = var.environment
  }
}

# WWW CNAME record and SSL certs
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = "30"
  records = [aws_cloudfront_distribution.app_distribution.domain_name]
}

resource "aws_acm_certificate" "www_cert" {
  provider          = aws.us_east_1
  domain_name       = "www.${var.zone_name}"
  validation_method = "DNS"

  tags = {
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "www_cert_validation" {
  name     = aws_acm_certificate.www_cert.domain_validation_options.0.resource_record_name
  type     = aws_acm_certificate.www_cert.domain_validation_options.0.resource_record_type
  zone_id  = aws_route53_zone.main.zone_id
  records  = [aws_acm_certificate.www_cert.domain_validation_options.0.resource_record_value]
  ttl      = 60
}

resource "aws_acm_certificate_validation" "www_cert_validation" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.www_cert.arn
  validation_record_fqdns = [aws_route53_record.www_cert_validation.fqdn]
}

# ALB CNAME record and SSL certs
resource "aws_route53_record" "alb" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "alb"
  type    = "CNAME"
  ttl     = "30"
  records = [aws_lb.app_lb.dns_name]
}

resource "aws_acm_certificate" "alb_cert" {
  domain_name       = "alb.${var.zone_name}"
  validation_method = "DNS"

  tags = {
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "alb_cert_validation" {
  name    = aws_acm_certificate.alb_cert.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.alb_cert.domain_validation_options.0.resource_record_type
  zone_id = aws_route53_zone.main.zone_id
  records = [aws_acm_certificate.alb_cert.domain_validation_options.0.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "alb_cert_validation" {
  certificate_arn         = aws_acm_certificate.alb_cert.arn
  validation_record_fqdns = [aws_route53_record.alb_cert_validation.fqdn]
}
