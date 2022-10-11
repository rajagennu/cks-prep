# Protect Node Metadata and Endpoints

## Cloud Platform Node Metadata
- Metadata service API by default reachable from cloud VMs, like AWS, AZURE and GCP. This metadata VM is hosted in the cloud and accessable by all VMs.
- this metadata VM can contain cloud credentials for VMs/Nodes
- Can contain provisioning data like kubelet credentials.


## Access sensitive Node Metadata

- Ensure that the cloud-instance-account has only the necessary permissions.
- each cloud provider has a set of recommentations to follow.
- not in the hands of k8s


## Restrict access using NetworkPolicies
- with default k8s deployment, pods can reach to metadata service directly.
- so we have to allow only pods that are allowed to metadata service VMs and block all.

to manage the pod lables, we can use
```
k get pod --show-labels
k label pod nginx role=metadata-accessor
```

# Ref
- https://github.com/killer-sh/cks-course-environment/tree/master/course-content/cluster-setup/protect-node-metadata
