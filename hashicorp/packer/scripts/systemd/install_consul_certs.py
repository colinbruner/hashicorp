#!/usr/bin/env python3

###
# INSECURE: This. This is definitely not secure. Please do not use this method in production.
# There are better ways to distribute certs, please don't use this outside of a demo.
###

import os
import boto3
import fileinput
import urllib.request


def _get_metadata():
    """ Return instance_id, region in a tuple """
    instance_id = (
        urllib.request.urlopen("http://169.254.169.254/latest/meta-data/instance-id")
        .read()
        .decode()
    )
    # Trim last character off, just need region not region specific AZ (e.g. us-east-1c)
    region = (
        urllib.request.urlopen(
            "http://169.254.169.254/latest/meta-data/placement/availability-zone"
        )
        .read()
        .decode()[:-1]
    )

    return (instance_id, region)


def _get_name_tag(instance):
    # Only 1 instance should be returned
    for tag in instance["Reservations"][0]["Instances"][0]["Tags"]:
        if tag["Key"] == "Name":
            return tag["Value"]
    return False


def _install_certs(certs):
    """Move instance specific certs from their initial location, installed by Packer, into their
    proper place within the consul.d/ directory."""

    init_dir = "/home/ubuntu/certs"  # Where certs are initially installed
    cert_dir = "/etc/pki/tls/certs"  # Where certs need to go
    key_dir = "/etc/pki/tls/private"  # Where keys need to go

    for cert in certs:
        if not os.path.exists(f"/{cert}"):
            # Move, Own, Mod
            os.system(f"sudo mv {init_dir}/{cert} {cert_dir}/{cert}")
            os.system(f"sudo chown consul:consul {cert_dir}/{cert}")
            os.system(f"sudo chmod 600 {cert_dir}/{cert}")
        else:
            print(f"Certificate {cert} already exists within consul.d directory. Continuing...")

    # One more certificate to move. This is expected on all Consul servers and thus is hardcoded
    # within the server.hcl, unlike the previous two certs.
    ca_cert = "consul-agent-ca.pem"

    os.system(f"sudo mv {init_dir}/{ca_cert} {key_dir}/{ca_cert}")
    os.system(f"sudo chown consul:consul {key_dir}/{ca_cert}")
    os.system(f"sudo chmod 600 {key_dir}/{ca_cert}")


def _edit_server_hcl(certs):
    """ Edit the server.hcl in place to point to the correct certs, now properly in consul.d/ """
    with fileinput.FileInput("/etc/consul.d/server.hcl", inplace=True) as f:
        # Iterate over the file in memory, replace whats needed, print out to file if not.
        for line in f:
            if "PLACEHOLDER.pem" in line:
                print(line.replace("PLACEHOLDER.pem", certs[0]), end="")
            elif "PLACEHOLDER-key.pem" in line:
                print(line.replace("PLACEHOLDER-key.pem", certs[1]), end="")
            else:
                print(line, end="")
    os.system("sudo chown consul:consul /etc/consul.d/server.hcl")


def main():
    # Fetch datacenter from environment
    datacenter = os.environ.get("CONSUL_DATACENTER", "dc1")

    instance_id, region = _get_metadata()

    ec2 = boto3.client("ec2", region_name=region)
    instance = ec2.describe_instances(InstanceIds=[instance_id])

    instance_name = _get_name_tag(instance)

    # expects tag to look like: 'consul-server-0'
    count = instance_name.split("-")[-1]

    # the certs actually tied to the system
    certs = [f"{datacenter}-server-consul-{count}.pem", f"{datacenter}-server-consul-{count}-key.pem"]

    _install_certs(certs)
    _edit_server_hcl(certs)

if __name__ == "__main__":
    main()
