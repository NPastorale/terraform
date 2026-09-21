# Cilium/Hubble mTLS material. Hubble relays use mutual TLS so that only
# trusted peers can read network flow data. These local certs are fed into the
# Cilium Helm release (hubble.tls.* values) and are NOT used for cluster auth.

# Root CA private key (Ed25519) for signing the Hubble server certificate.
resource "tls_private_key" "ca_key" {
  algorithm = "ED25519"
}

# Self-signed CA certificate (10y) used to sign and trust the Hubble server cert.
resource "tls_self_signed_cert" "ca_cert" {
  private_key_pem       = tls_private_key.ca_key.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = 87600 # 10 years
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

# Private key for the Hubble server certificate.
resource "tls_private_key" "server_key" {
  algorithm = "ED25519"
}

# CSR for the Hubble server cert, valid for *.${cluster}.hubble-grpc.cilium.io.
resource "tls_cert_request" "server_req" {
  private_key_pem = tls_private_key.server_key.private_key_pem
  subject {
    common_name = "*.${var.cluster_name}.hubble-grpc.cilium.io"
  }
}

# Hubble server certificate (1y) signed by the local CA above.
resource "tls_locally_signed_cert" "server_cert" {
  cert_request_pem      = tls_cert_request.server_req.cert_request_pem
  ca_private_key_pem    = tls_private_key.ca_key.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca_cert.cert_pem
  validity_period_hours = 8760 # 1 year
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}
