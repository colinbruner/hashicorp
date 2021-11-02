# Packer
Build out necessary AMIs for sandbox

# Creating Consul Certificates

```bash
# Create CA
consul tls ca create
# Create X number of certs for Consul servers being created
consul tls cert create -server -dc aws-us-east-1
```

## Fetch Base Nomad AMI for nomad_server build
```bash
# Build nomad_base_server
packer build -only="amazon-ebs.base_nomad_server" -var-file=vars/sandbox.pkrvars.hcl .

# Get the latest BASE_NOMAD_AMI
export BASE_NOMAD_AMI=$(cat manifests/nomad_base.json| jq -r '.builds[].artifact_id | split(":")[-1]' | tail -1)

# Build nomad_server
packer build -only="amazon-ebs.nomad_server" -var "base_nomad_ami=${BASE_NOMAD_AMI}" -var-file=vars/sandbox.pkrvars.hcl .
```
