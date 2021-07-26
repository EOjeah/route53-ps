resource "aws_route53_delegation_set" "main" {
  reference_name = "1047874"
}

output "delegation_set_id" {
  value = aws_route53_delegation_set.main.id
}
