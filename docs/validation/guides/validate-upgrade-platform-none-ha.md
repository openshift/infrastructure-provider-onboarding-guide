# OpenShift Installation Validation | Upgrade | Platform None HighAvailability Topology

This guide describes how to run Upgrade Conformance tests in an agnostic OpenShift installation.

--8<-- "docs/validation/shared/user-ccsp-process-overview.md"

## Prerequisites

### OpenShift Installation

--8<-- "docs/validation/shared/user-pre-ocp-install-agnostic-ha.md"

#### Setup MachineConfigPool for upgrade tests <a name="standard-env-setup-mcp"></a>

**Note**: The `MachineConfigPool` should be created only when the OPCT execution mode (`--mode`) is `upgrade`. If you are not running upgrade tests, please skip this section.

One `MachineConfigPool`(MCP) with the name `opct` must be created, selecting the dedicated node labels. The MCP must be `paused`, thus the node running the validation environment will not be restarted while the cluster is upgrading, avoiding disruptions to the conformance results.

You can create the `MachineConfigPool` by running the following command:

```bash
cat << EOF | oc create -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfigPool
metadata:
  name: opct
spec:
  machineConfigSelector:
    matchExpressions:
    - key: machineconfiguration.openshift.io/role,
      operator: In,
      values: [worker,opct]
  nodeSelector:
    matchLabels:
      node-role.kubernetes.io/tests: ""
  paused: true
EOF
```

Make sure the `MachineConfigPool` has been created correctly:

```bash
oc get machineconfigpool opct
```

### Validation Tool: OPCT

--8<-- "docs/validation/shared/user-pre-opct.md"

--8<-- "docs/validation/shared/user-pre-opct-dedicated.md"

--8<-- "docs/validation/shared/user-pre-opct-privileges.md"

--8<-- "docs/validation/shared/user-pre-opct-install.md"

<!-- Running validation tests -->

--8<-- "docs/validation/shared/user-opct-run.md"

<!-- --8<-- "docs/validation/shared/user-opct-run-upgrade.md" -->

#### Run the `upgrade` mode <a name="usage-run-upgrade"></a>

The `upgrade` mode runs the OpenShift cluster updates to the `4.y+1` version, then the regular conformance suites will be executed (Kubernetes and OpenShift). This mode was created to validate the entire update process, and to make sure the target OCP release is validated on the conformance suites.

> Note: If you will submit the results to Red Hat Partner Support, you must have Validated the installation on the initial release using the regular execution. For example, to submit the upgrade tests for 4.11->4.12, you must have submitted the regular tests for 4.11. If you have any questions, ask your Red Hat Partner Manager.

Requirements for running the `upgrade` mode:

- You have created the `MachineConfigPool` with name `opct`
- You have installed the OpenShift client locally (`oc`) - or have noted the Image `Digest` of the target release
- You must choose the next release of Y-stream (`4.Y+1`) supported by your current release. (See [update graph](https://access.redhat.com/labs/ocpupgradegraph/update_path))

```sh
openshift-provider-cert run --mode=upgrade --upgrade-to-image=$(oc adm release info 4.Y+1.Z -o jsonpath={.image})
```


--8<-- "docs/validation/shared/user-opct-run-options.md"

--8<-- "docs/validation/shared/user-opct-monitor-collect.md"

<!-- Reading results validation tests -->

--8<-- "docs/validation/shared/user-opct-results.md"

<!-- ccsp submit -->

--8<-- "docs/validation/shared/user-ccsp-submit.md"

<!-- Destroy validation process -->

--8<-- "docs/validation/shared/user-opct-destroy.md"