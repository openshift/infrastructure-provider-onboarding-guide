# OpenShift Installation Validation | Disconnected | Platform None HighAvailability Topology

The steps below describes how to run the validation process of OpenShift cluster installed
in disconnected environment.

--8<-- "docs/validation/shared/user-ccsp-process-overview.md"

## Prerequisites

### OpenShift Installation

--8<-- "docs/validation/shared/user-pre-ocp-install-agnostic-ha.md"

#### Disconnected Environment <a name="disconnected-env-setup"></a>

The OPCT requires numerous images during the setup and execution of tests.
The steps below describes how to configure a mirror registry and how to run the
OPCT to rely on the mirror registry for images.

Prerequisites/Requirements:

- Disconnected Mirror Image Registry created
- [Private cluster Installed](https://docs.openshift.com/container-platform/latest/installing/installing_bare_metal/installing-restricted-networks-bare-metal.html)
- [You created a registry on your mirror host](https://docs.openshift.com/container-platform/latest/installing/disconnected_install/installing-mirroring-installation-images.html#installing-mirroring-installation-images)

#### Configuring the Disconnected Mirror Registry

1. Extract the `openshift-tests` executable associated with the version of OpenShift you are installing.
_Note:_ The pull secret must contain both your OpenShift pull secret as well credentials for the disconnected
mirror registry.
~~~
PULL_SECRET=/path/to/pull-secret
OPENSHIFT_TESTS_IMAGE=$(oc get is -n openshift tests -o=jsonpath='{.spec.tags[0].from.name}')
oc image extract -a ${PULL_SECRET} "${OPENSHIFT_TESTS_IMAGE}" --file="/usr/bin/openshift-tests"
chmod +x openshift-tests
~~~

2. Extract the images and the location to where they are to be mirrored from the `openshift-tests` executable.  

~~~
TARGET_REPO=target-registry.net/ocp-cert
./openshift-tests images --to-repository ${TARGET_REPO} > images-to-mirror
~~~

3. Append Sonobuoy to the `images-to-mirror` list
~~~
SONOBUOY_TAG=$(./openshift-provider-cert-linux-amd64 version | grep "Sonobuoy Version:" | cut -d' ' -f 3)
SONOBUOY_TARGET=${TARGET_REPO}/sonobuoy:${SONOBUOY_TAG}
echo "quay.io/ocp-cert/sonobuoy:${SONOBUOY_TAG} ${SONOBUOY_TARGET}" >> images-to-mirror
~~~

4. Append the OPCT tools image to the `images-to-mirror` list

~~~
OPCT_VERSION=v0.4.0-alpha1
OPCT_TARGET=${TARGET_REPO}/openshift-tests-provider-cert:${OPCT_VERSION}
echo "quay.io/ocp-cert/openshift-tests-provider-cert:${OPCT_VERSION} ${OPCT_TARGET}" >> images-to-mirror
~~~

5. Mirror the images to the disconnected mirror registry

~~~
oc image mirror -a ${PULL_SECRET} -f images-to-mirror
~~~


#### Preparing Your Cluster

- The Insights operator must be disabled prior to to running tests.  See [Disabling insights operator](https://docs.openshift.com/container-platform/latest/support/remote_health_monitoring/opting-out-of-remote-health-reporting.html)
- The [Image Registry Operator](https://docs.openshift.com/container-platform/latest/registry/index.html) must be configured and available


### OPCT validation tool

--8<-- "docs/validation/shared/user-pre-opct.md"

--8<-- "docs/validation/shared/user-pre-opct-dedicated.md"

--8<-- "docs/validation/shared/user-pre-opct-privileges.md"

--8<-- "docs/validation/shared/user-pre-opct-install.md"

<!-- Running validation tests -->

--8<-- "docs/validation/shared/user-opct-run.md"

#### Run with the Disconnected Mirror registry<a name="usage-run-disconnected"></a>

Tests are able to be run in a disconnected environment through the use of a mirror registry.

Requirements for running tests with a disconnected mirror registry:

- Disconnected Mirror Image Registry created
- [Private cluster Installed](https://docs.openshift.com/container-platform/latest/installing/installing_bare_metal/installing-restricted-networks-bare-metal.html)
- [You created a registry on your mirror host](https://docs.openshift.com/container-platform/latest/installing/disconnected_install/installing-mirroring-installation-images.html#installing-mirroring-installation-images)


To run tests such that they use images hosted by the Disconnected Mirror registry:

~~~sh
openshift-provider-cert run --image-repository ${TARGET_REPO}
~~~


--8<-- "docs/validation/shared/user-opct-run-options.md"

--8<-- "docs/validation/shared/user-opct-monitor-collect.md"

<!-- Reading results validation tests -->

--8<-- "docs/validation/shared/user-opct-results.md"

<!-- ccsp submit -->

--8<-- "docs/validation/shared/user-ccsp-submit.md"

<!-- Destroy validation process -->

--8<-- "docs/validation/shared/user-opct-destroy.md"