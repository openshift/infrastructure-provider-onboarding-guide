# OpenShift Provider Certification Tool

*TODO - summary*

## Process

More detail on each step can be found in sections further below. 

1. Prepare OpenShift cluster to be certified
2. Download and install provider certification tool
3. Run provider certification tool
4. Monitor tests 
5. Gather results
6. Share results with Red Hat


## Prerequisites

A Red Hat OpenShift 4 cluster must be [installed](https://docs.openshift.com/container-platform/latest/installing/index.html) before certification can begin. The OpenShift cluster must be installed on your infrastructure as if it were a production environment. Ensure that each feature of your infrastructure you plan to support with OpenShift is configured in the cluster (e.g. Load Balancers, Storage, special hardware).

Below is a table of the minimum resource requirements for the OpenShift cluster under test:

| Machine       | Count | CPU | RAM (GB) | Storage (GB) |
| ------------- | ----- | --- | -------- | ------------ |
| Bootstrap     | 1     | 4   | 16       | 100          |
| Control Plane | 3     | 4   | 16       | 100          |
| Compute       | 3     | 4   | 64       | 100          |


*Note: These requirements are higher than the [minimum requirements](https://docs.openshift.com/container-platform/latest/installing/installing_bare_metal/installing-bare-metal.html#installation-minimum-resource-requirements_installing-bare-metal) in OpenShift product documentation due to the resource demand of the certification tests.*


### Privilege Requirements

A user with [cluster administrator privilege](https://docs.openshift.com/container-platform/latest/authentication/using-rbac.html#creating-cluster-admin_using-rbac) must be used with the provider certification tool. You also use the default kubeadmin user if you wish. 


## Install


### Prebuilt Binary

The provider certification tool is shipped as a single executable binary which can be downloaded from:

[https://github.com/redhat-openshift-ecosystem/provider-certification-tool](https://github.com/redhat-openshift-ecosystem/provider-certification-tool)

The provider certification tool can be used from any system with network access to the OpenShift cluster under test. 


### Build from Source

See the development guide for more information.
*TODO - link*


## Usage


### Run provider certification tests

```sh
openshift-provider-cert run 
openshift-provider-cert run -w # Keep watch open until completion
```


### Check status

```sh
openshift-provider-cert status 
openshift-provider-cert status -w # Keep watch open until completion
```


### Retrieve the results

The certification results must be retrieved from the OpenShift cluster under test using:

```sh
openshift-provider-cert retrieve
openshift-provider-cert retrieve ./destination-dir/
```

You can see a summarized view of the results using:

```sh
openshift-provider-cert results retrieved-archive.tar.gz
```


### Environment Cleanup

Once the certification process is complete and you are comfortable with destroying the test environment:

```sh
openshift-provider-cert destroy
```

You will need to destroy the OpenShift cluster under test separately. 


### Certification Failures

If you already know the reason for a certification failure then resolve the problem and re-run the provider certification tool again so a new certification archive is created. 

If you are not sure why you have failed certification or if some of the tests fail intermittently, proceed with the troubleshooting steps below. 


### Troubleshooting

Using the _status_ command above will provide a high level overview but more information is needed to troubleshoot a problem with the provider certification tool or why you aren’t able to pass all certification checks. A Must Gather from the cluster and Inspection of sonobuoy namespace is the best way to start troubleshooting:

```sh
oc adm must-gather
oc adm inspect openshift-provider-certification
```

Use the two archives created by the commands above to begin troubleshooting. The must gather archive provides a snapshot view into the whole cluster. The inspection archive will contain information about the sonobuoy namespace only.
