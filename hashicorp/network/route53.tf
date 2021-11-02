data "aws_route53_zone" "selected" {
  name = var.route53_base_domain
}

resource "aws_route53_zone" "sandbox" {
  name = "sandbox.${var.route53_base_domain}"
}

resource "aws_route53_record" "sandbox_ns" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "sandbox.${var.route53_base_domain}"
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.sandbox.name_servers
}
