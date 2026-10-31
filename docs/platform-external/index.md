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

To learn more about the feature, we encourage you to read the OpenShift Enhancement Proposal
["Introduce new platform type `External` in the OpenShift specific Infrastructure resource"](https://github.com/openshift/enhancements/blob/master/enhancements/cloud-integration/infrastructure-external-platform-type.md).

To begin learning about the process, we are providing the following pages to achieve your goal:

- [OpenShift components using platform type `External`](./components.md): A list of OpenShift components which is natively integrated with OpenShift platform type `External`.
- [Installing a Platform External OpenShift cluster](./installing/agnostic.md): A generic
  guide exploring the components and steps to provision an OpenShift cluster
- [Installing a Platform External OpenShift cluster with CAPI](./installing/capi.md):A generic guide exploring how to enhance from UPI method to Cluster API/CAPI provider implementation to manage the infrastructure required to install OpenShift on your provider.
- [Installing a Platform External OpenShift cluster on AWS with CAPI](./installing/capi-ref-image-aws.md): A reference implementation of an OpenShift cluster installation using platform type `External` with Cluster API AWS (CAPA) provider implementation to provision cluster infrastructure resources.