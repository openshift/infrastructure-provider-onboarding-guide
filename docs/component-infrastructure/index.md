# Component Infrastructure

Some components are not strictly required for an OpenShift installation, but
their integration will improve user's experiences when operating OpenShift on
an infrastructure provider.

## Image Registry

OpenShift contains a component named the [Image Registry Operator][image-reg-oper]
which is responsible for managing a singleton instance of the OpenShift registry.
This operator will manage a container image registry for the OpenShift cluster
which will provide persistent storage for ImageStreams, built images (from Builds
and BuildConfigs), and intermediate images produced during build processes.

By default, the operator will deploy an image registry that is supported by local,
ephemeral, storage. This means that if the node containing the registy is
rebooted, then the cached images will be lost.  This configuration is not
supported by Red Hat and is only added as default on new platforms to aid with
building the platform. It must be changed before the new platform will be
considered complete for general availability.

Infrastructure providers can improve performance for their users by integrating
an infrastructure specific storage configuration for the image registry
operator. With proper integration to a storage service, images will be
available in a persistent local storage. If the new infrastructure platform
will not provide the storage for the image registry, then this component
must be removed by default.

For more information on how the image registry operator works, including
instructions for development, please see the [project documentation][image-reg-oper-docs].

For more information on how the integrated registry works in OpenShift, please
see the [OpenShift product documentation][image-reg-docs].

To see examples of previous infrastructure integrations with the image registry
operator, please see the follow pull requests:

* [Support AlibabaCloud OSS for Image Registry][image-reg-pr-ali]
* [Support IBmCloud and add IBM COS Storage Driver][image-reg-pr-ibm]


[image-reg-oper]: https://github.com/openshift/cluster-image-registry-operator
[image-reg-oper-docs]: https://github.com/openshift/cluster-image-registry-operator/tree/master/docs
[image-reg-docs]: https://docs.openshift.com/container-platform/latest/registry/index.html
[image-reg-pr-ali]: https://github.com/openshift/cluster-image-registry-operator/pull/724
[image-reg-pr-ibm]: https://github.com/openshift/cluster-image-registry-operator/pull/698
