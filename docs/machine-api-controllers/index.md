# Machine API Controllers

The Machine API is OpenShift's declarative API for infrastructure provider
compute resources. It is responsible for creating, destroying, and monitoring
the machine instances (virtual machines, bare metal servers, etc.) that are
configured for inclusion. In a standard Installer Provisioned Infrastructure
(IPI) installation, the Machine API will include the instances of the compute
plane, the control plane is not managed by the Machine API. In User Provisioned
Infrastructure (UPI) installations, the Machine API may, or may not, be used
depending on the configuration specified by the user.

## Components of Machine API

There are several operators, controllers, and Custom Resource Definitions which
define the Machine API. It is important to understand how these components interact
before building a new infrastructure provider.

### Custom Resource Definitions

The primary resources of the Machine API are Machines, MachineSets, and
MachineHealthChecks. For the purposes of implementing a new infrastructure
provider, Machines and MachineSets will be the resources that will require
integration.

Machines represent individual host instances within an infrastructure provider that will
become Nodes in the OpenShift cluster.

MachineSets are scalable collections of Machines. Within each MachineSet is a template
for creating new Machines on the infrastructure.

MachineHealthChecks are resources that are used to designate MachineSets which should
automatically repair unhealthy Machines, and the conditions by which those Machine's
health is determined.

### Machine API Operator

The [machine-api-operator][mao-repo] (MAO) is the main entry point into the Machine API.
The operator is responsible for deploying the infrastructure-specific Machine controller,
and also runs controllers for MachineSets, and MachineHealthChecks. The MAO also deploys
the validating and mutating webhooks for Machine resources.

For more information about the Machine API Operator, please see the
[Machine API Operator Overview][mao-overview], and the
[Machine API Hacking Guide][mao-hackguide].

#### Controllers owned by the Machine API Operator

- Machine controller - manages Machine resources. It uses an [actuator interface][actuator-interface],
  which follows a [Machine lifecycle pattern][ml-pattern]. This interface provides `Create`,
  `Update`, `Exists`, and `Delete` methods to manage provider specific cloud instances, connected
  storage, and networking settings to make the instance prepared for bootstrapping. Each provider
  is therefore responsible for implementing these methods.
- MachineSet controller - manages MachineSet resources and ensures the presence of the expected number
  of replicas and a given provider config for a set of Machines. When increasing the replica count,
  this controller will use information in its ProviderSpec to create new Machines, copying that ProviderSpec
  to the Machine in the process.
- MachineHealthCheck controller - manages MachineHealthCheck resources. Ensure Machines being
  targeted by MachineHealthCheck objects are satisfying healthiness criteria or are remediated otherwise.
  For more information about MachineHealthChecks, please see the OpenShift [Deploying machine health checks][mhc-docs]
  documentation.
- NodeLink controller - ensure Machines have a nodeRef based on `providerID` matching. Annotate
  nodes with a label containing the Machine name.

Although the Machine API operator owns the lifecycle of all these controllers, it is worth
noting that for new infrastructure providers only the Machine controller will require
code changes.

#### Machine API Webhooks

The Machine API operator deploys mutating and validating webhooks for Machines and MachineSets.
The webhooks allow the Machine API operator to detect invalid manifest declarations, or add
values that are required by OpenShift. By using webhooks the Machine API operator is able
to return warnings and errors to the user before the request is accepted by the Kubernetes API server.
For more information about webhooks in Kubernetes, please see the [Dynamic Admission Control][k8s-dac]
documentation.

In general, new infrastructure provider should not need to change the webhook configuration.

## Integrating with the Machine API Operator

There are several steps involved with integrating a new infrastructure provider into the
Machine API on OpenShift. The largest task will be creating the actuator which will do the
work of creating, deleting, and updating infrastructure resources. Beyond that, there
are some details around aligning the deployed release images, and the infrastrcuture detection
within the MAO.

### Machine API CRDs and ProviderSpec

MachineSets and Machines are the resources that describe the server instances within the
infrastructure provider. Each MachineSet contains a [Template][ms-template] field which
declares how new Machines should be created by embedding a [MachineSpec][machinespec]
object. The MachineSpec contains a field named [ProviderSpec][providerspec],
although this resource is not a CRD on its own, it is an embedded API type that
allows each infrastructure provider to have a different set of variables to use when creating
new Machines.

While the MachineSet and Machine objects will not need to change to accomodate new infrastructure
providers, the ProviderSpec will need to be created specifically for each new provider.  For example
here are the ProviderSpecs for Alibaba Cloud and IBM Cloud:

