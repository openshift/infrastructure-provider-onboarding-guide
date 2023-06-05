
## Collect the results <a name="usage-retrieve"></a>

The results must be retrieved from the OpenShift cluster under test using:

```sh
openshift-provider-cert retrieve

# OR save to the target directory

openshift-provider-cert retrieve ./destination-dir/
```

The file must be saved locally.


## Review the results <a name="usage-results"></a>

You can see a summarized view of the results using:

```sh
openshift-provider-cert results <retrieved-archive>.tar.gz
```