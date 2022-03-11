# Container Storage Interface Driver

## Goal

In the end, OpenShift installation should provide a cluster that is usable out of the box. Users can create PVCs or StatefulSets and get a decent storage for them.

* Install one CSI driver, the most useful for the platform. Usually it’s one that provides block volumes (AWS EBS, GCP PD, Azure Disk, OpenStack Cinder, ...).
* Provide *one* default StorageClass that is good for a generic usage. Not too expensive, but not too slow either.
  * Each cluster is different, don’t anticipate application needs, leave creation of additional StorageClasses to the cluster administrators. They know better what they need.
* If the platform provides more storage backends, provide CSI drivers for them via OLM. This is out of scope of this guide, but library-go can be used for it too, see [AWS EFS CSI driver operator](https://github.com/openshift/aws-efs-csi-driver-operator). It even supports un-installation of the CSI driver.

## Overview

### Installation workflow

Using GCP cloud and its Persistent Disk (PD) CSI driver as an example, but it works exactly the same on other platforms.
During cluster installation, following things happen:

* `cluster-version-operator` (CVO) starts [`cluster-storage-operator`](https://github.com/openshift/cluster-storage-operator) (CSO) in namespace `openshift-cluster-storage-operator`. CVO does it by blindly applying YAML files in [`manifest/`](https://github.com/openshift/cluster-storage-operator/tree/master/manifests) directory of the operator image.
  * Notice that manifests in `cluster-storage-operator` image will have the correct references to all images of all CSI drivers, CSI driver operators, CSI sidecars and so on. We have an [automation]() that replaces [the image names from `quay.io/openshift`](https://github.com/openshift/cluster-storage-operator/blob/f8eda8eeaba9ec2f275431e95555fa05a8c6fa81/manifests/10_deployment.yaml#L57-L124) to `registry.redhat.io` during release build. The operator gets them as env. variables.
* `cluster-storage-operator` sees that it runs on platform GCP and starts the [GCP PD CSI driver operator](https://github.com/openshift/gcp-pd-csi-driver-operator) in namespace `openshift-cluster-csi-drivers` and creates `ClusterCSIDriver` CR for it.
  * `cluster-storage-operator` passes the correct images that the CSI driver operator should use as [env. variables of the operator Deployment](https://github.com/openshift/cluster-storage-operator/blob/f8eda8eeaba9ec2f275431e95555fa05a8c6fa81/assets/csidriveroperators/gcp-pd/07_deployment.yaml#L24-L39).
* GCP PD CSI driver operator observes its `ClusterCSIDriver` CR and installs GCP PD CSI driver. The operator reports the status of the installation to the `ClusterCSIDriver` CR status.
  * GCP PD CSI driver operator gets all images that it should use for the driver + sidecars as env. vars.
* `cluster-storage-operator` observes `ClusterCSIDriver` CR status and reports its status to `cluster-version-operator` using [ClusterOperator](https://github.com/openshift/enhancements/blob/master/dev-guide/cluster-version-operator/dev/clusteroperator.md) CR.
* `cluster-version-operator` reports installation/upgrade status to `ClusterVersion` CR.


### Upgrade

Upgrade works in exactly the same way as installation, except that `cluster-storage-operator`, CSI driver operator and the CSI driver are updated, i.e. their `Deployment` / `DaemonSets` are updated instead of created. Updated image names are propagated exactly as during the installation - as env. variables from CVO through CSO to CSI driver operator(s).

### Cluster Un-installation

Nothing is needed from the driver or its operator during cluster un-installation. However,
`openshift-install destroy cluster` itself should destroy all volumes that were dynamically provisioned in the cluster. In other words:

1. The CSI driver must tag / label all volumes created during the cluster lifetime with the cluster ID. Most CSI drivers have a special argument to add tags to all created volumes. Their CSI driver operator can file it easily. See [GCP PD CSI driver operator that sets tag (=label in GCP jargon) `kubernetes-io-cluster-${CLUSTER_ID}=owned`](https://github.com/openshift/gcp-pd-csi-driver-operator/blob/223a251c3ba39d8af605258d14794b32a5cfafda/assets/controller.yaml#L51).
2. `openshift-install destroy cluster` must list all volumes that are tagged with the cluster ID and delete them. See [code for GCP PD](https://github.com/openshift/installer/blob/3f318d7049d5f4b6f98211b4b899fdb43b1f3542/pkg/destroy/gcp/disk.go#L86).

### `ClusterCSIDriver`

`ClusterCSIDriver` is a [Custom Resource](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/). Its CRD is created during cluster installation. Each CSI driver operator uses its own dedicated CR name. For example, GCP PD CSI driver operator uses ClusterCSIDriver instance named [`pd.csi.storage.gke.io`](https://github.com/openshift/cluster-storage-operator/blob/master/assets/csidriveroperators/gcp-pd/08_cr.yaml). See [openshift/api repository](https://github.com/openshift/api/blob/b632c5fc10c0ea86cb18577db9388109a43d465f/operator/v1/types_csi_cluster_driver.go#L26) for details about the available fields in the CR and for allowed CSI drivers.

The ClusterCSIDriver is heavily based on [ClusterOperator CR](https://github.com/openshift/enhancements/blob/master/dev-guide/cluster-version-operator/dev/clusteroperator.md) - it has the same [`Spec`](https://github.com/openshift/api/blob/b632c5fc10c0ea86cb18577db9388109a43d465f/operator/v1/types.go#L51) and [`Status`](https://github.com/openshift/api/blob/b632c5fc10c0ea86cb18577db9388109a43d465f/operator/v1/types.go#L109).

`ClusterCSIDriver` does not provide any configuration of the operator nor the driver except for log level, both of [the operator](https://github.com/openshift/api/blob/b632c5fc10c0ea86cb18577db9388109a43d465f/operator/v1/types.go#L71) and its [operand](https://github.com/openshift/api/blob/b632c5fc10c0ea86cb18577db9388109a43d465f/operator/v1/types.go#L62) (=the CSI driver). A CSI driver operator should install the CSI driver with some default parameters that suit the best in OpenShift. If the operator needs it, it can get parameters from install-config or other OCP components by getting corresponding API objects - most of the cluster is up and running at the time CSI driver operator starts.

Using [`ClusterCSIDriver.Status`](https://github.com/openshift/api/blob/b632c5fc10c0ea86cb18577db9388109a43d465f/operator/v1/types.go#L109) the CSI driver operator reports status of the CSI driver "up the chain", to `cluster-storage-operator`. Especially see [`ClusterCSIDriver.Status.Conditions`](https://github.com/openshift/api/blob/b632c5fc10c0ea86cb18577db9388109a43d465f/operator/v1/types.go#L116), they're directly transferred by `cluster-storage-operator` to overall status of storage in `ClusterOperator` CR.

### `openshift/library-go`

[`openshift/library-go`](https://github.com/openshift/library-go/) is a collection of functions that allow us to build OpenShift operators easily. Most of the functionality of a CSI driver operator is already available there.

In the ideal case, a CSI driver operator just provides yaml files of the CSI driver (`Deployment`, `DaemonSet`, `ServiceAccount`, `Role`, `ClusterRole`, `RoleBindings`, `ClusterRoleBindings`, ...) and initializes + starts library-go Controllers that handle the rest.

There is already a lot of internal OpenShift knowledge in these controllers, for example:
* Inject cluster-wide HTTP proxy to driver pods.
* Inject custom CA bundles to the driver pods.
* Put the controller Pods to the master nodes (if they’re available).
* Scale down nr. of controller Pods on single-node cluster.
* Configure leader-election of the CSI sidecar appropriately for the platform.
* (Optionally) restart CSI driver pods when cloud credentials change, so the CSI driver does not need to reload the credentials on its own.
* Replace image name placeholders with the current images for an OCP release.
* Propagate log level changes.
* Create a default storage class.
* "Stomp" over any user changes in the driver `Deployment` / `DaemonSets` - the operator knows better how to run the CSI driver.
* Report its status correctly via `ClusterCSIDriver.Status.Conditions`.
* Etc.

### CSI sidecars

OpenShift already ships CSI sidecars, usually with the version that corresponds to the Kubernetes version in each OCP release. These sidecars MUST be used by the CSI driver. A CSI driver operator gets their image names (SHAs) as env. variables.

### Credentials

The CSI driver should be able to consume `Secrets` provided by the `cloud-credentials-operator` (CCO). Technically it’s possible that a CSI driver operator translates the Secrets from CCO to a format understood by the CSI driver, but you save some sweat and tears if you avoid doing so.

`CredentialsRequest` for the CSI driver must be present in `cluster-storage-operator` [`manifests/` directory](https://github.com/openshift/cluster-storage-operator/tree/master/manifests), to be available during cluster installation and/or extraction of `CredentialRequests` during installation.

### Metrics

In OpenShift, we provide metrics through HTTPS. Since most CSI driver and all CSI sidecars expose metrics as HTTP endpoints, we add `kube-rbac-proxy` containers to the driver Pods. They provide a proxy that listens on Pod's public IP address and proxy HTTPS requests from Prometheus to HTTP metric endpoints of the driver / sidecar. The HTTP endpoint is available only on loopback and it's not exposed outside of the driver Pod.

If possible, make the CSI driver working without metrics and add them later. They’re tricky to set up correctly. In general, follow GCP PD CSI driver operator example how the metric ports are exposed in the Pods and how their scraping is configured in [ServiceMonitor CR](https://github.com/openshift/gcp-pd-csi-driver-operator/blob/master/assets/servicemonitor.yaml).

OpenShift shall handle TLS side of things, i.e. it will provide [a Secret with TLS key](https://github.com/openshift/gcp-pd-csi-driver-operator/blob/223a251c3ba39d8af605258d14794b32a5cfafda/assets/service.yaml#L5) that can be used in [`kube-rbac-proxy` sidecars](https://github.com/openshift/gcp-pd-csi-driver-operator/blob/223a251c3ba39d8af605258d14794b32a5cfafda/assets/controller.yaml#L114-L115) using [Secret volumes](https://github.com/openshift/gcp-pd-csi-driver-operator/blob/223a251c3ba39d8af605258d14794b32a5cfafda/assets/controller.yaml#L127-L129). 

### CI
If you do not do so yet, test your CSI driver in vanilla Kubernetes frequently using [Kubernetes storage tests](https://github.com/kubernetes/kubernetes/tree/master/test/e2e/storage/external). Neither OpenShift or an operator is needed here and all your Kubernetes customers will benefit from it.

OpenShift packages the same tests as openshift-test binary / [container image](https://quay.io/repository/openshift/origin-tests). The binary just wraps the tests with proper OpenShift privileges, but otherwise they're the same tests as upstream and consume the same `manifest.yaml` file. To run the tests:

1. Place `manifest.yaml` and `kubeconfig` in a single directory, e.g.  `data/`
2. Run `openshift-tests` from `quay.io/repository/openshift/origin-tests` image:
    ```
    $ podman run -v `pwd`:/data:z --rm -it quay.io/repository/openshift/origin-tests:latest sh -c "KUBECONFIG=/data/kubeconfig TEST_CSI_DRIVER_FILES=/data/manifest.yaml /usr/bin/openshift-tests run openshift/csi --junit-dir /data/results"
    ```

In the end, a CI job will run the same tests. CI for a CSI driver is tricky to set up and probably should be done by Red Hat.

## Deliverables

### CSI driver
Fork the CSI driver under `github.com/openshift` and integrate it with Prow and Tide as described [elsewhere in this guide](../procedures).

Make sure that the CSI driver image is built in Red Hat's CI.


### openshift/api changes
Add your CSI driver name to allowed `ClusterCSIDriver` names [here](https://github.com/openshift/api/blob/b632c5fc10c0ea86cb18577db9388109a43d465f/operator/v1/types_csi_cluster_driver.go#L44-L57) and [here](https://github.com/openshift/api/blob/master/operator/v1/0000_90_cluster_csi_driver_01_config.crd.yaml-patch). You must update `cluster-storage-operator` to the new `openshift/api` version to get the `ClusterCSIDriver` CRD updated during cluster installation / update. A simple `go get -u github.com/openshift/api@master` is enough.

### CSI driver operator
The CSI driver must be installed via an operator and the operator must be based on library-go. As listed above, it has a lot of knowledge about OpenShift. **You cannot use an operator previously developed in-house and using OLM!**

* Ask your Red Hat representative to create a new empty repo in `gihub.com/openshift`. Take [the GCP PD CSI driver operator](https://github.com/openshift/gcp-pd-csi-driver-operator) as a base and copy it there. Replace traces of "GCP PD" and "gcp-pd" in the whole repo with your CSI driver name. If you're lucky, you may be done!
* The only useful code is in [`pkg/operator/starter.go`](https://github.com/openshift/gcp-pd-csi-driver-operator/blob/master/pkg/operator/starter.go) and it basically only instantiates + starts CSI driver controllers from library-go.
* The most important thing is the [`assets/` directory](https://github.com/openshift/gcp-pd-csi-driver-operator/tree/master/assets). It contains YAML files of all objects that the CSI driver needs.
  * Check `${}` "variables" in the files there - the operator will replace e.g. `${LOG_LEVEL}` with `"2"`, `${DRIVER_IMAGE}` with the driver image name etc.
  * Check `kube-rbac-proxy` containers and how they provide HTTPS endpoints for metrics of each CSI sidecar.

#### CSI driver deployment

As result, the operator must deploy the CSI driver this way:

* The CSI driver runs in namespace `openshift-cluster-csi-drivers`.
* OpenShift can be deployed by various tools and in different modes.
  * The most typical mode is a cluster with 3 dedicated master and a number of worker nodes. In this mode a CSI driver runs as:
    * `Deployment` with 2 replicas of CSI controler Pods (driver + external-provisioner,  external-attacher, external-resizer, external snapshotter, livenessprobe and nr. of kube-rbac-proxies). These pods run on master nodes and have anti-affinity towards each other (i.e. run on different master nodes).
    * `DaemonSet` that matches all nodes (incl. masters) with the driver + node-driver-registrar + livenessprobe.
      * The DaemonSet has [`Rolling` update strategy](https://github.com/openshift/gcp-pd-csi-driver-operator/blob/223a251c3ba39d8af605258d14794b32a5cfafda/assets/node.yaml#L13-L16) + tolerates 10% of missing pods (to be able to update 10% of pods at the same time, speeding up updates of large clusters).
    * All containers (both in the `DaemonSet` and `Deployment`) have [CPU and memory requests filed](https://github.com/openshift/gcp-pd-csi-driver-operator/blob/223a251c3ba39d8af605258d14794b32a5cfafda/assets/node.yaml#L73-L76)
  * In a single-node cluster, the `Deployment` with the controller pods has 1 replica.
  * In a cluster without dedicated master nodes, the `Deployment` has no node selector.

Most of the above is automatically configured and managed by our common library-go code!

#### CI
The operator repository must contain a yaml manifest for e2e tests in [`test/e2e` directory] ((https://github.com/openshift/gcp-pd-csi-driver-operator/tree/master/test/e2e) and [Dockerfile.test](https://github.com/openshift/gcp-pd-csi-driver-operator/blob/master/Dockerfile.test) for it. In our CI we can distribute "stuff" like the test manifest only as a container images, hence we build a container with the manifest in CI. `FROM: src` will then use the same image as we built for the driver sources, as checked out from github.

### cluster-storage-operator
* Add `CredentialsRequest` for the CSI driver to `manifest/ directory of CSO](https://github.com/openshift/cluster-storage-operator/tree/master/manifests). Follow existing examples there.
* Add complete assets of the CSI driver **operator** to [`assets/csidriveroperators/<platform>`](https://github.com/openshift/cluster-storage-operator/tree/master/assets/csidriveroperators). It must contain all RBACs that the operator needs (incl. those that the operator will grant to the driver and all CSI sidecars!), `ServiceAccount` and `Deployment` of the CSI driver operator. Check [GCE PD](https://github.com/openshift/cluster-storage-operator/tree/master/assets/csidriveroperators/gcp-pd) as an example.
* Teach CSO how / when to start the CSI driver operator via a little glue code.
  * Write [`Get<driver name>OperatorConfig()`](https://github.com/openshift/cluster-storage-operator/blob/master/pkg/operator/csidriveroperator/csioperatorclient/gcp-pd.go), that returns a structure describing how to start the operator.
    * [Replacement strings](https://github.com/openshift/cluster-storage-operator/blob/f8eda8eeaba9ec2f275431e95555fa05a8c6fa81/pkg/operator/csidriveroperator/csioperatorclient/gcp-pd.go#L18-L19) for ${OPERATOR_IMAGE} and ${DRIVER_IMAGE} in the operator Deployment.
    * [Platform](https://github.com/openshift/cluster-storage-operator/blob/f8eda8eeaba9ec2f275431e95555fa05a8c6fa81/pkg/operator/csidriveroperator/csioperatorclient/gcp-pd.go#L25), on which the operator should start.
    * [What static assets](https://github.com/openshift/cluster-storage-operator/blob/f8eda8eeaba9ec2f275431e95555fa05a8c6fa81/pkg/operator/csidriveroperator/csioperatorclient/gcp-pd.go#L26-L31) to create when the operator should run.
    * [Deployment](https://github.com/openshift/cluster-storage-operator/blob/f8eda8eeaba9ec2f275431e95555fa05a8c6fa81/pkg/operator/csidriveroperator/csioperatorclient/gcp-pd.go#L34) asset.
    * [ClusterCSIDriver CR](https://github.com/openshift/cluster-storage-operator/blob/f8eda8eeaba9ec2f275431e95555fa05a8c6fa81/pkg/operator/csidriveroperator/csioperatorclient/gcp-pd.go#L34) to create.
  * Initialize [list of supported CSI driver operators](https://github.com/openshift/cluster-storage-operator/blob/f8eda8eeaba9ec2f275431e95555fa05a8c6fa81/pkg/operator/starter.go#L132-L145) at the operator startup.

CSO will then handle the rest - if the platform where OCP runs corresponds to the platform that the CSI driver operator declared, CSO will start the operator + `ClusterCSIDriver` CR.

#### CSI driver operator deployment
CSO must deploy the CSI driver operator as a `Deployment` with 1 replica that runs on the master nodes, if they’re available.

## Development
* It’s possible to start the CSI driver operator on the command line, see [GCP PD example](https://github.com/openshift/gcp-pd-csi-driver-operator).
* It’s possible to start the cluster-storage-operator on the command line. It's currently not documented, but provide [expected env. variables](https://github.com/openshift/cluster-storage-operator/blob/f8eda8eeaba9ec2f275431e95555fa05a8c6fa81/manifests/10_deployment.yaml#L53-L124) + start the operator in the same way as the GCP PD CSI driver operator above.

### Troubleshooting

Both the driver + CSI driver operator API objects and logs will be available in must-gather collected by `oc adm must-gater` out of the box, no need to configure anything.

#### CSO
* CSO reports its status in ClusterOperator CR
  * `oc get clusteroperator storage`
  * `oc get clusteroperator storage -o yaml`
  * In addition, CSO reports more detailed status in Storage CR
    * `oc get storage -o yaml`
    * Especially check its conditions.
* You can bump CSO log level in the Storage CR
  * `oc edit storage`
    * Note that the `logLevel` **does not** propagate to CSI driver operators!
* You can "pause" the operator by setting `managementLevel: Unmanaged`.
  * For example to test manual changes to the CSI driver operator `Deployment`. Otherwise, the operator will overwrite any of your changes.

#### CSI driver operator
* The driver operator reports its status in `ClusterCSIDriver` CR
  * `oc get clustercsidriver -o yaml`
* You can bump CSO log level in the ClusterCSIDriver CR
  * `oc edit clustercsidriver`
    * Note that `logLevel` **does** propagate to the CSI driver!
* You can "pause" the operator by setting `managementLevel: Unmanaged`. For example to test manual changes to the driver `Deployment` / `DaemonSet`. Otherwise, the operator will overwrite any of your changes.
