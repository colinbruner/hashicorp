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


class System:
    # Headers to pass for authentication
    _headers = {
        "consul": {"X-Consul-Token": os.environ.get("CONSUL_HTTP_TOKEN")},
        "nomad": {"X-Nomad-Token": os.environ.get("NOMAD_TOKEN")},
        "vault": {"X-Vault-Token": os.environ.get("VAULT_TOKEN")},
    }
    # Environment variables for system tokens
    _env = {
        "consul": {"ADDR": "CONSUL_HTTP_ADDR", "TOKEN": "CONSUL_HTTP_TOKEN"},
        "vault": {"ADDR": "VAULT_ADDR", "TOKEN": "VAULT_TOKEN"},
        "nomad": {"ADDR": "NOMAD_ADDR", "TOKEN": "NOMAD_TOKEN"},
    }

    _api_raft_config = {
        "consul": "/v1/operator/raft/configuration",
        "nomad": "/v1/operator/raft/configuration",
        "vault": "/v1/sys/storage/raft/configuration",
    }
    _api_raft_remove = {"vault": "/v1/sys/storage/raft/remove-peer", "consul": "", "nomad": ""}

    _keymap = {
        "consul": {"node": "Node", "leader": "Leader", "voter": "Voter"},
        "nomad": {"node": "Node", "leader": "Leader", "voter": "Voter"},
        "vault": {"node": "node_id", "leader": "leader", "voter": "voter"},
    }

    def __init__(self, system):
        self.name = system
        # API
        self.address = os.environ.get(self._env[system]["ADDR"])
        self.headers = self._headers[system]

        # Sanity
        self.address_name = self._env[self.name]["ADDR"]
        self.token_name = self._env[self.name]["TOKEN"]

        # Shortcuts for accessing keys within returned `get_peers()` data.
        self.node_key = self._keymap[system]["node"]
        self.leader_key = self._keymap[system]["leader"]
        self.voter_key = self._keymap[system]["voter"]

        ###
        # API Access URLs
        ###
        self.raft_config_url = self.address + self._api_raft_config[system]
        # Only implemented for vault currently.
        self.raft_delete_url = self.address + self._api_raft_remove[system]

    def preflight_checks(self):
        """Verify token / address are in place before continuing."""
        # TODO: Preflight auth test, correct token?

        # Check that an address has been provided within environment variables.
        if not self.address:
            print(f"ERROR: Address for {self.name} is not defined. Please export {self.address_name} and try again.")
            sys.exit(1)
        else:
            print(f"Success: Address {self.address} for {self.name} found within environment variables.")

        # Check that a token has been provided within environment variables.
        # .values() returns a 'view', need to cast to list to determine if any elements exist
        if not os.environ.get(self.token_name):
            print(f"ERROR: Token for {self.name} is not defined. Please export {self.token_name} and try again.")
            sys.exit(1)
        else:
            print(f"Success: Token for {self.name} found with environment variables.")

        # In order to validate we can resolve the hostname:
        # remove any 'https://' protocol strings,
        # remove any ending (e.g.) ':8200' port strings
        if ":" in self.address:
            system_hostname = self.address.split("://")[1].split(":")[0]

        try:
            socket.gethostbyname(system_hostname)
        except socket.gaierror:
            print(f"ERROR: Unable to resolve {system_hostname}.")
            sys.exit(2)
        else:
            print(f"Success: Resolved {system_hostname} address.")

        # Final check print account ID
        print(
            f"Success: Authenticated to AWS. Will continue under AccountID {boto3.client('sts').get_caller_identity()['Account']}"
        )

    def get_raft_config(self) -> list:
        """Gets raft configuration for a cluster."""
        data = requests.get(self.raft_config_url, headers=self.headers).json()
        if self.name == "consul" or self.name == "nomad":
            return data["Servers"]
        elif self.name == "vault":
            return data["data"]["config"]["servers"]

    def check_cluster_peers(self, waiting=bool) -> bool:
        """Check if the current total of peers equals the original total number of peers"""
        current_peers = self.get_raft_config()
        current_total_peers = len(current_peers)

        if current_total_peers == total_peers:
            # Original number of peers are back.
            print(
                f"Determined {current_total_peers} peers out of an expected total: {total_peers} peers have joined the cluster."
            )

            # We need Voter = True on the last instance to be included in the cluster. Check last element of list to confirm.
            # TODO: This is not necessarily authorative, I don't know if the order will be the same across systems so this could fail?
            if not current_peers[-1][self.voter_key]:
                print(f"Peer has not registered as a voter, sleeping for 5s")
                time.sleep(5)
                return True
            else:
                print(f"Peer has registered as a voter and synced raft data successfully, continuing.")
                return False
        else:
            print(
                f"Sleeping for 10s to wait for a total of {total_peers} {self.name.title()} Servers to join the cluster."
            )
            time.sleep(10)
            return True

    def remove_peer(self, peer=dict):
        """
        Removes a Peer from Vaults raft configuration.
        This currently only applies to Vault systems.
        """
        if self.name != "vault":
            print(f"ERROR: Removing a peer from raft configuration is not implemented for {self.name.title()}")
            raise (NotImplemented)

        # Remove a peer by 'server_id', its node identifier
        node = peer[self.node_key]

        data = requests.post(self.raft_delete_url, data={"server_id": node}, headers=self.headers)
        # Vault returns a 204, 'No Content'. Not really sure how to error handle this, so just exiting.
        if data.status_code == 204:
            print(f"Successfully removed {node} from {self.name.title()}'s raft configuration.")
        else:
            print(f"ERROR Unable to remove {node} from raft. Exiting now, please review.")
            sys.exit(3)

    def terminate_peer(self, peer=dict):
        """
        Terminate an EC2 instance by instance ID.
        returns: datetime object representing time since last terminated
        """
        # Nomad is special, and will include '.region' aloong with Node ID e.g. 'i-0b9efdb21a715536f.us-east-1'
        node = peer[self.node_key].split(".")[0]
        leader = peer[self.leader_key]

        print(f"Cycling Node: {node} -- Leader: {leader}")
        ec2.instances.filter(InstanceIds=[node]).terminate()
        print(f"Successfully Terminated Instance")

        # Returns the datetime representation of last terminated instance
        return datetime.now()

    def safety_pause(self, terminated_time):
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


def main(system: System, peers=list, total_peers=int):
    print(f"Calculated {total_peers} peers exist within the cluster.")

    for peer in peers:
        waiting = True

        # Ensure cluster has its initial total number of peers
        while waiting:
            waiting = system.check_cluster_peers(waiting)

        # Vault does not set 'cleanup_dead_servers' to True by default. When cycling peers, they must
        # be manually cleaned up unless this autopilot setting is enabled.
        if system.name == "vault":
            system.remove_peer(peer)

        # Terminate the instance
        terminated_time = system.terminate_peer(peer)

        # Prevent terminations sooner than 'min_terminate_seconds'
        system.safety_pause(terminated_time)

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
    system = System(args.system)

    ###
    # Sanity
    ###
    # Run preflight checks before beginning
    system.preflight_checks()

    ###
    # Initial Values
    ###
    # Total Peers
    peers = system.get_raft_config()
    # Move 'Leader' to end of the list
    peers.sort(key=lambda x: x[system.leader_key] == True)
    # Initial Total Peers count
    total_peers = len(peers)

    main(system, peers, total_peers)
