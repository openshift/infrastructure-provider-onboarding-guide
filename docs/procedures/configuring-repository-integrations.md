# Configuring Basic Repository Integrations

After the repository is copied to the OpenShift organization, there are a few basic
continuous integration tasks that should be configured. The most important of these
initially are the job to permit automated merging through [Tide][tide]
and the job to create container images on commits.

OpenShift uses [Prow][prow] for continuous integration testing much like the Kubernetes community does.
The configurations are contained in the [openshift/release][openshift-release]
repository. This is where pull requests will need to be made to enable integrations
for the new CCM.

For a deeper understanding of the OpenShift continuous integration tooling, the
[OpenShift CI Docs][ci-docs] are the authoritative source.  In specific for this initial task, the
[Bootstrapping Configuration for a new Repository][bootstrapping] should be used as a guide.

[tide]: https://github.com/kubernetes/test-infra/tree/master/prow/tide
[prow]: https://github.com/kubernetes/test-infra/tree/master/prow
[openshift-release]: https://github.com/openshift/release
[ci-docs]: https://docs.ci.openshift.org/
[bootstrapping]: https://docs.ci.openshift.org/docs/how-tos/onboarding-a-new-component/#bootstrapping-configuration-for-a-new-repository
