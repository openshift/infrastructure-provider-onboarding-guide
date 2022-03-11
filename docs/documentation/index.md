# Documentation

All OpenShift components that are released from Red Hat will have accompanying
documentation in the [OpenShift product documentation][ocp-docs]. The content
for these product documents are created and maintained by Red Hat, but they
are inspired by the [OpenShift enhancement](../openshift-enhancement),
repository level documentation, and direct discussions with the component
engineers.

## Repository level documentation

Any component that has its code in a Git repository must have
documentation in that repository to cover its usage and troubleshooting. This
repository level documentation forms the basis of the product documentation
and also helps OpenShift users to have a deeper understanding the software they
are deploying and running. This documentation should be written by the authors
of the software component.

**Examples of Respository Level Documentation**

* Machine API Operator, the [documenation directory][mao-docs] contains several documents
  structured by intended audience and topic.

* Alibaba Machine API Actuator, the [README file][ali-docs] contains detailed information
  about deployment and usage.

## Product level documentation

As mentioned above, all components in OpenShift will have product documentation
created by Red Hat content teams. This documentation is inspired by the repository
level content, and direct communication with the engineers who are creating and
maintaining the software. During the development of new infrastructure components
it is expected that Red Hat content writers will have access to the repository
level documentation and to the original authors of the components in question.


[ocp-docs]: https://docs.openshift.com
[mao-docs]: https://github.com/openshift/machine-api-operator/tree/master/docs
[ali-docs]: https://github.com/openshift/cluster-api-provider-alibaba/blob/main/README.md
