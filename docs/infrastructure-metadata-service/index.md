# Infrastructure Metadata Service

## About Metadata Service

Several cloud providers support a [metadata service](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html) for their instances. The metadata service allows users to access their instance metadata. Instance metadata is any data associated with the instance such as hostname, security groups, user data etc. that can be used to configure or manage the instance.

## Securing access to Metadata Service

If your cloud provider runs a metadata service, you would typically want pods created in 
OpenShift to not be able to access the metadata service. 
OpenShift's native CNI plugins (OpenShift SDN and OVN-Kubernetes) provide a way to secure
your metadata service by adding IP Tables rules to block access. 

### OpenShift SDN

To block access to the metadata service from pods in OpenShift, please add your
metadata service IP based on your platform to the [generateIPTablesRules](https://github.com/openshift/sdn/blob/master/pkg/cmd/openshift-sdn-cni/openshift-sdn.go#L121) function.

### OVN Kubernetes

To block access to the metadata service from pods in OpenShift, please add your
metadata service IP based on your platform to the [setupIPTablesBlocks](https://github.com/openshift/ovn-kubernetes/blob/master/go-controller/pkg/cni/OCP_HACKS.go#L35) function.

### Questions

Questions can be directed to the OpenShift Networking team via the Red Hat partners you are working with.
