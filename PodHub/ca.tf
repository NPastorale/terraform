resource "tls_private_key" "ca_key" {
  algorithm = "ED25519"
}

resource "tls_self_signed_cert" "ca_cert" {
  private_key_pem       = tls_private_key.ca_key.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = 8760
  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "key_encipherment",
    "digital_signature",
  ]
  subject {
    common_name = "Cilium CA"
  }
}

resource "tls_private_key" "server_key" {
  algorithm = "ED25519"
}

resource "tls_cert_request" "server_req" {
  private_key_pem = tls_private_key.server_key.private_key_pem
  subject {
    common_name = "*.${var.cluster_name}.hubble-grpc.cilium.io"
  }
}

resource "tls_locally_signed_cert" "server_cert" {
  cert_request_pem   = tls_cert_request.server_req.cert_request_pem
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 8760
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}
