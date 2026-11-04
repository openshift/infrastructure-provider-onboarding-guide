# Troubleshooting Platform External installs

Symptoms seen while installing a `platform: external` cluster with a CAPI provider, and
what each one actually means. Grouped by the phase that produces them.

The reference walkthrough is
[Installing a cluster with Platform External using CAPA](./installing/capi-ref-image-aws.md).

## Building and publishing the payload image

### `http: server gave HTTP response to HTTPS client`

**Cause.** A local development registry serves plain HTTP; podman and skopeo default to
HTTPS.

**Fix.** Pass `--tls-verify=false`, or mark the registry insecure once:

```bash
sudo tee /etc/containers/registries.conf.d/localhost-5000.conf >/dev/null <<'EOF'
[[registry]]
location = "localhost:5000"
insecure = true
EOF
```

This affects your own `podman` and `skopeo` commands only — the installer passes
`--insecure` to `oc` on its own for loopback references.

### `requested access to the resource is denied` against `docker.io/library/false`

**Cause.** `--tls-verify` takes an optional value, so it must be joined by `=`. Written
with a space, `false` is parsed as the push **destination**.

**Fix.** `podman push --tls-verify=false <image>`. A denied push to Docker Hub reads like
a credentials problem and is really a missing character.

### `reading manifest <tag> in <registry>/<name>: manifest unknown`

**Cause.** The registry is answering correctly: it holds no such tag. TLS is working, or
the failure would have come at the handshake instead. The usual reason is building under
one image name and pushing under another.

**Fix.** Ask the registry what it has, then make the build, the push, the verification and
`install-config.yaml` all use the same string:

```bash
curl -s http://localhost:5000/v2/_catalog
curl -s "http://localhost:5000/v2/<name>/tags/list"
```

### `couldn't find remote ref` when building with `CAPA_REF`

**Cause.** The build does a shallow `git fetch origin <ref>`, which resolves a commit id
server-side rather than matching a prefix. An abbreviated SHA — such as the 12-character
form in a Go pseudo-version — cannot be resolved that way.

**Fix.** Use the full 40-character SHA; `git rev-parse <short-sha>` against a full clone
expands it.

### The rebuild produced the same image

**Cause.** Expected, not a fault: the build is fully cached when nothing in the build
context changed. Every blob reports `already exists` on push and the image keeps its
original creation timestamp.

**Fix.** Confirm it is the image you meant before concluding the build is broken:

```bash
skopeo inspect --tls-verify=false "docker://${PAYLOAD_IMAGE}" \
  | jq -r '"digest: \(.Digest)\ncreated: \(.Created)"'
find Containerfile payload -newermt "<the Created timestamp>"
```

An empty `find` means nothing changed and the cache hit is correct. Changing
`--build-arg CAPA_REF=` invalidates the cache on its own; `--no-cache` is needed only to
re-resolve the *same* ref.

## Payload validation, during `create manifests`

These all fail before any cloud resource is created, which is the point of validating the
payload at this stage.

### The installer rejects an executable the payload did not declare

**Cause.** Layout validation requires that every executable in the image is named in
`openshift.yaml`. A payload built `FROM` a conventional base image fails on the base
image's own `/bin` and `/usr/bin`.

**Fix.** Build the payload stage `FROM scratch`.

### A path declared in `openshift.yaml` does not exist in the image

**Cause.** `layout` names a file or directory the build did not copy — commonly a
`hooks:` entry, or a renamed template directory.

**Fix.** Compare the descriptor against the image contents; extract locally with
`oc image extract --path=/:<dir> --confirm --filter-by-os=linux/amd64` and list by
filename.

### The payload's compatibility range rejects the release

**Cause.** `compatibility.kubernetes.min`/`max` in `openshift.yaml` does not admit the
Kubernetes version of the OpenShift release being installed.

**Fix.** Widen the range only after testing the provider against that version. Bumping the
provider commit without revisiting this range is the common mistake.

### An unresolved `${VAR}` survives into the rendered templates

**Cause.** A token used by the payload's templates has no entry in
`platform.external.clusterAPI.variables`.

**Fix.** Add it. `INSTALLER_`-prefixed variables are supplied by the installer and must
not be set by the user; everything else is the provider's namespace.

### `oc` is not found

**Cause.** Image mode extracts the payload with `oc image extract`, so `oc` is a hard
runtime dependency of that mode. Local-path mode has no such dependency.

**Fix.** Install `oc` and put it on `PATH`. The installer checks before creating anything
in the cloud.

## Cluster API admission, during `create cluster`

### `spec.s3Bucket: Forbidden: can be set only if the BootstrapFormatIgnition feature gate is enabled`

