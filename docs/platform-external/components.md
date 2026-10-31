# OpenShift components supported on External Platform

List of components that OpenShift supports natively extend a cloud provider implementation.

Components not listed here will act as a `None` provider implementation, also known as previous named as platform `None`.

## Cloud Controller Manager (CCM)

To signal the use of a cloud provider's Cloud Controller Manager, OpenShift provides
a mechanism to set the `--cloud-provider` flag to `external` on Kubernetes components (Kubelet and Kube Controller
Manager) when using the platform type `External`. This mechanism must be activated in the installer option
`platform.external.cloudControllerManager` with value of `External` on `install-config.yaml`.


## Cluster API (CAPI) on openshift-install

TBD