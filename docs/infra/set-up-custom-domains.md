# Custom domains

You will need a hostname at which to host your project's web apps.  This
document describes how to configure custom domains. The custom domain setup
process will:

1. Create a hosted zone in Azure DNS to manage DNS records for a domain and
   subdomains
2. Create a DNS A (address) records to route traffic from a custom domain to the
   application's load balancer

## Requirements

Before setting up custom domains you'll need to have [set up the Azure
account](./set-up-azure-account.md)

## 1. Set hosted zone in domain configuration

Update the value for the `hosted_zone` in the domain configuration. The custom
domain configuration is defined as a `domain_config` object in the [network
section of the project config module](/infra/project-config/networks.tf). A
hosted zone represents a domain and all of its subdomains. For example, a hosted
zone of `platform-test-azure.navateam.com` includes
`platform-test-azure.navateam.com`, `cdn.platform-test-azure.navateam.com`,
`notifications.platform-test-azure.navateam.com`,
`foo.bar.platform-test-azure.navateam.com`, etc.

## 1b. Use a shared hosted zone

If your network administrator is able to delegate an entire subdomain to your
project's control (likely for just your lower environments), you can set
`shared_hosted_zone` in `/infra/project-config/networks.tf` to that domain,
which will cause the infrastructure to set up a single DNS hosted zone record in
the "shared" account that all the environments configured to use that domain
will insert their records into.

## 2. Update the network layer to create the hosted zone

Run the following command to create the hosted zone specified in the domain
configuration.

```bash
make infra-update-network NETWORK_NAME=<NETWORK_NAME>
```

## 3. Delegate DNS requests to the newly created hosted zone

You most likely registered your domain outside of this project. Using whichever
service you used to register the domain name (e.g. Namecheap, GoDaddy, Google
Domains, etc.), add a DNS NS (nameserver) record. Set the "name" equal to the
`hosted_zone` and set the value equal to the list of hosted zone name servers
that was created in the previous step. You can see the list of servers by
running

```bash
terraform -chdir=infra/networks output -json hosted_zone_name_servers
```

Your NS record might look something like this:

**Name**:

```text
platform-test-azure.navateam.com
```

**Value**: (Note the periods after each of the server addresses)

```text
"ns1-04.azure-dns.com.",
"ns2-04.azure-dns.net.",
"ns3-04.azure-dns.org.",
"ns4-04.azure-dns.info.",
```

Run the following command to verify that DNS requests are being served by the
hosted zone nameservers using `nslookup`.

```bash
nslookup -type=NS <HOSTED_ZONE>
```

## 4. Configure custom domain for your application

Define the `domain_name` for each of the application environments in the
`app-config` module. The `domain_name` must be either the same as the
`hosted_zone`, a subdomain of the `hosted_zone`, or a domain safe string that
will be treated as a subdomain of the network hosted zone. For example, if your
hosted zone is `platform-test-azure.navateam.com`, then
`platform-test-azure.navateam.com`, `cdn.platform-test-azure.navateam.com` and
`cdn` are all valid values for `domain_name`, with the latter two being
equivalent.

## 5. Create A (address) records to route traffic from the custom domain to your application's load balancer

Run the following command to create the A record that routes traffic from the
custom domain to the application's load balancer.

```bash
make infra-update-app-service APP_NAME=<APP_NAME> ENVIRONMENT=<ENVIRONMENT>
```

## 6. Repeat for each application

If you have multiple applications in the same network, repeat steps 4 and 5 for
each application.

## Externally managed DNS

If you plan to manage DNS records outside of the project, then set
`network_configs[*].domain_config.manage_dns = false` in the networks section of
the project-config module.