**Cause.** CAPA's validating webhook rejects the `AWSCluster`. The same gate is what makes
`AWSMachine.spec.ignition` legal, so the install cannot proceed without it.

**Fix.** Include `BootstrapFormatIgnition=true` in the controller's `--feature-gates`
argument. It is not optional for this path.

## Install

### The install reaches the bootstrap timeout and fails resolving `api-int`

**Cause.** Nothing published the `api-int` record. In practice the `infraReady` hook was
skipped — neither the payload nor `install-config.yaml` declared one.

**Fix.** Declare an `infraReady` hook, or publish the record out of band before the
bootstrap node comes up. The installer warns and continues rather than refusing, because
out-of-band DNS is a legitimate deployment.

### Nodes register but stay `NotReady`, carrying `node.cloudprovider.kubernetes.io/uninitialized`

**Cause.** The cloud controller manager never ran, so nothing removed the taint and no
node received a `providerID`.

**Fix.** Check the CCM Deployment and its credentials:

```bash
oc get deployment -n openshift-cloud-controller-manager
oc get nodes -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.providerID}{"\n"}{end}'
```

On AWS the usual cause is an empty or missing `aws-cloud-credentials` Secret in
`openshift-cloud-controller-manager`. Verify its shape without printing it:

```bash
grep -c '^  credentials: [A-Za-z0-9+/=]\{40,\}$' <the extra-manifest>   # must be 1
```

### Compute nodes never join

**Cause.** Compute CSRs are not auto-approved on `platform: external`. This affects
`platform: none` as well and predates CAPI support.

**Fix.** Approve them, twice a minute or so apart — each node submits a client CSR first
and a serving CSR after it joins:

```bash
oc get csr --no-headers | awk '$NF=="Pending"{print $1}' | xargs -r oc adm certificate approve
```

### The `postProvision` hook appears to hang

**Cause.** Usually normal. A hook that waits for the ingress Service to be given a load
balancer address cannot finish until the cluster is far enough along for the ingress
operator to run. On a reference AWS run this took about 14 minutes.

**Fix.** Read the hook's own log lines before intervening; they report what they are
waiting for and the timeout they will wait until.

## Destroy

### `open data/cluster-api: no such file or directory`, after etcd has already started

**Cause.** A `MODE=dev` installer build reads its data assets from disk rather than from
the binary. Destroy needs them too — it unpacks the envtest control plane and the embedded
Cluster API components before it can restore anything.

**Fix.** Export `OPENSHIFT_INSTALL_DATA=<clone>/data/data` (note the doubled component).
A released binary does not need this.

### Destroy cannot start

**Cause.** Teardown runs through the provider that created the infrastructure, and needs
three things the install left behind: `metadata.json`, `.clusterapi_output/*.yaml`, and
the payload still extracted at `<install-dir>/capi-installer/`.

**Fix.** Keep the whole install directory. Without it there is nothing to destroy from.

### Resources appear to be left behind

**Cause.** Often a measurement error rather than a leak — an account-wide count includes
other people's resources and other clusters.

**Fix.** Scope every query to the cluster's own infrastructure ID and VPC before
concluding anything:

```bash
INFRA_ID=$(jq -r .infraID "${INSTALL_DIR}/metadata.json")
aws ec2 describe-instances \
  --filters "Name=tag-key,Values=kubernetes.io/cluster/${INFRA_ID}" \
  --query "length(Reservations[].Instances[?State.Name!='terminated'][])"
aws elbv2 describe-load-balancers --query "length(LoadBalancers[?VpcId=='${VPC_ID}'])"
```

If resources genuinely remain, they are most likely ones the provider did not create and
therefore cannot delete — a load balancer created by the ingress operator, or DNS records
written by a hook. Those belong to a `preDestroy` hook.

!!! warning "A single clean teardown is unverified"

    Teardown that works on the cluster it was developed against routinely fails on the
    next one, because the second cluster has resources the first did not. Run it twice,
    against two different clusters, before trusting it.

## Reading installer logs safely

The install log contains the kubeadmin password, and a generated manifest tree contains
TLS and CA private keys, the pull secret and the kubeadmin password hash. Neither should
be pasted into a ticket, a chat or a recording.

Ask narrow questions instead:

```bash
grep -c 'Install complete!' install.log
grep -c 'level=fatal' install.log
grep -n 'level=error' install.log | cut -c1-200
```

Serial console output needs URLs redacted before it is read — a pre-authenticated request
URL used to deliver bootstrap Ignition grants unauthenticated read over everything it
points at:

```bash
sed -E 's|https?://[^ ")]*|<URL-REDACTED>|g'
```
