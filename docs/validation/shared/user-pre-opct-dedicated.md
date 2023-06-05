#### Environment Setup: Dedicated Node <a name="standard-env-setup-node"></a>

The `Dedicated Node` is a regular worker with additional label and taints to run the OPCT environment.

The following requirements must be satisfied:

1. Choose one node with at least 8GiB of RAM and 4 vCPU
2. Label node with `node-role.kubernetes.io/tests=""` (conformance-related pods will schedule to dedicated node)
3. Taint node with `node-role.kubernetes.io/tests="":NoSchedule` (prevent other pods from running on dedicated node)

Steps to setup the dedicated node:

```shell
oc label node <node_name> node-role.kubernetes.io/tests=""
oc adm taint node <node_name> node-role.kubernetes.io/tests="":NoSchedule
```