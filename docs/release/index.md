# Release

Red Hat releases new minor versions of OpenShift Container Platform approximately
once every 4 months. OpenShift versions use a [Semantic Versioning][semver]
style of denotation to designate specific versions. For example, version "4.8.1"
of OpenShift would designate that the major version is "4", the minor version
is "8", and the patch level is "1". OpenShift is currently releasing along the
major version "4" series. When the next version of OpenShift is released, it will be
"4.n+1", where "n" is the current minor version. For example, at the time of writing
the current version of OpenShift is "4.9", the next release will then be "4.10".

## Z-Stream Releases

While new minor versions of OpenShift are released every 4 months, "Z-Stream" releases
are created much more frequently to address security and critical bug fixes.
A z-stream release is designated by an increase in the patch level version of the
release. For example, version "4.8.1" of OpenShift would designate that the current
patch level is "1", if a new z-stream release is needed it will be version "4.8.2".

In general, backports to older versions of OpenShift will be evaluated on a case-by-case
basis. Security and critical bug fixes will be considered the highest priority
for backporting. Features are not backported without a justified exception from Red Hat.

## Integrating with the Release Process

For any minor version of OpenShift the release process consists of several important
phases which are traversed in this manner:

Feature Development -> Feature Freeze -> Code Freeze -> General Availability

### Feature Development

The feature development phase is a time when any change can be proposed to the
code repositories. There are no automated limitations on the pull requests that
can be proposed, and any work related to new features can be considered for inclusion.
Ideally, the bulk of new work will be created during this phase of development.

### Feature Freeze

Feature freeze is an important concept to understand when integrating with the
Red Hat release process. During the development of a new version of
OpenShift there will come a time when new feature work will be disallowed
into the code base. This process is referred to as "feature freeze" and it is used
to create a hard deadline for adding new features to a release. As new
infrastructure platforms are considered features, new components and changes
should be in place before the feature freeze.

Approximately 12 weeks before the general availability release for an OpenShift
version, the engineering team will observe the feature freeze. After the feature
freeze date, new pull requests will require a related bugzilla issue in order to
be considered for merging. This is not a mechanism for bringing features in though,
and should only be used to fix bugs within the existing code.

What this means is that new infrastructure providers should work to ensure
their provider specific components have been created and included in continuous
integration before the feature freeze. There will still be time to fix bugs,
but the major pieces should be in place (e.g. repositories created, continuous
integration configured, image builds automated).

### Code Freeze

Approximately 6 weeks after feature freeze the OpenShift engineering team will
observe a "code freeze". The code freeze indicates that no more pull requests
will be taken from the source repositories, and that the release teams will
now take over the process of performing the final testing and analysis, and
packaging of release artifacts.

During the time between the feature freeze and the code freeze, new pull
requests will be accepted provided they have a related bugzilla issue. After
code freeze these changes will not be considered or accepted unless they are
release blocking issues.

### General Availability

Once the source base that was compiled during the code freeze has been fully
tested and vetted by the Red Hat release teams, the new OpenShift Container
Platform version will be released for general availability. This process is
usually predicted to occur 6 weeks after the code freeze, but given the
possibility of release blocking bugs this is only an approximation.

If you have followed the instructions in this guide then your new components
will be ready for inclusion with the next OpenShift minor release. The final
piece necessary for being included in an OpenShift release from Red Hat are
full end-to-end integration of your infrastructure platform into the continuous
integration process (this is covered in greater detail in
[Continuous Integration and Testing][ci]).

When the end-to-end integration tests of the new infrastructure platform are passing
regularly, the new platform can be included in an OpenShift release. The new
components will have already been included in nightly and continuous integration
payloads, and they will now be promoted to the release payload.

## Release Life Cycle

After release, Red Hat provides a support and maintenance life cycle for the
version of OpenShift Container Platform depending on the release type and
version number. For more information about this process and the dates
associated with extended support, please see the
[Red Hat OpenShift Container Platform Life Cycle Policy][lifecycle]
document.

For some historical context around the release schedule and how Red Hat
has arrived at this process, please see the following articles:

* [Time Is On Your Side: A Change to the OpenShift 4 Lifecycle][blog1]
* [The Ultimate Guide to OpenShift Release and Upgrade Process for Cluster Administrators][blog2]



[semver]: https://semver.org/spec/v2.0.0.html
[ci]: ../continuous-integration-and-testing
[lifecycle]: https://access.redhat.com/support/policy/updates/openshift/
[blog1]: https://cloud.redhat.com/blog/time-is-on-your-side-a-change-to-the-openshift-4-lifecycle
[blog2]: https://cloud.redhat.com/blog/the-ultimate-guide-to-openshift-release-and-upgrade-process-for-cluster-administrators
