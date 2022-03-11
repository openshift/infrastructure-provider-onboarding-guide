# RHCOS Platform Support

To support a new platform one of the main requirements is to have Red Hat Enterprise Linux CoreOS (RHCOS) operating system work on the platform for provisioning the machines. This [getting started guide](https://docs.fedoraproject.org/en-US/fedora-coreos/getting-started/) gives a good overview of the Fedora CoreOS (FCOS) operating system and way to provision machines on different platforms. The process of building RHCOS and FCOS is largely the same except for the packages contained inside of the OS itself (RHEL vs Fedora).

## File a ticket for new platform support

Please make sure to file a ticket against [Fedora-CoreOS-Tracker](https://github.com/coreos/fedora-coreos-tracker.git) by filing a new issue and choosing the [Request a new platform](https://github.com/coreos/fedora-coreos-tracker/issues/new/choose) option.
Some important questions to be thought about/answered in the platform request tracker are:

- The official name of the platform - the name by which Ignition will identify the platform. Note that this can be different from the platform name used by the Openshift APIs
- How is userdata provided - this refers to how [Ignition](https://github.com/coreos/ignition) configuration is provided for this platform.
- How is the hostname provided - the method through which the machine gets its hostname. this could be through dhcp or a service like [afterburn](https://github.com/coreos/afterburn)
- How is network configuration provided - the method through which network is configured - through DHCP or static ips provided in the metadata which can be accessed through services like afterburn
- How are ssh keys provided
- Details of the VM image which is to be built and published - this includes things like APIs to upload VM images, the disk format specification, etc..

Any new platform being added should first support FCOS (Fedora CoreOS) making sure that once the platform is fully supported that there are regular upstream CI jobs run to test FCOS and publish FCOS images.

## Support for building and publishing disk images

If you are looking into building and publishing new disk images, you need to start with looking at the [coreos-assembler](https://github.com/coreos/coreos-assembler#readme) tool. The coreos-assembler is a collection of tools inside a containerized build environment which is used to build and publish FCOS and RHCOS images. Some useful links on how to develop and use the coreos assembler:

- [Working with CoreOS Assembler guide](https://github.com/coreos/coreos-assembler/blob/main/docs/working.md)
- [Building Fedora CoreOS](https://github.com/coreos/coreos-assembler/blob/main/docs/building-fcos.md)
- [Working on CoreOS Assembler guide](https://github.com/coreos/coreos-assembler/blob/main/docs/devel.md)
- [CoreOS Assembler Design](https://github.com/coreos/coreos-assembler/blob/main/docs/design.md)

In addition, there are tools that help you test your image locally and also help you upload your images to the cloud. [Mantle](https://github.com/coreos/coreos-assembler/tree/main/mantle#mantle-gluing-container-linux-together) inside the coreos-assembler has a bunch of tools which help with different things:

- kola - for launching instances and running tests
- kolet - an agent for kola that runs on instances
- ore - for interfacing with cloud providers

## Ignition support

[Ignition](https://github.com/coreos/ignition#ignition) is a utility that configures the machine. A list of supported platforms and how they provide the configuration to Ignition is listed [here](https://github.com/coreos/ignition/blob/main/docs/supported-platforms.md). Whenever a new platform is added, corresponding code must be added to specify the way to [fetch configuration](https://github.com/coreos/ignition/tree/main/internal/providers) for the platform.

## Afterburn support

[Afterburn](https://github.com/coreos/afterburn) is used to implement cloud provider specific functionality by interacting with its metadata endpoints. It can be used to optionally set things like hostname and also inject network kernel command line arguments. In addition, it is also used to retrieve attributes from the metadata. Once added, some of this functionality can be enabled as systemd units in the Machine Config Operator.

## Questions

Questions can be directed to these various [communication channels for Fedora CoreOS](https://github.com/coreos/fedora-coreos-tracker#communication-channels-for-fedora-coreos)