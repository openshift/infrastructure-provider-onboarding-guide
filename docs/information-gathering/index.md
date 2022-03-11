
# Information Gathering

The following items will be needed to move forward smoothly in the onboarding process. Use the questions below to build an inventory of your existing capabilities or gaps. Red Hat will review these to help estimate the amount of work. 


## Compute

- Do you have a list and documentation of pre-configured instance types (e.g. `m4.2xlarge`) or are machines configured another way? 
- What are the supported processor architectures and what do you wish to use with OpenShift?
- Do you have multiple instance types (e.g. compute, graphics, HPC, etc)? 
- Can you organize machines into zones, regions, or other types of groups?

Additionally, as a reference, you can review the [minimum hardware requirements](https://docs.openshift.com/container-platform/latest/installing/installing_bare_metal/installing-bare-metal.html#installation-minimum-resource-requirements_installing-bare-metal) for OpenShift.

## Storage

- What types of storage do you offer (e.g. block, object, filesystem, fast, budget, etc)?
- Do you have any storage performance benchmarks you can share? 
- Do you support features like snapshots and disk expansion?

## Networking

- Do you have a native load balancing solution? If so, does it meet the [requirements for OpenShift](https://docs.openshift.com/container-platform/latest/installing/installing_bare_metal/installing-bare-metal.html#installation-load-balancing-user-infra_installing-bare-metal)?
- Do you have a IP Address Management solution? (e.g. DHCP and DNS)?
    - Do you support static IP assignment via DHCP? 
- Will you be able to support each of the [DNS record types used by OpenShift](https://docs.openshift.com/container-platform/latest/installing/installing_bare_metal/installing-bare-metal.html#installation-dns-user-infra_installing-bare-metal)?
- Do you have features like VPC, subnets, and firewalls?
- Do you have disconnected, offline, or restricted network capabilities?

## Security

- Do you have an IDM or Authentication solution? If so, what standard does it follow (e.g. OAuth, OpenID, etc)?
- Does you have role based access controls (RBAC) available or another authorization solution?
- Do you have hardware security module (HSM) support?

## Development and Community

- Do you have API documentation and libraries for your infrastructure? Are there code examples?
- Is there a metadata service for your infrastructure? (e.g. `169.254.169.254`)
- Are there any existing Kubernetes interface implementations? For example:
    - [Container Storage Interface (CSI)](https://kubernetes-csi.github.io/docs/)
    - [Container Networking Interface (CNI)](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)
    - [Cloud Controller Manager (CCM)](https://kubernetes.io/docs/tasks/administer-cluster/developing-cloud-controller-manager/)
    - [Cluster API (CAPI) Provider](https://cluster-api.sigs.k8s.io/introduction.html)
-  The OpenShift installer relies on Terraform to provision resources. Do you have a Terraform provider?
-  Do you have support for [Fedora CoreOS](https://docs.fedoraproject.org/en-US/fedora-coreos/platforms/), [Ignition](https://coreos.github.io/ignition/), and [Afterburn](https://coreos.github.io/afterburn/)?

