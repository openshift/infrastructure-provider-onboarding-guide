# Installing a cluster with Platform External

The steps to install an OpenShift cluster with platform external derives from
the guidance and infrastructure requirements of the "agnostic installation"
method from the official documentation ["Installing a cluster on any platform"](https://docs.openshift.com/container-platform/4.13/installing/installing_platform_agnostic/installing-platform-agnostic.html).

This method is a fully customized automation, allowing the user to deploy
a cluster to use any automation they want, including provider's specific like network components,
required to deploy an OpenShift cluster.

There are other methods and tools than using `openshift-installer` to deploy a
provider-agnostic cluster, such as the Assisted Installer, which are not covered by this guide.

To begin an agnostic installation for platform external, the `install-config.yaml`
configuration file must be changed to set the platform type to `External`, then
the providers' manifests must be placed into the install directory before creating
the ignition files.

The following sections describe the steps to install an OpenShift cluster using
platform external type using fully customized automation.


Table of Contents:

- [Prerequisites](#prerequisites)
- [Create Infrastructure resources](#create-infrastructure-resources)
    - [Identity](#identity)
    - [Network](#network)
    - [DNS](#dns)
    - [Load Balancers](#load-balancers)
- [Setup OpenShift installation](#preparing-the-installation)
    - [Create the install-config.yaml](#create-the-install-configyaml)
    - [Create the manifests](#create-manifests)
    - [Create ignition files](#create-ignition-files)
- [Create compute nodes](#create-compute-nodes)
    - [Bootstrap](#bootstrap-node)
    - [Control Plane](#control-plane)
    - [Compute/workers](#computeworkers)
- [Next](#next-steps)


## Prerequisites

### Clients

The OpenShift client (`oc`) and Installer (`openshift-install`) must be
downloaded, read the steps described in
["Obtaining the installation program"](https://docs.openshift.com/container-platform/4.13/installing/installing_platform_agnostic/installing-platform-agnostic.html).

The credentials to pull OpenShift images, also known as "Pull Secret", needs
to be obtained from the [Red Hat Hybrid Cloud Console](https://console.redhat.com/openshift).

### Upload the RHCOS image

The Red Hat Core OS image is built for providers into different architectures and formats.
You must choose and download the image from the format that is supported by the provider.

You can obtain the URL for each platform, architecture, and format by running
the following command:

~~~bash
./openshift-install coreos print-stream-json
~~~

For example, to download an image format `QCOW2` built for `x86_64` architecture
and the `OpenStack` platform, you can use the following command:

~~~bash
wget $(./openshift-install coreos print-stream-json | jq -r '.architectures["x86_64"].artifacts["openstack"].formats["qcow2.gz"].disk.location')
~~~

You must upload the downloaded image to your cloud provider image service and
use it when creating virtual machines.

## Create Infrastructure resources

Several types of infrastructure need to be created including compute nodes, storage, and networks.
This document describes how to integrate those resources into the OpenShift installation process,
and assumes that the entire process of creating the infrastructure will be automated for end users.

In OpenShift, the `openshift-install` binary is responsible for provisioning the infrastructure in
integrated providers using the IPI (Installer-Provisioned Infrastructure IPI) method,  the external
platform does not have any automation implemented to create infrastructure. The `openshift-install` uses
Terraform as a backend on supported platforms to automatically create cloud resources and form them
into a new cluster. In certain situations, such as when preparing an external platform cluster, the
resource creation needs to be customized. The following examples show how to customize and automate
the infrastructure creation provided in the installer repository:

- [AWS CloudFormation Templates](https://github.com/openshift/installer/tree/master/upi/aws/cloudformation) for [AWS UPI](https://docs.openshift.com/container-platform/4.13/installing/installing_aws/installing-aws-user-infra.html)
- [ARM Templates](https://github.com/openshift/installer/tree/master/upi/azure) for [Azure UPI](https://docs.openshift.com/container-platform/4.13/installing/installing_azure/installing-azure-user-infra.html)
- [Ansible Playbooks](https://github.com/openshift/installer/tree/master/upi/openstack) for [OpenStack UPI](https://docs.openshift.com/container-platform/4.13/installing/installing_openstack/installing-openstack-user-kuryr.html)

The steps below point to the OpenShift documentation for each infrastructure component section.

### Identity

The agnostic installation used by the platform external does not require any identity,
although the provider's components may require identity to communicate with the cloud APIs.

You might need to create any credentials, secrets, and/or configmap manifest according to the cloud provider components' documentation, like Cloud Controller Manager.

OpenShift prioritizes, and recommends, the least privileges and password-less authentication
method, or short-lived tokens, when providing credentials to components.

### Network

There is no specific configuration for the platform external when deploying network components.

See the [Networking requirements for user-provisioned infrastructure](https://docs.openshift.com/container-platform/4.13/installing/installing_platform_agnostic/installing-platform-agnostic.html#installation-network-user-infra_installing-platform-agnostic)
for details of the deployment requirements.

In production environments it is recommended to deploy OpenShift
in more than one location, some clouds  refer to these as named zones or fault domains.
The most important point is to increase the availability and redundancy of the control
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

Important notes:

- the address `api-int.clusterDomain` must point to the internal load balancer address.
- the load balancers must support hairpin connections

[upi-lb]: https://docs.openshift.com/container-platform/4.13/installing/installing_platform_agnostic/installing-platform-agnostic.html#installation-load-balancing-user-infra_installing-platform-agnostic

## Preparing the installation

The cluster configuration to setup the platform external is created in this section.

The steps below describe how to create the `install-config.yaml` with the required fields, and
the steps used to customize the providers' manifests before generating the ignition
configuration files.

### Create the install-config.yaml

Follow the steps to [Manually create the installation configuration file](install-config),
customizing the `platform` object, setting the type to `external`, and the
`platformName` to the cloud provider's name:

```yaml
platform:
  external:
    platformName: "providerName"
```

[install-config]: https://docs.openshift.com/container-platform/4.13/installing/installing_platform_agnostic/installing-platform-agnostic.html#installation-initializing-manual_installing-platform-agnostic

### Create manifests

Once the `install-config.yaml` is created, you can generate the manifests for the
deployment by running the command:

```bash
./openshift-install create manifests
```

The `install-config.yaml` will be consumed, then the `openshift/` and
`manifests/` directories will be created.

The steps below describe how to customize the OpenShift installation.

#### Create custom manifests for CCM

If a Cloud Controller Manager (CCM) is available for the platform, it can be deployed by
custom manifests added in the install directory.

This section describes the minimal requirements to be defined in those custom manifests.

1) A set of tolerations must be set to the CCM's pod spec
to ensure the controllers are initialized even if the node is not yet ready.

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

2) Red Hat strongly recommends deploying the CCM's resources in a custom namespace,
and properly setting the security constraints on that namespace. For example:

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

- Service Account

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cloud-controller-manager
  namespace: {{ cloud provider name }}-cloud-controller-manager
```

- Cluster Role

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

4) The manifest below can be used as a Deployment configuration:

```yaml
# This a template that can be used as a base to run your cluster controller manager in openshift, all you need is to:
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

#### Create custom manifests for Kubelet

The [kubelet service](https://github.com/openshift/machine-config-operator/blob/master/templates/worker/01-worker-kubelet/_base/units/kubelet.service.yaml)
is also started with the flags `--cloud-provider=external` and `--provider-id=${KUBELET_PROVIDERID}`,
requiring a valid `${KUBELET_PROVIDERID}`

The value of `${KUBELET_PROVIDERID}` depends on CCM, we recommend reading the cloud
provider's CCM to check the appropriate value.

In OpenShift you can set the `${KUBELET_PROVIDERID}` on each node using the
[MachineConfiguration](https://docs.openshift.com/container-platform/4.13/rest_api/machine_apis/machineconfig-machineconfiguration-openshift-io-v1.html).

The example below shows how to create a `MachineConfig` to retrieve the provider's
ID from the Instance/VM Metadata service, setting it to the syntax `providerName://ID`:

```yaml
# https://github.com/openshift/machine-config-operator/blob/master/templates/common/aws/files/usr-local-bin-aws-kubelet-providerid.yaml
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

The `{{ machine_role }}` must be `master` and `worker`. Both manifests must be
saved to `config-master.bu` and `config-worker.bu`, then run the following commands:

```bash
$ butane config-master.bu \
  -o openshift/99_openshift-machineconfig_00-master-kubelet-providerid.yaml

$ butane config-worker.bu \
  -o openshift/99_openshift-machineconfig_00-worker-kubelet-providerid.yaml
```

#### Create additional manifests

If the CCM or any other component you want to add in install time requires
dependencies, you can also add them to the respective directories.

For example, if the CCM requires secrets or custom configuration, you can create it:

> Note: replace the `{{ secret_value | b64encode }}` to a valid base64 string

```bash
cat <<EOF > manifests/cloud-controller-manager-01-secret.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: cloud-controller-manager-config
data:
  cloud-provider.yaml: {{ secret_value | b64encode }}
EOF
```

### Create ignition files

Once the manifests are placed, you can create the cluster ignition configurations:

~~~bash
./openshift-install create ignition-configs
~~~

The files with the extension `.ign` will be generated by the above command.

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

## Create compute nodes

The step to provision the compute nodes is cloud-specific. The required steps
to boot RHCOS is different for each compute role:

- bootstrap node: must use the ignition file `bootstrap.ign`
- control-plane nodes: must use the ignition file `master.ign`
- compute nodes: must use the ignition file `worker.ign`

Requirements:

- You created the ignition configs
- You uploaded the RHCOS image to the cloud image service
- You reviewed the ["Minimum resource requirements for cluster installation"](https://docs.openshift.com/container-platform/4.13/installing/installing_platform_agnostic/installing-platform-agnostic.html#installation-minimum-resource-requirements_installing-platform-agnostic)

### Bootstrap node

The bootstrap node is a temporary machine used only during the installation process.
It is a temporary machine that runs a minimal Kubernetes configuration to deploy
the OpenShift Container Platform control plane.

The `bootstrap.ign` must be used to create the bootstrap node. Most of the cloud
providers have size limits in the user data, so you must store the `bootstrap.ign`
externally, then retrieve it in the boot process. If the cloud provider
provides a blob service allowing the creation of a signed HTTPS URL,
it can be used to store and serve the ignition file.

The following example can be used to fetch the ignition using a secure HTTP method,
with authentication:

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

### Control Plane

Three control plane nodes must be created.
The ignition file `master.ign` must be used in the user data for each node.

### Compute/workers

Compute nodes (two or more are recommended) must be created.
The ignition file `worker.ign` must be used in the user data for each node.

#### Approve certificates

The Certificate Signing Requests (CSR) for each compute node must be approved
by the user, and lately automated by the provider.

See the references on how to approve it:

- [Certificate signing requests management](https://docs.openshift.com/container-platform/4.13/installing/installing_platform_agnostic/installing-platform-agnostic.html#csr-management_installing-platform-agnostic)

- [Approving the certificate signing requests for your machines](https://docs.openshift.com/container-platform/4.13/installing/installing_platform_agnostic/installing-platform-agnostic.html#installation-approve-csrs_installing-platform-agnostic)

### Destroy Bootstrap

Once the Control Plane nodes join the cluster, you can destroy the bootstrap node.
You can check it by running:

```bash
./openshift-install wait-for bootstrap-complete --log-level debug
```

Wait for the installation to be completed:

```bash
./openshift-install wait-for install-complete --log-level debug
```

## Next steps

- [Validating an installation](https://docs.openshift.com/container-platform/4.13/installing/validating-an-installation.html#validating-an-installation)
- [Running conformance tests in non-integrated providers](./e2e-testing.md)