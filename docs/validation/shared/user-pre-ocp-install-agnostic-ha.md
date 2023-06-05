#### Standard Environment <a name="standard-env"></a>

A Red Hat OpenShift 4 cluster must be [installed](https://docs.openshift.com/container-platform/latest/installing/index.html) before validation can begin. The OpenShift cluster must be installed on your infrastructure as if it were a production environment. Ensure that each feature of your infrastructure you plan to support with OpenShift is configured in the cluster (e.g. Load Balancers, Storage, special hardware).

A dedicated compute node should be used to avoid disruption of the test scheduler. Otherwise, the concurrency between resources scheduled on the cluster, e2e-test manager (aka openshift-tests-plugin), and other stacks like monitoring can disrupt the test environment, leading to unexpected results, like the eviction of plugins or aggregator server (`sonobuoy` pod).

The dedicated node environment cluster size can be adjusted to match the table below. Note the differences in the `Dedicated Test` machine:

| Machine       | Count | CPU | RAM (GB) | Storage (GB) |
| ------------- | ----- | --- | -------- | ------------ |
| Bootstrap     | 1     | 4   | 16       | 100          |
| Control Plane | 3     | 4   | 16       | 100          |
| Compute       | 3     | 4   | 16       | 100          |
| Dedicated Test| 1     | 4   | 8        | 100          |

*Note: These requirements are higher than the [minimum requirements](https://docs.openshift.com/container-platform/latest/installing/installing_bare_metal/installing-bare-metal.html#installation-minimum-resource-requirements_installing-bare-metal) for a regular cluster (non-validation) in OpenShift product documentation due to the resource demand of the conformance environment.*