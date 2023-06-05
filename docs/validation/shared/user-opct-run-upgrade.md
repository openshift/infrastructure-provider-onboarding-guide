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