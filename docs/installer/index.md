# Installer

The [OpenShift Installer repo][repo] contains the code for the `openshift-install` Go binary as well as templates and documentation
for user-provisioned infrastructure. `openshift-install` provides a user interface for the installation process on multiple cloud platforms.
Users provide install configuration through an [`install-config.yaml`][install-config] file, which can be created interactively through the
`openshift-install create install-config` command. The installer uses this configuration to create Kubernetes manifests and ignition configs
for the virtual machines. In the case of installer-provisioned infrastructure, `openshift-install` uses Terraform to create the infrastructure
for the cluster. For user-provisioned infrastructure, [cloud-specific templates][upi] such as CloudFormation for AWS or ARM for Azure, are provided.

For a more detailed overview of the Installer, please read the [Installer Overview][overview]. For an overview of the general architecture
of a cluster see the [Architecture section of the official docs][arch].

For contributing to the Installer, please read the [Contributor Guidelines][contributing]. In particular, please note the guidelines regarding
commit messages. Code contributions should be grouped into logically organized commits with clear commit messages. OWNERS files should be added in platform specific subdirectories.

We recommend committing code to the Installer in the following order:

## pkg/types

The `types` package is the API for the Installer. As such, it should not contain any external dependencies so that the package can be cleanly
vendored to other repos.

* [Adding Alibaba Platform][types]
* [`openshift-install explain` command][explain]]

## pkg/assets:

For the design behind assets in the installer, see [the Asset Generation doc][asset-generation]. A suggested approach for adding assets
would be:

1. `pkg/assets/installconfig`
1. `pkg/assets/manifests`
1. `pkg/assets/machines`

* [Adding Alibaba Assets][asset-example].

## Terraform Integration

Integrate the Terraform provider by adding the plugin.
 
* [Adding Stages and Terraform Variables for Alibaba][tf-integration].

## Terraform Configs

Create the Terraform configurations at `/data/data/{platform}`.

* [Alibaba Terraform Configuration][tf-configs].

## Destroy

Add code to remove all resources created by the Installer and the cluster. The Installer
should loop until all known resources are destroyed.

* [Alibaba Destroy Code][destroy]

## Documentation

Add in-repo documentation, ideally following the general format of other platforms.

* [AWS docs][doc].

[repo]: https://www.github.com/openshift/installer
[install-config]: https://github.com/openshift/installer/blob/master/docs/user/customization.md
[upi]: https://github.com/openshift/installer/tree/master/upi
[overview]: https://github.com/openshift/installer/blob/master/docs/user/overview.md
[arch]: https://docs.openshift.com/container-platform/4.8/architecture/architecture-installation.html
[contributing]: https://github.com/openshift/installer/blob/master/CONTRIBUTING.md
[types]: https://github.com/openshift/installer/commit/590dc0c62d432d4d3ea1ca40aa84ba6f17bee780#diff-5dc50083bb8d12ad7439e48e73af24cc866f5fb59322144805cba65a8abdefc7
[explain]: https://github.com/openshift/installer/blob/master/docs/dev/explain.md
[asset-generation]: https://github.com/openshift/installer/blob/master/docs/design/assetgeneration.md
[asset-example]: https://github.com/openshift/installer/pull/5333/commits/0577ab9ff94b2688645186674ec0eec0c8b5c190
[tf-integration]: https://github.com/openshift/installer/pull/5333/commits/e99ecc6bf902542b207cd76274ec6f861279ab0e
[tf-configs]: https://github.com/openshift/installer/pull/5333/commits/75ca60ff2483379d29fe6b78064783ccbd4ee6db
[destroy]: https://github.com/openshift/installer/commit/0ef6c1367a42978059665be13e82a08ea74a7f37#diff-80f8e210f9e17a175682591d811168a5779aed19b3dee41f280014f2c2040127
[doc]: https://github.com/openshift/installer/tree/master/docs/user/aws