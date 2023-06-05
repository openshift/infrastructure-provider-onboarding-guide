# Overview

There are many ways to run validation tests in OpenShift. OpenShift provides many specific suites to validate the cluster aside the regular [kubernetes conformance suites]() running in [Red Hat OpenShift CI infrastructure](/continuous-integration-and-testing/).

Red Hat also provides a program to validate OpenShift installations for CCSP partners. This section describes the steps to run the validation of an OpenShift installation and submit to the CCSP/Validated program.

The validation process uses the [OpenShift Provider Compatibility Tool (OPCT)](https://redhat-openshift-ecosystem.github.io/provider-certification-tool/) to run the validation environment outside the Red Hat OpenShift CI Infrastructure, although anyone can consume the tool to self-evaluate a custom OpenShift installation.

Please see the following pages according your goal:

<!-- - [CCSP/Validated Overview](./ccsp-overview.md) -->
- Validation Guides:
    - [Standard OpenShift Validation for Agnostic Installation](./guides/validate-standard-platform-none-ha.md)
    - [Standard Upgrade OpenShift Validation for Agnostic Installation](./guides/validate-upgrade-platform-none-ha.md)
    - [OpenShift Validation for Agnostic Installation in Disconnected environments](./guides/validate-standard-platform-none-ha.md)
- [Submiting the results to Red Hat Partner Support](./ccsp-submit.md)