* [ProviderSpec defined for Alibaba Cloud][ali-providerspec]
* [ProviderSpec defined for IBM Cloud][ibm-providerspec]

When creating a new ProviderSpec it is natural to begin development with the API type defined
within the repository for the new component (akin to the IBM Cloud example). Before final
release the ProviderSpec API code should be moved to the [openshift/api][api-repo] repository
(similar to the Alibaba Cloud example). All new ProviderSpecs will be at API version `v1`.
The rationale for adding these types to the API repository is that it makes it easier to
re-vendor those API types into other projects, and it promotes a more thorough API review
process. Keep in mind that when adding changes to the API repository, all dependent
repositories (for example installer) will need to be re-vendored after the API changes have
merged. The following pull request is an example of how to integrate a new ProviderSpec into the
API repository:

* [Machine API: adding Alibaba cloud provider types #1045][ali-api-pr]

### Machine Controllers and Actuators

As noted above, the Machine controller manages Machine resources. The Machine controller is also
the interface between the MAO, the Machine API CRDs, and the infrastructure provider. The
controller wraps the [actuator interface][actuator-interface] which talks directly to the
infrastructure provider. The actuator interface is the contact point between OpenShift's
Machine API and a provider's infrastructure. This diagram illustrates the relationships:

```ascii
+----------+              +--------------------+
| Machine  |  reconciles  | Machine controller |
| Resource |<-------------|                    |                +----------------+
+----------+              |    +----------+    |  communicates  |                |
                          |    | actuator |----+--------------->| Infrastructure |
                          |    +----------+    |                |                |
                          +--------------------+                +----------------+
```

When writing a new actuator implementation, it is helpful to first start by looking at the
controller wrapper which is provided by the MAO. The controller is defined in the
[controller.go][machine-controller] file of the [machine-api-operator][mao-repo] repository.
This controller is used by each infrastructure provider to associate its actuator code
with the Machine reconciliation. The machine controller is designed to work with
[controller-runtime managers][controller-runtime] using the `AddWithActuator` method.
For example, here is how the Machine controllers and actuators are configured for AWS and IBM
Cloud:

* [AWS Machine controller actuator configuration][aws-actuator-call]
* [IBM Cloud Machine controller actuator configuration][ibm-actuator-call]

The majority of the work when implmenting a Machine controller for a new infrastructure provider
will be satisfying the [actuator interface][actuator-interface] defined by the MAO. The interface
itself is small enough that it can be reproduced here:

```go
type Actuator interface {
    // Create the machine.
    Create(context.Context, *machinev1.Machine) error
    // Delete the machine. If no error is returned, it is assumed that all dependent resources have been cleaned up.
    Delete(context.Context, *machinev1.Machine) error
    // Update the machine to the provided definition.
    Update(context.Context, *machinev1.Machine) error
    // Checks if the machine currently exists.
    Exists(context.Context, *machinev1.Machine) (bool, error)
}
```
The following are two examples of Machine actuator implementations:

* [AWS Machine actuator][aws-actuator]
* [IBM Cloud Machine actuator][ibm-actuator]

### MachineSet Controllers

Infrastructure provider-specific MachineSet controllers are used to enable scale-from-zero
features with the cluster autoscaler as described in this
[OpenShift enhancement on Autoscaling from/to zero][sfz-enhancement]. Unlike the Machine
controller and actuator provided by the MAO, there is no corresponding helpers for
implementing a MachineSet controller.

The following are two examples of MachineSet controllers which implement scale from/to zero:

* [AWS MachineSet controller][aws-machineset]
* [IBM Cloud MachineSet controller][ibm-machineset]

### Adding the new controllers to the Machine API operator

With all the necessary controller code and repositories created, the final step for integration
with the Machine API is adding the new infrastructure provider to the Machine API operator.
This process involves adding a manifest for a cloud credential request, adding the container
image references, and updating the operator to detect the new platform.

These changes are best illustrated through example, the following pull request show
the addition of the IBM Cloud provider to the Machine API operator. Take special
note of the `CredentialsRequest` as this is the resource to encode provider-specific
access roles.

* [IBM Cloud provider addition to Machine API operator][ibm-mao-pr]

## Integrating with OpenShift

In addition to implementing the controllers and actuators for a new Machine API provider,
the repository containing this code will need to be included in the OpenShift
organization on GitHub. After adding the new repository to the organization, it will then
need to be configured for continuous integration testing and image creation.

### Add Machine API provider repo to OpenShift

For the highest levels of integration with OpenShift, it is recommended to copy the
new infrastructure provider code repository to the OpenShift organization on GitHub.
Migrating the code to this organization will help to ensure that the OpenShift continuous
integration processes have full access to the source repository.

To begin adding a new Machine API infrastructure provider repository the first step is
the repository name. It should have a format of `machine-api-provider-$PROVIDER_NAME`,
where `$PROVIDER_NAME` is replaced with the infrastructure name. For example, the AWS
provider is `machine-api-provider-aws`.

The repository will need to be copied into the OpenShift organization.
This process is described in more detail in the
[Creating a GitHub Repository in the OpenShift Organization](../procedures/creating-an-openshift-repository)
document.

Having the source code in the OpenShift organization will allow Red Hat's continuous
integration tooling access to it for running tests, building images, and including in
the official releases.

### Configure basic repository integrations

After setting up the code repository, there are several continuous integration
tasks which must be done. This process is described in more detail in the
[Configuring Basic Repository Integrations](../procedures/configuring-repository-integrations)
document.

As an example, here is the pull request to add the MAPI provider for IBM Cloud to the
OpenShift Prow. It configures the Tide mechanics as well as pre-submit jobs to
run the unit tests and check Go language formatting, and post-submit jobs to
build the container images.

* [openshift/release #19890](https://github.com/openshift/release/pull/19890)

## Relation to Cluster API

The Machine API shares a common ancestry with the [Cluster API project][capi-project].
In the early days of Cluster API development, the Machine API was solidified
around the Machine and Machineset object definitions. Over time, the Machine API
has continued to grow in accordance with the needs of OpenShift users. It is worth
noting that the Machine API is **not** API compatible with the current versions of Cluster API.


[mao-repo]: https://github.com/openshift/machine-api-operator
[capi-project]: https://cluster-api.sigs.k8s.io
[actuator-interface]: https://github.com/openshift/machine-api-operator/blob/master/pkg/controller/machine/actuator.go#
[ml-pattern]: https://github.com/openshift/enhancements/blob/master/enhancements/machine-api/machine-instance-lifecycle.md
[mao-overview]: https://github.com/openshift/machine-api-operator/blob/master/docs/user/machine-api-operator-overview.md
[mao-hackguide]: https://github.com/openshift/machine-api-operator/blob/master/docs/dev/hacking-guide.md
[ms-template]: https://github.com/openshift/api/blob/release-4.10/machine/v1beta1/types_machineset.go#L52
[machinespec]: https://github.com/openshift/api/blob/release-4.10/machine/v1beta1/types_machine.go#L163
[providerspec]: https://github.com/openshift/api/blob/release-4.10/machine/v1beta1/types_machine.go#L186
[ali-providerspec]: https://github.com/openshift/api/blob/master/machine/v1/types_alibabaprovider.go
[ibm-providerspec]: https://github.com/openshift/cluster-api-provider-ibmcloud/blob/release-4.10/pkg/apis/ibmcloudprovider/v1beta1/ibmcloudproviderconfig_types.go#L30
[machine-controller]: https://github.com/openshift/machine-api-operator/blob/master/pkg/controller/machine/controller.go
[controller-runtime]: https://github.com/kubernetes-sigs/controller-runtime
[aws-actuator-call]: https://github.com/openshift/machine-api-provider-aws/blob/main/cmd/manager/main.go#L161
[ibm-actuator-call]: https://github.com/openshift/cluster-api-provider-ibmcloud/blob/main/cmd/manager/main.go#L143
[actuator-interface]: https://github.com/openshift/machine-api-operator/blob/master/pkg/controller/machine/actuator.go
[aws-actuator]: https://github.com/openshift/machine-api-provider-aws/blob/main/pkg/actuators/machine/actuator.go
[ibm-actuator]: https://github.com/openshift/cluster-api-provider-ibmcloud/blob/main/pkg/actuators/machine/actuator.go
[sfz-enhancement]: https://github.com/openshift/enhancements/blob/master/enhancements/machine-api/autoscaling-from-to-zero.md
[aws-machineset]: https://github.com/openshift/machine-api-provider-aws/blob/main/pkg/actuators/machineset/controller.go
[ibm-machineset]: https://github.com/openshift/cluster-api-provider-ibmcloud/blob/main/pkg/actuators/machineset/controller.go
[ibm-mao-pr]: https://github.com/openshift/machine-api-operator/pull/871
[api-repo]: https://github.com/openshift/api
[k8s-dac]: https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/
[mhc-docs]: https://docs.openshift.com/container-platform/latest/machine_management/deploying-machine-health-checks.html
[ali-api-pr]: https://github.com/openshift/api/pull/1045
