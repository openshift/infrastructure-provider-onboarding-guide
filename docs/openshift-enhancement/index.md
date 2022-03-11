# OpenShift Enhancement

Inspired by the Kubernetes community enhancement process, OpenShift also uses
enhancements to drive and define its features. Early in the process of adding a
new infrastructure provider to OpenShift, an enhancement document should be
created to scope the work that is being done and to expose design details which
might need modification on OpenShift.

To begin, visit the [OpenShift enhancements](https://github.com/openshift/enhancements)
repository and become familiar with the
[enhancement template](https://github.com/openshift/enhancements/blob/master/guidelines/enhancement_template.md)
as well as the [enhancement guidelines](https://github.com/openshift/enhancements/tree/master/guidelines).
When ready, create a pull request with your new infrastructure provider enhancement
to the repository. To aid in this process, here are two examples of pull requests
for recently added platforms:

* [Alibaba Cloud platform enhancement pull request](https://github.com/openshift/enhancements/pull/707)

* [IBM Cloud platform enhancement pull request](https://github.com/openshift/enhancements/pull/773)

## Writing the enhancement

The [enhancement template](https://github.com/openshift/enhancements/blob/master/guidelines/enhancement_template.md)
should guide you in organizing the text of your enhancement. But, it has been designed
primarily for feature and code changes to OpenShift, so there are a few topics you
should consider specifically while writing.

What will an OpenShift cluster look like on the new infrastructure provider?
(Adding a topology diagram can be very helpful to explain the logical architecture.)

Are there special networking considerations that need to be explained
(e.g. DNS and load balancing strategies)?

What types of compute and storage are available on the infrastructure?

How will users install and consume OpenShift on the infrastructure?

The "Drawbacks" and "Alternatives" sections in the enhancement do not always make
sense for new infrastructure providers. Depending on the options available for
deploying OpenShift on the infrastructure, the "Alternatives" section can be a good
place to talk about other methods of deployment.
