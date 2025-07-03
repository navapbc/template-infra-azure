output "hosted_zone_name_servers" {
  value = local.dns_zone != null ? local.dns_zone.name_servers : null
}
