terraform {
  cloud {
    organization = "DiSabatino_Inc"

    workspaces {
      name = "disabatino-route-53"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.70.0"
    }
  }
}

locals {
  domain_name = "disabatinoinc.io"
  zone_id = "Z03794032HYZLW9PN1WNP"
}

provider "aws" {
  region = "us-east-1"
}

import {
    to = aws_route53_zone.disabatinoinc_zone
    id = "Z03794032HYZLW9PN1WNP"
}

resource "aws_route53_zone" "disabatinoinc_zone" {
    name = "disabatinoinc.io"
}

resource "aws_acm_certificate" "disabatinoinc_certificate" {
  domain_name               = local.domain_name
  subject_alternative_names = ["*.${local.domain_name}"]
  validation_method         = "DNS"

  tags = {
    Name : local.domain_name
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_route53_record" "disabatinoinc_record" {
  for_each = {
    for dvo in aws_acm_certificate.disabatinoinc_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.disabatinoinc_zone.zone_id
}

resource "aws_acm_certificate_validation" "disabatinoinc_certificate_validation" {
  certificate_arn         = aws_acm_certificate.disabatinoinc_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.disabatinoinc_record : record.fqdn]
}
