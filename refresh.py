#!/usr/bin/env python3

import os
import sys
import time
import socket
from datetime import datetime, timedelta

import requests
import boto3

# AWS EC2 Client
ec2 = boto3.resource("ec2")

# The minimum number of seconds between instance termination
min_terminate_seconds = 120


# Headers to pass for authentication
headers = {
    "consul": {"X-Consul-Token": os.environ.get("CONSUL_HTTP_TOKEN")},
    "nomad": {"X-Nomad-Token": os.environ.get("NOMAD_TOKEN")},
    "vault": {"X-Vault-Token": os.environ.get("VAULT_TOKEN")},
}
# Environment variables for system tokens
env = {
    "consul": {"ADDR": "CONSUL_HTTP_ADDR", "TOKEN": "CONSUL_HTTP_TOKEN"},
    "vault": {"ADDR": "VAULT_ADDR", "TOKEN": "VAULT_TOKEN"},
    "nomad": {"ADDR": "NOMAD_ADDR", "TOKEN": "NOMAD_TOKEN"},
}

endpoints = {
    "consul": "/v1/operator/raft/configuration",
    "nomad": "/v1/operator/raft/configuration",
    "vault": "/v1/sys/storage/raft/configuration",
}

keymap = {
    "consul": {"node": "Node", "leader": "Leader", "voter": "Voter"},
    "nomad": {"node": "Node", "leader": "Leader", "voter": "Voter"},
    "vault": {"node": "node_id", "leader": "leader", "voter": "voter"},
}


# class Peer:
#    def __init__(self, system):
#        self.system = system
#        self.headers = headers[system]
#
#    def raft_config(self):
#        return requests.get(system_url, headers=self.headers).json()


def preflight_sanity():
    """Verify token / address are in place before continuing."""
    # TODO: Preflight auth test, correct token?

    # .values() returns a 'view', need to cast to list to determine if any elements exist
    if not list(headers[system].values())[0]:
        print(f"Token for {system} is not defined. Please export {tokens[system]} and try again.")
        sys.exit(1)

    # Remove any 'https://' protocol strings, remove any ending (e.g.) ':8200' port strings
    if ":" in system_addr:
        system_hostname = system_addr.split("://")[1].split(":")[0]

    if not socket.gethostbyname(system_hostname):
        print(f"Unable to resolve {system_hostname} based off environment variables.")
        sys.exit(2)

    # Final check print account ID
    print("Checking authentication against AWS.")
    print(
        f"Success. Will continue under AccountID {boto3.client('sts').get_caller_identity()['Account']}"
    )
    return True


def get_peers():
    """Fetch all node JSON via systems API"""
    data = requests.get(system_url, headers=headers[system]).json()
    if system == "consul" or "nomad":
        return data["Servers"]
    elif system == "vault":
        return data["data"]["config"]["servers"]


def check_cluster_peers(waiting=bool) -> bool:
    """Check if the current total of peers equals the original total number of peers"""
    current_peers = get_peers()
    current_total_peers = len(current_peers)

    if current_total_peers == total_peers:
        # Original number of peers are back.
        print(
            f"Determined {current_total_peers} peers out of an expected total: {total_peers} peers have joined the cluster."
        )

        # We need Voter = True on the last instance to be included in the cluster. Check last element of list to confirm.
        # TODO: This is not authorative, I don't know if the order will be the same across systems and this could fail.
        if not current_peers[-1][voter_key]:
            print(f"Peer has not registered as a voter, sleeping for 5s")
            time.sleep(5)
            return True
        else:
            print(f"Peer has synced raft data successfully, continuing.")
            return False
    else:
        print(
            f"Sleeping for 10s to wait for a total of {total_peers} {system.title()} Servers to join the cluster."
        )
        time.sleep(10)
        return True


def terminate_peer(peer):
    """
    Terminate an EC2 instance by instance ID.
    returns: datetime object representing time since last terminated
    """
    # Nomad is special, and will include '.region' aloong with Node ID e.g. 'i-0b9efdb21a715536f.us-east-1'
    node = peer[node_key].split(".")[0]
    leader = peer[leader_key]

    print(f"Cycling Node: {node} -- Leader: {leader}")
    ec2.instances.filter(InstanceIds=[node]).terminate()
    print(f"Successfully Terminated Instance")

    # Returns the datetime representation of last terminated instance
    return datetime.now()


def safety_pause(terminated_time):
    """Prevent any node from being terminated earlier than 'min_terminate_seconds'"""
    seconds_since_last_terminated = int()

    # Ensure least 2minutes before terminating a 2nd instance
    while seconds_since_last_terminated < min_terminate_seconds:
        print(
            f"Terminated last instance {seconds_since_last_terminated} seconds ago. Waiting at least {min_terminate_seconds} before checking cluster status."
        )
        time.sleep(10)

        # Calculate how long its been since the last instance was terminated.
        seconds_since_last_terminated = (datetime.now() - terminated_time).seconds


def main():
    print(f"Calculated {total_peers} peers exist within the cluster.")
    for peer in peers:
        waiting = True

        # Ensure cluster has its initial total number of peers
        while waiting:
            waiting = check_cluster_peers(waiting)

        # Terminate the instance
        terminated_time = terminate_peer(peer)

        # Prevent terminations sooner than 'min_terminate_seconds'
        safety_pause(terminated_time)

    print(f"Refreshed {total_peers} successfully.")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Refresh a Hashicorp system to upgrade its AMI.")
    parser.add_argument(
        "--system",
        help="The name of the system to run against.",
        choices=["consul", "vault", "nomad"],
        type=str,
        required=True,
    )
    args = parser.parse_args()

    # Working with only a single system, this will be our pointer
    system = args.system

    system_addr = os.environ.get(env[system]["ADDR"])
    # Hostname + API URI
    system_url = system_addr + endpoints[system]

    # Shortcuts for accessing keys within returned `get_peers()` data.
    node_key = keymap[system]["node"]
    leader_key = keymap[system]["leader"]
    voter_key = keymap[system]["voter"]

    ###
    # Sanity
    ###
    # Make sure tokens are set
    preflight_sanity()

    ###
    # Initial Values
    ###
    # Total Peers
    peers = get_peers()
    # Move 'Leader' to end of the list
    peers.append(peers.pop(0))
    # Initial Total Peers count
    total_peers = len(peers)

    main()
