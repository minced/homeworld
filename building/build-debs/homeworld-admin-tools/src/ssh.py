import os
import subprocess
import tempfile

import configuration
import util

SSH_BASE = ["ssh", "-o", "StrictHostKeyChecking=yes", "-o", "ConnectTimeout=1"]
SCP_BASE = ["scp", "-o", "StrictHostKeyChecking=yes", "-o", "ConnectTimeout=1"]


def ssh_get_login(node: configuration.Node) -> str:  # returns root@<HOSTNAME>.<EXTERNAL_DOMAIN>
    config = configuration.get_config()
    return "root@%s.%s" % (node.hostname, config.external_domain)


def build_ssh(node: configuration.Node, *script: str) -> list:
    return SSH_BASE + [ssh_get_login(node), "--"] + list(script)


def build_scp_up(node: configuration.Node, source_path: str, dest_path: str) -> list:
    return SCP_BASE + ["--", source_path, ssh_get_login(node) + ":" + dest_path]


def check_ssh(node: configuration.Node, *script: str) -> None:
    subprocess.check_call(build_ssh(node, *script))


def check_ssh_output(node: configuration.Node, *script: str) -> bytes:
    return subprocess.check_output(build_ssh(node, *script))


def check_scp_up(node: configuration.Node, source_path: str, dest_path: str) -> None:
    subprocess.check_call(build_scp_up(node, source_path, dest_path))


def upload_bytes(node: configuration.Node, source_bytes: bytes, dest_path: str) -> None:
    # tempfile.TemporaryDirectory() creates the directory with 0o600, which protects the data if it's sensitive
    with tempfile.TemporaryDirectory() as scratchdir:
        scratchpath = os.path.join(scratchdir, "scratch")
        util.writefile(scratchpath, source_bytes)
        check_scp_up(node, scratchpath, dest_path)
        os.remove(scratchpath)
