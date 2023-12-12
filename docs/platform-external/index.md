# Overview

The Platform External path allows providers to self-serve the integration of
Kubernetes components in OpenShift/OKD without the need to modify any core payload
and without the need for direct involvement of Red Hat engineering.

What are external cloud providers in Kubernetes?

Historically, all cloud providers in Kubernetes were found in the main Kubernetes repository.
However, Kubernetes aims to be ubiquitous and this means supporting a great many infrastructure
providers. Doing this all from a single monolithic repository (and a single monolithic kube-controller-manager
binary) was deemed something that wouldn’t scale, and so in 2017, the Kubernetes community began working
on support for out-of-tree cloud providers. These out-of-tree providers were initially aimed at
allowing the community to develop cloud providers for new, previously unsupported infrastructure providers,
but as the functionality matured, the community decided to migrate all of the current in-tree cloud providers
to external cloud providers too. You can read more about this in the
[Kubernetes blog](https://kubernetes.io/blog/2019/04/17/the-future-of-cloud-providers-in-kubernetes/)
and the [Kubernetes documentation](https://kubernetes.io/docs/concepts/architecture/cloud-controller/).

To signalize the use of external cloud providers' components, like Cloud Controller Manager, OpenShift provides
a mechanism to set the `--cloud-provider` flag to `external` on Kubernetes components (Kubelet and Kube Controller
Manager) when using the platform type `External`. This mechanism must be activated in the installer option
`platform.external.cloudControllerManager` with value of `External` on `install-config.yaml`.

To learn more about the feature, we encourage you to read the OpenShift Enhancement Proposal
["Introduce new platform type `External` in the OpenShift specific Infrastructure resource"](https://github.com/openshift/enhancements/blob/master/enhancements/cloud-integration/infrastructure-external-platform-type.md).

To begin learning about the process, we are providing the following pages to achieve your goal:

- [Installing a Platform External OpenShift cluster](./installing.md): A generic
  guide exploring the components and steps to provision an OpenShift cluster