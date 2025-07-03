# HTTPS support

HTTPS is required for all public web services. By default certificates will be
acquired via the ACME protocol (server is configurable, defaults to Let's
Encrypt staging), but certificates can be acquired via Azure Key Vault (via a
DigiCert or GlobalSign account) or generated externally and uploaded to Azure
Key Vault for use in the system.

## Requirements

In order to set up HTTPS support you'll also need to have [set up custom
domains](/docs/infra/set-up-custom-domains.md). This is because SSL/TLS
certificates must be properly configured for the specific domain to support
establishing secure connections.

## 1. Set desired certificates in domain configuration

By default the system will attempt to acquire a wildcard certificate for
subdomains of the network hosted zone. This supports the default setup where
each application/service has a subdomain on the relevant networks (and
temporary/PR environments for each of those services if utilized). If you wish
to opt-out of this automatic behavior, set `manage_certs = false` in the
`domain_config` block in the relevant networks, which will make the system do
nothing beyond what you configure in the certification configuration object.

For each custom domain you want to set up in the network, define a certificate
configuration object and set the `source` to `issued`. You'll probably want at
least one custom domain for each application/service in the network. The custom
domain must be either the same as the hosted zone or a subdomain of the hosted
zone.

If you have an existing certificate you wish to use, import it into the
Certificate Key Vault for the project. And set the `cert_name` parameter in the
env-config of every service you wish to use the certificate.

## 2. Update the network layer to issue the certificates

Run the following command to issue SSL/TLS certificates for each custom domain
configured:

```bash
make infra-update-network NETWORK_NAME=<NETWORK_NAME>
```

## 3. Attach certificate to load balancer

Run the following command to attach the SSL/TLS certificate to the load
balancer:

```bash
make infra-update-app-service APP_NAME=<APP_NAME> ENVIRONMENT=<ENVIRONMENT>
```
