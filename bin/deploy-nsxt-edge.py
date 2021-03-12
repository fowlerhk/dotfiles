#!/usr/bin/env python3
#
# Helper script to deploy an NSX-T Edge VM.
# This is intended for deployments to your own ESX host, where the Host is
# managed by a VC. SSH is always enabled, root logins are allowed, and thin
# provisioning is used.
#
import argparse
import re
import subprocess
import sys

#
# VC info. ********* ADJUST ACCORDING TO YOUR OWN SETUP **********
#
VCUSER="administrator@vsphere.local"
VCPASS="Admin!23Admin"
VCIP="10.20.119.89"
VCDATACENTER="Datacenter"
VCCLUSTER="Cluster"
DATASTORE="DatastoreSSD"
RESOURCEPOOL="Transformers"
NETWORK0="Network 0=VM Network"


TARGET="vi://$VCUSER:$VCPASS@$VCIP/$VCDATACENTER/host/$VCCLUSTER/Resources/$RESOURCEPOOL"

EDGEPASSWORD="Admin!23Admin" # Used for root and admin

BUILD_URL_PREFIX="http://build-squid.eng.vmware.com/build/mts/release/"
OVFTOOL_BIN="/build/toolchain/lin64/ovftool-4.3.0/ovftool"



def run_cmd(cmd_list, display=False):
    if display:
        out_stream = sys.stdout
        err_stream = sys.stdout
    else:
        out_stream = subprocess.PIPE
        err_stream = subprocess.PIPE
    p = subprocess.Popen(cmd_list, stdout=out_stream, stderr=err_stream, shell=False)
    if display:
        p.wait()
    out, err = p.communicate()
    # In Python3, communicate() returns byte strings, so convert to string
    if out is not None:
        out = out.decode("utf-8", "strict")
    if err is not None:
        err = err.decode("utf-8", "strict")
    rc = p.returncode
    return rc, out, err


def get_build_ovf_url(buildid):
    """Function to return the OVF URL for the given build id.

    The build version number can change over time, and is not provided by
    the user. So, this function will try to figure out the version number by downloading
    and index html file from buildweb, and then constructing the actual filename of the
    OVF file.

    Args:
        buildid - string containing the build id. e.g. "sb-12345678", or "ob-87654321".

    Returns:
        Complete URL of the Edge VM's OVF file on buildweb, or None on failure.
    """
    version = None
    buildtype, buildnum = buildid.split("-")
    url = BUILD_URL_PREFIX
    # OB and SB published files are stored in slightly different directory structures.
    # Account for that here.
    if buildtype == "ob":
        url += "bora-"
    else:
        url += "sb-"
    url += buildnum

    # Let's check if this build number is for nsx-transformers or nsx-edgenode.
    # Look at the publish dir on buildweb and see if "nsx-edgenode/" dir is there. If so,
    # then this is an nsx-transformers build, otherwise assume an nsx-edgenode build.
    url += "/publish/"
    cmd = ["wget", "-nv", "-O-", url]
    rc, out, err = run_cmd(cmd)
    if rc != 0:
        print("ERROR: Failed to get buildweb listing. {}".format(err))
        return None

    is_nsx_transformers = False
    re_pattern = "nsx-edgenode/"
    for line in out.split("\n"):
        match = re.search(re_pattern, line)
        if match:
            is_nsx_transformers = True

    if is_nsx_transformers:
        url += "nsx-edgenode/exports/ovf/"
    else:
        url += "exports/ovf/"

    # Get a listing of the ovf directory on buildweb to determine the exact OVF filename.
    #
    # The following wget call will return HTML like the following example:
    # <html>
    # <head><title>Index of /build/storage61/release/bora-17044750/publish/exports/ovf/</title></head>
    # <body bgcolor="white">
    # <h1>Index of /build/storage61/release/bora-17044750/publish/exports/ovf/</h1><hr><pre><a href="../">../</a>
    # <a href="nsx-edge-3.0.2.0.1.17044750.cert">nsx-edge-3.0.2.0.1.17044750.cert</a>                   16-Oct-2020 16:28                1926
    # <a href="nsx-edge-3.0.2.0.1.17044750.mf">nsx-edge-3.0.2.0.1.17044750.mf</a>                     16-Oct-2020 16:28                 142
    # <a href="nsx-edge-3.0.2.0.1.17044750.ovf">nsx-edge-3.0.2.0.1.17044750.ovf</a>                    16-Oct-2020 16:27               31253
    # <a href="nsx-edge.vmdk">nsx-edge.vmdk</a>                                      16-Oct-2020 16:27          2730201088
    # </pre><hr></body>
    # </html>
    cmd = ["wget", "-nv", "-O-", url]
    rc, out, err = run_cmd(cmd)
    if rc != 0:
        print("ERROR: Failed to get buildweb listing. {}".format(err))
        return None

    filename = None
    re_pattern = "href=\"(nsx-.*\.ovf)\">"
    for line in out.split("\n"):
        match = re.search(re_pattern, line)
        if match:
            filename = match.group(1)
    if filename == None:
        print("ERROR: Failed to determine build OVF filename.")
        return None

    url += filename
    return url


def get_ovftool_cmd(url, name, size, is_autoedge, poweron):
    cmd = [OVFTOOL_BIN,
           "--acceptAllEulas",
           "--allowExtraConfig",
           "--allowAllExtraConfig",
           "--deploymentOption={}".format(size),
           "--noSSLVerify",
           "--name={}".format(name),
           "--datastore={}".format(DATASTORE),
           "--diskMode=thin",
           "--net:{}".format(NETWORK0),
           "--prop:nsx_isSSHEnabled=True",
           "--prop:nsx_allowSSHRootLogin=True",
           "--prop:nsx_cli_passwd_0={}".format(EDGEPASSWORD),
           "--prop:nsx_passwd_0={}".format(EDGEPASSWORD)]
    if is_autoedge:
        cmd.append("--prop:is_autonomous_edge=True")
    if poweron:
        cmd.append("--powerOn")
    cmd.append(url)
    target = "vi://{}:{}@{}/{}/host/{}/Resources/{}".format(
                    VCUSER, VCPASS, VCIP, VCDATACENTER, VCCLUSTER, RESOURCEPOOL)
    cmd.append(target)
    return cmd


def deploy_edge_vm(buildid, name, size, is_auto_edge, poweron):
    url = get_build_ovf_url(buildid)
    if not url:
        print("ERROR: Failed to determine the build URL.")
        return
    deploy_cmd = get_ovftool_cmd(url, name, size, is_auto_edge, poweron)
    print("Ovftool command: " + " ".join(deploy_cmd))
    return run_cmd(deploy_cmd, True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Deploy NSX-T Edge")
    parser.add_argument("--size", default="small", choices=["small", "medium", "large", "xlarge"],
                        help="Edge VM size. Default: small.")
    parser.add_argument("--auto", default=False, action='store_true', help="Deploy Edge as Autonomous Edge")
    parser.add_argument("--poweron", default=False, action='store_true', help="Power-on the Edge VM after deployment.")
    parser.add_argument("buildid", help="The build to deploy, e.g. sb-12345678")
    parser.add_argument("name", help="Name of the deployed Edge VM")
    args = parser.parse_args()

    rc, out, err = deploy_edge_vm(args.buildid, args.name, args.size, args.auto, args.poweron)
    if rc != 0:
        print("ERROR: Failed to deploy Edge VM.\n{}".format(err))

