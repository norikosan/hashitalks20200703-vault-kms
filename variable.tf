variable "region" {
  default = "asia-northeast1"
}

variable "vault_project" {
  default = "example_project"
}

// 使うプロジェクト全てに対して色々権限が必要です。
variable "user" {
  default = "hogehoge@example.com"
}

// TLS証明書のコモンネーム
variable "common_name" {
  default = "vault-test.example.com"
}

// CloudDNS用のプロジェクト
variable "dns_project" {
  default = "dns_example_project"
}

variable "dns_managed_zone" {
  default = "dns_zone_example"
}

// Let's Encrypt 用のメールアドレス
variable "mailaddress" {
  default = "your@example.com"
}

variable "gcs_project" {
  default = "gcs_example_project"
}
