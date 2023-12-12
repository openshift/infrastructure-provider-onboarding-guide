# Installing a cluster with Platform External

The steps to install an OpenShift cluster with a platform type external inherits from
the guidance and infrastructure requirements of the "agnostic installation"
method from the official documentation ["Installing a cluster on any platform"](https://docs.openshift.com/container-platform/4.13/installing/installing_platform_agnostic/installing-platform-agnostic.html).

This method is a fully customized path, allowing the users to config
a cluster using `openshift-installer`, creating the infrastructure using
any automation they wanted to provision resources required to install an OpenShift cluster.

There are other methods and tools than using `openshift-installer` to deploy a
provider-agnostic cluster, such as the Assisted Installer, which is not covered by this guide.

To begin an agnostic installation for the platform external, the `install-config.yaml`
configuration file must be changed to set the platform type to `External`, then
the providers' manifests must be placed into the install directory before creating
the ignition files.

This guide is organized into three sections:

- Section 1 - OpenShift configuration: the section describes how to set up
  OpenShift configuration files and specific customizations for platform type
  `External`.
- Section 2 - Infrastructure provisioning: the section describes how to consume
  the configuration files, with an overview of the agnostic installation method
  used by deployments in non-integrated providers.
- Section 3 - Setup Cloud Controller Manager (CCM): the section describes how to
  create the required cloud provider resources when opted into it in the bootstrap
  stage.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Section 1. Setup OpenShift configuration](#section-1-setup-openshift-configuration)
    - [Create the install-config.yaml](#create-the-install-configyaml)
    - [Create the manifests](#create-manifests)
        - [Customize manifest for CCM (optional)](#customize-manifest-for-ccm-optional)
            - [Patch the Infrastructure Object](#patch-the-infrastructure-object-optional)
            - [Create MachineConfig for Kubelet Provider ID](#create-machineconfig-for-kubelet-provider-id-optional)
    - [Create ignition files](#create-ignition-files)
- [Section 2. Create Infrastructure resources](#section-2-create-infrastructure-resources)
    - [Identity](#identity)
    - [Network](#network)
    - [DNS](#dns)
    - [Load Balancers](#load-balancers)
    - [Create compute nodes](#create-compute-nodes)
        - [Upload the RHCOS image](#upload-the-rhcos-image)
        - [Bootstrap](#bootstrap-node)
        - [Control Plane](#control-plane)
        - [Compute/workers](#computeworkers)
- [Section 3. Deploy Cloud Controller Manager (CCM)](#section-3-deploy-cloud-controller-manager-ccm)
- [Review the installation](#review)
- [Next](#next-steps)

The following sections describe the steps to install an OpenShift cluster using
platform external type using fully customized automation.


## Prerequisites

Clients:

- The OpenShift client (`oc`) and Installer (`openshift-install`) must be downloaded,
  please read the steps described in [Obtaining the installation program][installing-cli].

- The Butane utility (`butane`) must be installed to manipulate Machine Configs. Please
  read the steps described in [Installing Butane][installing-butane]

[installing-cli]: https://docs.openshift.com/container-platform/latest/installing/installing_platform_agnostic/installing-platform-agnostic.html
[installing-butane]: https://docs.openshift.com/container-platform/latest/installing/install_config/installing-customizing.html#installation-special-config-butane-install_installing-customizing

Credentials:

- The credentials to pull OpenShift images from the container registry, also known as "Pull Secret", needs
to be obtained from the [Red Hat Hybrid Cloud Console](https://console.redhat.com/openshift).

## Section 1. Setup OpenShift configuration

The OpenShift cluster configuration to set up the platform external is created in this section.

The steps below describe how to create the `install-config.yaml` with the required fields, and
the steps used to customize the providers' manifests before generating the ignition
configuration files.

### Create the install-config.yaml

Follow the steps to [Manually create the installation configuration file](install-config),
customizing the `platform` object, setting the type to `external`, and the customized fields:

- `platform.external.platformName` holds the arbitrary string representing the infrastructure
  provider name, expected to be set at the installation time. This field is solely for
  informational and reporting purposes and is not expected to be used for decision-making.
- `platform.external.cloudControllerManager` when set to `External`, this property will enable an
  external cloud provider. Default: "" (empty/None).

!!! info "`.platform.external.cloudControllerManager`"
    The cluster cloud controller manager operator reads the state of the platform external
    deployment in the `Infrastructure` custom resource object when the value
    of `.status.platformStatus.external.cloudControllerManager.state` is set to
    `External`, the `--cloud-provider` flag will be set to `External` in the Kubelet
    and Kubernetes API Server, the nodes will also wait to be initialized by the
    cloud provider CCM.

Examples of `install-config.yaml` using platform external:

- Default configuration without customizations:

```yaml
platform:
  external:
    platformName: myCloud
```

- Signalizing that an external CCM will be supplied:

```yaml
platform:
  external:
    platformName: myCloud
    cloudControllerManager: External
```

[install-config]: https://docs.openshift.com/container-platform/latest/installing/installing_platform_agnostic/installing-platform-agnostic.html#installation-initializing-manual_installing-platform-agnostic

### Create manifests

Once the `install-config.yaml` is created, the manifests can be generated by running the command:

```bash
openshift-install create manifests
```

The `install-config.yaml` will be consumed, then the `openshift/` and
`manifests/` directories will be created.

The following steps describe how to customize the OpenShift installation.

#### Create MachineConfig for Kubelet Provider ID (optional)

This step **is required when you are planning to deploy a Cloud Controller Manager in Section 3**,
where the objective is to install an OpenShift cluster with a provider's Cloud
Controller Manager, the Kubelet must be set in the configuration stage.

The [kubelet service](https://github.com/openshift/machine-config-operator/blob/master/templates/worker/01-worker-kubelet/_base/units/kubelet.service.yaml)
is started with the flags `--cloud-provider=external` and `--provider-id=${KUBELET_PROVIDERID}`,
requiring a valid `${KUBELET_PROVIDERID}`.

The value of `${KUBELET_PROVIDERID}` should be unique by node, and the syntax
and values depend on the CCM requirements, we recommend reading the cloud
provider's CCM to check the appropriate value.

In OpenShift it is possible to set a dynamic value of `${KUBELET_PROVIDERID}`
can be set on each node using the
[MachineConfiguration](https://docs.openshift.com/container-platform/4.13/rest_api/machine_apis/machineconfig-machineconfiguration-openshift-io-v1.html).

The example below shows how to create a `MachineConfig` to retrieve the provider's
ID from the Instance/VM Metadata service, setting it to the syntax required by
CCM, for example: `providerName://ID`:

> [Reference for AWS in integrated platform](https://github.com/openshift/machine-config-operator/blob/master/templates/common/aws/files/usr-local-bin-aws-kubelet-providerid.yaml)

```yaml
variant: openshift
version: 4.14.0
metadata:
  name: 00-{{ machine_role }}-kubelet-providerid
  labels:
    machineconfiguration.openshift.io/role: {{ machine_role }}
storage:
  files:
  - mode: 0755
    path: "/usr/local/bin/kubelet-providerid"
    contents:
      inline: |
        #!/bin/bash
        set -e -o pipefail
        NODECONF=/etc/systemd/system/kubelet.service.d/20-providerid.conf
        if [ -e "${NODECONF}" ]; then
            echo "Not replacing existing ${NODECONF}"
            exit 0
        fi
        PROVIDERID=$(curl -sL http://169.254.169.254/metadata/id);
        cat > "${NODECONF}" <<EOF
        [Service]
        Environment="KUBELET_PROVIDERID=providerName://${PROVIDERID}"
        EOF
systemd:
  units:
  - name: kubelet-providerid.service
    enabled: true
    contents: |
      [Unit]
      Description=Fetch kubelet provider id from Metadata
      # Wait for NetworkManager to report it's online
      After=NetworkManager-wait-online.service
      # Run before kubelet
      Before=kubelet.service
      [Service]
      ExecStart=/usr/local/bin/kubelet-providerid
      Type=oneshot
      [Install]
      WantedBy=network-online.target
```

Where:

- `{{ machine_role }}` must be `master` and `worker`.

Both YAML manifest files must be saved, in this example, with respective names
`config-master.bu` and `config-worker.bu`, followed by running the commands:

- Generate the MachineConfig manifest for master nodes:
```bash
butane config-master.bu \
  -o openshift/99_openshift-machineconfig_00-master-kubelet-providerid.yaml
```

- Generate the MachineConfig manifest for worker nodes:
```bash
butane config-worker.bu \
  -o openshift/99_openshift-machineconfig_00-worker-kubelet-providerid.yaml
```

### Create ignition files

Once the custom manifest files are saved in the install directory,
you can create the cluster ignition configuration files by running:

```bash
openshift-install create ignition-configs
```

The files with the extension `.ign` will be generated as the example below:

```text
.
├── auth
│   ├── kubeadmin-password
│   └── kubeconfig
├── bootstrap.ign
├── master.ign
├── metadata.json
└── worker.ign
```

## Section 2. Create Infrastructure resources

Several types of infrastructure need to be created including compute nodes,
storage, and networks.

This section describes how to integrate those resources into the OpenShift
installation process, and assumes that the entire process of creating the
infrastructure will be automated by the partner to be consumed by the end-users.

In OpenShift, the `openshift-install` binary is responsible for provisioning the
infrastructure in integrated providers using the IPI (Installer-Provisioned
Infrastructure) method, it uses compiled-in SDKs to automate the cloud resources
creation on supported IPI platforms and form them into a new cluster.
In the external platform deployments, automation is not available.

The following examples show how to customize and automate the infrastructure creation
without `openshift-install` automation (non-IPI), allowing highly-customized infrastructure
deployments by the end-user:

- [AWS CloudFormation Templates](https://github.com/openshift/installer/tree/master/upi/aws/cloudformation) for [AWS UPI](https://docs.openshift.com/container-platform/4.13/installing/installing_aws/installing-aws-user-infra.html)
- [Azure ARM Templates](https://github.com/openshift/installer/tree/master/upi/azure) for [Azure UPI](https://docs.openshift.com/container-platform/4.13/installing/installing_azure/installing-azure-user-infra.html)
- [Ansible Playbooks](https://github.com/openshift/installer/tree/master/upi/openstack) for [OpenStack UPI](https://docs.openshift.com/container-platform/4.13/installing/installing_openstack/installing-openstack-user-kuryr.html)

The following sub-sections provide guidance referencing the OpenShift documentation
for the infrastructure components required to deploy a cluster.

### Identity

The agnostic installation used by the platform external does not require any identity,
although the provider's components, such as CCM, may require identity to communicate
with the cloud APIs.

You might need to create any Secrets, and/or ConfigMap manifest according to the cloud
provider components' documentation, like Cloud Controller Manager.

OpenShift prioritizes, and recommends, the least privileges and password-less
authentication method, or short-lived tokens, when providing credentials to components.

### Network

There is no specific configuration for the platform external when deploying network components.

See the [Networking requirements for user-provisioned infrastructure](https://docs.openshift.com/container-platform/4.13/installing/installing_platform_agnostic/installing-platform-agnostic.html#installation-network-user-infra_installing-platform-agnostic)
for details of the deployment requirements for OpenShift.

In production environments, it is recommended to deploy OpenShift control plane nodes
within the same geographical location (regions) distributed in more than one isolated
location or data centers (also known as zones, when available), which some cloud providers
refer to as zones and/or fault domains.
The most important goal is to increase the availability and redundancy of the control
plane and worker nodes using the provider offerings.

### DNS

There is no specific configuration for DNS when using the platform external, the setup
must follow the same as agnostic installation and the provider configuration.

Please take a look at the following guides for the DNS setup:

- [User-provisioned DNS requirements][upi-dns-requirements]
- [Validating DNS resolution for user-provisioned infrastructure][upi-dns-validating]

[upi-dns-requirements]: https://docs.openshift.com/container-platform/4.13/installing/installing_platform_agnostic/installing-platform-agnostic.html#installation-dns-user-infra_installing-platform-agnostic
[upi-dns-validating]: https://docs.openshift.com/container-platform/4.13/installing/installing_platform_agnostic/installing-platform-agnostic.html#installation-user-provisioned-validating-dns_installing-platform-agnostic

### Load Balancers

OpenShift requires a couple of configurations when deploying the load balancer to
serve the Kubernetes API, Ingress Routers, and other internal services.
Please take a look at the documentation ["Load balancing requirements for user-provisioned infrastructure"][upi-lb] for more information.

You can use the cloud provider's load balancer when it meets the requirements.

!!! warning "Attention"
    - the value DNS record `api-int.` must point to the internal load balancer IP or DNS address.
    - the internal IP or DNS address for the Load Balancer must not be dynamic.
    - the internal load balancer(s) must support hairpin connections in the control plane
      services (e.g.: Kubernetes API Server, Machine Config Server)

[upi-lb]: https://docs.openshift.com/container-platform/4.13/installing/installing_platform_agnostic/installing-platform-agnostic.html#installation-load-balancing-user-infra_installing-platform-agnostic

### Create compute nodes

The step to provision the compute nodes is cloud-specific. The required steps
to boot RHCOS is different for each compute role:

- bootstrap node: must use the ignition file `bootstrap.ign`
- control-plane nodes: must use the ignition file `master.ign`
- compute nodes: must use the ignition file `worker.ign`

Furthermore, the Red Hat CoreOS (RHCOS) image must be uploaded to the related cloud provider service.

Requirements:

- You created the ignition configs
- You reviewed the ["Minimum resource requirements for cluster installation"](https://docs.openshift.com/container-platform/4.13/installing/installing_platform_agnostic/installing-platform-agnostic.html#installation-minimum-resource-requirements_installing-platform-agnostic)

#### Upload the RHCOS image

The Red Hat Core OS image is built for providers into different architectures and formats.
You must choose and download the image from the format that is supported by the provider.

You can obtain the URL for each platform, architecture, and format by running
the following command:

~~~bash
openshift-install coreos print-stream-json
~~~

For example, to download an image format `QCOW2` built for `x86_64` architecture
and the `OpenStack` platform, you can use the following command:

~~~bash
wget $(openshift-install coreos print-stream-json |\
  jq -r '.architectures["x86_64"].artifacts["openstack"].formats["qcow2.gz"].disk.location')
~~~

You must upload the downloaded image to your cloud provider image service and
use it when creating virtual machines.

#### Bootstrap node

The bootstrap node is a temporary machine used only during the installation process.
It is a temporary machine that runs a minimal Kubernetes configuration to deploy
the OpenShift Container Platform control plane.

The `bootstrap.ign` must be used to create the bootstrap node. Most of the cloud
providers have size limits in the user data, so you must store the `bootstrap.ign`
externally, then retrieve it in the boot process. If the cloud provider
offers a blob service allowing the creation of a signed HTTPS URL,
it can be used to store and serve the ignition file for bootstrap.

The following example is an ignition file which can be used to fetch a remote ignition
stored externally using a secure HTTP method, with authentication:

```json
{
  "ignition": {
    "config": {
      "replace": {
        "source": "https://blob.url/bootstrap.ign?signingKeys"
      }
    },
    "version": "3.1.0"
  }
}
```

Once the bootstrap node is created, you can attach it to the load balancers:

- Kubernetes API (public and private)
- Machine Config Server

#### Control Plane

Three control plane nodes must be created and distributed into different locations.
The ignition file `master.ign` must be used in the user data for each node.

#### Compute/workers

Compute nodes (two or more are recommended) must be created.
The ignition file `worker.ign` must be used in the user data for each node.

## Section 3. Deploy Cloud Controller Manager (CCM)

This section is mandatory when the setup requires the deployment of Cloud Controller Manager.

The steps describe how to customize the OpenShift cluster installed with platform type
External by creating the manifests to deploy the provider Cloud Controller Manager.

At this stage, the temporary Kubernetes API Server must be available running in the bootstrap phase.

Wait until you can retrieve objects:

```sh
export KUBECONFIG=$INSTALL_DIR/auth/kubeconfig

oc get infrastructures -o yaml
```

### Create custom manifests for CCM

If a Cloud Controller Manager (CCM) is available for the platform, it can be deployed by
custom manifests added in the install directory.

This section describes the steps to customize the OpenShift installation by creating
the required Cloud Controller Manager manifests.

The following items must be considered to create custom CCM manifests:

1) Create a directory `ccm` to store the custom manifest files;

2) Red Hat strongly recommends deploying the CCM's resources in a custom namespace,
and properly defining the security constraints on that namespace. Create the manifest
file `ccm/00-namespace.yaml`. For example:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: {{ cloud provider name }}-cloud-controller-manager
  annotations:
    workload.openshift.io/allowed: management
  labels:
    "pod-security.kubernetes.io/enforce": "privileged"
    "pod-security.kubernetes.io/audit": "privileged"
    "pod-security.kubernetes.io/warn": "privileged"
    "security.openshift.io/scc.podSecurityLabelSync": "false"
    "openshift.io/run-level": "0"
    "pod-security.kubernetes.io/enforce-version": "v1.24"
```

3) Adjust the RBAC according to the CCM's needs:

- Create the Service Account file `ccm/01-serviceaccount.yaml`:

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cloud-controller-manager
  namespace: {{ cloud provider name }}-cloud-controller-manager
```

- Create the Cluster Role manifest file `ccm/02-rbac.yaml`:

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:cloud-controller-manager
  labels:
    kubernetes.io/cluster-service: "true"
rules:
  {{ define here the authorization rules required by your CCM }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: oci-cloud-controller-manager
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:cloud-controller-manager
subjects:
- kind: ServiceAccount
  name: cloud-controller-manager
  namespace: {{ cloud provider name }}-cloud-controller-manager
```

4) The manifest file `ccm/03-deployment.yaml` with the following content can be used
as an example of Deployment configuration:

```yaml
# This a template that can be used as a base to deploy the provider's cluster
# controller manager in OpenShift, please pay attention to:
# - replace values between {{ and }} with your own ones
# - specify a command to start the CCM in your container
# - define and mount extra volumes if needed
# This example defines the CCM as a Deployment, but a DaemonSet is also possible as long as Pod's template is defined in the same way.
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ cloud provider name }}-cloud-controller-manager # replace me
  namespace: {{ cloud provider name }}-cloud-controller-manager # replace me
  labels:
    k8s-app: {{ cloud provider name }}-cloud-controller-manager # replace me
    infrastructure.openshift.io/cloud-controller-manager: {{ cloud provider name }} # replace me
spec:
  replicas: 2
  selector:
    matchLabels:
      k8s-app: {{ cloud provider name }}-cloud-controller-manager # replace me
      infrastructure.openshift.io/cloud-controller-manager: {{ cloud provider name }} # replace me
  strategy:
    type: Recreate
  template:
    metadata:
      annotations:
        target.workload.openshift.io/management: '{"effect": "PreferredDuringScheduling"}'
      labels:
        k8s-app: {{ cloud provider name }}-cloud-controller-manager # replace me
        infrastructure.openshift.io/cloud-controller-manager: {{ cloud provider name }} # replace me
    spec:
      hostNetwork: true
      serviceAccount: cloud-controller-manager
      priorityClassName: system-cluster-critical
      nodeSelector:
        node-role.kubernetes.io/master: ""
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - topologyKey: "kubernetes.io/hostname"
            labelSelector:
              matchLabels:
                k8s-app: {{ cloud provider name }}-cloud-controller-manager # replace me
                infrastructure.openshift.io/cloud-controller-manager: {{ cloud provider name }} # replace me
      tolerations:
        - key: CriticalAddonsOnly
          operator: Exists
        - key: node-role.kubernetes.io/master
          operator: Exists
          effect: "NoSchedule"
        - key: node.cloudprovider.kubernetes.io/uninitialized
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/not-ready
          operator: Exists
          effect: NoSchedule
      containers:
        - name: cloud-controller-manager
          image: {{ cloud controller image URI }} # replace me
          imagePullPolicy: "IfNotPresent"
          command:
          - /bin/bash
          - -c
          - |
            #!/bin/bash
            set -o allexport
            if [[ -f /etc/kubernetes/apiserver-url.env ]]; then
              source /etc/kubernetes/apiserver-url.env
            fi
            exec {{ cloud controller binary }} # replace me
          ports:
          - containerPort: 10258
            name: https
            protocol: TCP
          resources:
            requests:
              cpu: 200m
              memory: 50Mi
          volumeMounts:
            - mountPath: /etc/kubernetes
              name: host-etc-kube
              readOnly: true
            - name: trusted-ca
              mountPath: /etc/pki/ca-trust/extracted/pem
              readOnly: true
            # mount extra volumes if needed
      volumes:
        - name: host-etc-kube
          hostPath:
            path: /etc/kubernetes
            type: Directory
        - name: trusted-ca
          configMap:
            name: ccm-trusted-ca
            items:
              - key: ca-bundle.crt
                path: tls-ca-bundle.pem
        # add extra volumes if needed
```

!!! info "Note"
    The following tolerations must be set to the CCM's pod spec
    to ensure the controller is deployed even if the node is not yet initialized.

    ```yaml
          tolerations:
            - key: CriticalAddonsOnly
              operator: Exists
            - key: node-role.kubernetes.io/master
              operator: Exists
              effect: "NoSchedule"
            - key: node.cloudprovider.kubernetes.io/uninitialized
              operator: Exists
              effect: NoSchedule
            - key: node.kubernetes.io/not-ready
              operator: Exists
              effect: NoSchedule
    ```

Finally, deploy the resources required by CCM:

```sh
oc create -f ccm/*.yaml
```

## Review the installation

This section describes useful commands to follow up on the installation progress.

After the OpenShift configuration, infrastructure and CCM is deployed (when required).

Export the `KUBECONFIG` environment, only if it was not yet exported in Section 3:

```sh
export KUBECONFIG=$INSTALL_DIR/auth/kubeconfig
```

### Cloud Controller Manager

Steps to review the Cloud Controller Manager resources when it is deployed in the
section 3, otherwise you can skip to the next section.

Check if the CCM pods have been started and the control plane nodes initialized:

```sh
oc logs -f deployment.apps/mycloud-cloud-controller-manager -n mycloud-cloud-controller-manager
```

- Check if the CCM components (pods) are running:

```sh
oc get all -n mycloud-cloud-controller-manager
```

- Check if the nodes have been initialized:

```sh
oc get nodes
```

### Approve certificates for compute nodes

The Certificate Signing Requests (CSR) for each compute node must be approved
by the user, and lately automated by the provider.

See the references on how to approve it:

- [Certificate signing requests management](https://docs.openshift.com/container-platform/4.13/installing/installing_platform_agnostic/installing-platform-agnostic.html#csr-management_installing-platform-agnostic)

- [Approving the certificate signing requests for your machines](https://docs.openshift.com/container-platform/4.13/installing/installing_platform_agnostic/installing-platform-agnostic.html#installation-approve-csrs_installing-platform-agnostic)

Check the pending certificates using `oc get csr -w`, then approve those by running the command:

```sh
oc adm certificate approve $(oc get csr  -o json \
  | jq -r '.items[] | select(.status.certificate == null).metadata.name')
```

Observe the nodes joining in the cluster by running: `oc get nodes -w`.

### Wait for Bootstrap to complete

Once the control plane nodes join the cluster, you can destroy the bootstrap node.
You can check it by running:

```sh
openshift-install --dir $INSTALL_DIR wait-for bootstrap-complete
```

Example output:
```text
INFO It is now safe to remove the bootstrap resources
INFO Time elapsed: 1s
```

### Check installation complete

It is also possible to wait for the installation to complete by using the
`openshift-install` binary:

```sh
openshift-install --dir $INSTALL_DIR wait-for install-complete
```

Example output:

```text
$ openshift-install --dir $INSTALL_DIR wait-for install-complete
INFO Waiting up to 40m0s (until 6:17PM -03) for the cluster at https://api.cluster-name.mydomain.com:6443 to initialize...
INFO Checking to see if there is a route at openshift-console/console...
INFO Install complete!
INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/path/to/kubeconfig'
INFO Access the OpenShift web-console here: https://console-openshift-console.apps.cluster-name.mydomain.com
INFO Login to the console with user: "kubeadmin", and password: "[super secret]"
INFO Time elapsed: 2s
```

Alternatively, you can watch the cluster operators to follow the installation process:

```sh
# To follow the operator's progress:
oc get clusteroperators -w

# To get a full summary frequently
watch -n10 oc get clusteroperators

# To wait for the platform operators to become stable
oc adm wait-for-stable-cluster
```

The cluster will be ready to use once the operators are stabilized.

If you have issues, you can start exploring the [Throubleshooting Installations page](https://docs.openshift.com/container-platform/4.13/support/troubleshooting/troubleshooting-installations.html).

## Next steps

- [Validating an installation](https://docs.openshift.com/container-platform/4.13/installing/validating-an-installation.html#validating-an-installation)
- [Running conformance tests in non-integrated providers](./e2e-testing.md)