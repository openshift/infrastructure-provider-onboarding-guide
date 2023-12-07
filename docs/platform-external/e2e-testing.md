# Conformance tests

After the OpenShift/OKD cluster has been installed, you want to run OpenShift conformance
tests (e2e) to validate OpenShift core components.

The Continuous Integration (CI) testing for OpenShift and its supported infrastructure providers is handled through Prow; the same system used for the Kubernetes project. You can read more in the guide for [Continuous Integration and Testing](../continuous-integration-and-testing).

For non-integrated providers, or when the provider is looking to run a small set of tests,
it is possible to achieve this with the following tools:

- `openshift-tests`: the utility implements several extended conformance suites (e2e) for OpenShift.
- `opct`: [OpenShift/OKD Provider Compatibility Tool](https://redhat-openshift-ecosystem.github.io/provider-certification-tool/) orchestrate a set of kubernetes and OpenShift conformance suite in a target installation, providing summarized feedback of the execution, and results of several checks for the expected behavior for production-ready clusters while the tests have been executed. OPCT uses `openshift-tests` as an engine of test suites, and [Sonobuoy](https://sonobuoy.io/) as an orchestrator.

This guide explores how to run a conformance workflow with OPCT.

## openshift-tests utility

The `openshift-tests` utility is used to run the end-to-end (e2e) tests on OpenShift. The utility implements all the tests and suites, and groups e2e tests with a similar purpose. The `openshift/conformance` suite will be used to validate a cluster.

### Prerequisites

Install the utility by extracting from the release image:

```sh
export VERSION=${CLUSTER_VERSION:-4.14.0}
oc adm release extract \
    --tools quay.io/openshift-release-dev/ocp-release:${VERSION}-x86_64 \
    -a ${PULL_SECRET_FILE}

tar xvfz openshift-install-linux-${VERSION}.tar.gz
RELEASE_IMAGE=$(./openshift-install version | awk '/release image/ {print $3}')
TESTS_IMAGE=$(oc adm release info --image-for='tests' $RELEASE_IMAGE)
oc image extract $TESTS_IMAGE \
    --file="/usr/bin/openshift-tests" \
    -a ${PULL_SECRET_FILE}
chmod u+x ./openshift-tests
```

where:

- `PULL_SECRET_FILE` is the registry credentials used to pull container images from the repository.

### Running the OpenShift conformance suite

- Run the utility:

```sh
openshift-tests run openshift/conformance --junit-dir /tmp/results
```

The results are available in `/tmp/results` directory

## OPCT utility

The OPCT is an option when the provider does not have integration with OpenShift CI and wants to get quick feedback about conformance execution in their infrastructure.

The tool allows to orchestration of conformance test suites used in OpenShift CI in
custom installations using [OpenShift Provider Compatibility Tool (OPCT)](https://redhat-openshift-ecosystem.github.io/provider-certification-tool/user/), providing signals of the custom installations is passing on the e2e tests required for a healthy OpenShift installation.

OPCT orchestrates a single workflow with the following steps:

- conformance tests for upgrade: when enabled, it runs an upgrade to the target release with a couple of tests monitoring the upgrade
- kubernetes conformance suite: the standard kubernetes conformance suite
- openshift conformance suite: the `openshift/conformance` suite
- artifacts collector: collect data must-gather, disk performance, Prometheus metrics, etc

There are variants like disconnected, ARM, upgrades, etc which are not covered by this guide.
To learn more about the variants, take a look at the OpenShift documentation page
["Installation Overview"](https://docs.openshift.com/container-platform/latest/installing/).

### Prerequisites

- [opct installed][opct-install]
- KUBECONFIG environment variable exported
- Persistent storage for image registry. [Here][image-registry-storage-bm] is an example used by Bare Metal.
- [A dedicated node created for the test environment](https://redhat-openshift-ecosystem.github.io/provider-certification-tool/user/#standard-env-setup-node)

[opct-install]: https://redhat-openshift-ecosystem.github.io/provider-certification-tool/user/#install
[image-registry-storage-bm]: https://docs.openshift.com/container-platform/4.13/registry/configuring_registry_storage/configuring-registry-storage-baremetal.html

### Running the conformance suites

- Start the tests

```sh
opct run --watch
```

- Collect the results

```sh
opct retrieve
```

- Review the results

```sh
opct report artifact.tar.gz
```

- Extended report: An HTML report will be created with details to drill down into the results

```sh
opct report artifact.tar.gz --save-to /tmp/results --loglevel debug
```

For more details, read the documentation.

### Destroying the environment

```sh
opct destroy
```