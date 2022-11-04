
## Security Contexts
- Define privilege and access control for POD/Container
  - UserID and Group ID
  - Run privileged and unprivileged
  - Linux Capabilities.

```
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  volumes:
    - name: vol
      emptyDir: {}
  securityContext: # Pod Level
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000 # supplementary group ID
  containers:
    - command:
      - sh
      - -c
      - sleep 1d
    image: busybox
    name: busybox
    securityContext: # Container Level
      runAsUser: 0 
```

```bash
@rajagennu ➜ /workspaces/cks-prep (master ✗) $ kubectl run pod --image=busybox --command -oyaml --dry-run=client > pod.yaml -- sh -c 'sleep 1d'
@rajagennu ➜ /workspaces/cks-prep (master ✗) $ cat pod.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod
  name: pod
spec:
  containers:
  - command:
    - sh
    - -c
    - sleep 1d
    image: busybox
    name: pod
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
@rajagennu ➜ /workspaces/cks-prep (master ✗) $ mv pod.yaml files/
@rajagennu ➜ /workspaces/cks-prep (master ✗) $ cd files/
 
@rajagennu ➜ /workspaces/cks-prep/files (master ✗) $ vim pod.yaml 
@rajagennu ➜ /workspaces/cks-prep/files (master ✗) $ kubectl create -f pod.yaml 
pod/pod created
@rajagennu ➜ /workspaces/cks-prep/files (master ✗) $ kubectl get pods
NAME     READY   STATUS              RESTARTS      AGE
gvisor   0/1     ContainerCreating   0             49m
nginx    1/1     Running             1 (58m ago)   90m
pod      0/1     ContainerCreating   0             4s
 
@rajagennu ➜ /workspaces/cks-prep/files (master ✗) $ kubectl exec -it pod -- sh
/ # id
uid=0(root) gid=0(root) groups=0(root),10(wheel)
/ # exit
@rajagennu ➜ /workspaces/cks-prep/files (master ✗) $ vim pod.yaml 
 
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod
  name: pod
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
  containers:
  - command:
    - sh
    - -c
    - sleep 1d
    image: busybox
    name: pod
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {} 

@rajagennu ➜ /workspaces/cks-prep/files (master ✗) $ kubectl delete pod pod --force
Warning: Immediate deletion does not wait for confirmation that the running resource has been terminated. The resource may continue to run on the cluster indefinitely.
pod "pod" force deleted
@rajagennu ➜ /workspaces/cks-prep/files (master ✗) $ kubectl create -f pod.yaml 
pod/pod created
@rajagennu ➜ /workspaces/cks-prep/files (master ✗) $ kubectl exec -it pod -- sh
/ $ touch file
touch: file: Permission denied
/ $ cd /tmp/
/tmp $ touch file
/tmp $ ls -ltrh 
total 0      
-rw-r--r--    1 1000     3000           0 Nov  4 07:33 file
/tmp $ 
```

## Force container as non root user

On container layer add another security context as 

```
spec
  container
    securityContext:
      runAsNonRoot: true
```

## Privileged containers

By default docker containers run unprivileged

Possible to run privieleged to access all devices

```
docker run --privileged
```
Container process can directly map with kernel process 

```
spec
  container
    securityContext:
      privileged: true
```

### Privilege Escalation

Allow Privilege Escalation controls whether a process can gain more privileges than its parent process.

```
apiVersion: v1
kind: pod
metadata:
  name: priviesca
spec:
  containers:
    - name: priviesca
      image: nginx
      command:
        - sh
        - -c
        - 'sleep 1d'
      securityContext:
        allowPrivilegeEscalation: false
```

Privileged: Means that container user 0 ( root) is directly mapped to host user 0 (root), runs as root and same as root. 

privilegeEscalation: Allow Privilege Escalation controls whether a process can gain more privileges than its parent process.

with Privilege esclation as false

root@allow-priv-esca:/# cat /proc/1/status  | grep -i priv
NoNewPrivs:     1
root@allow-priv-esca:/# 

And as true
```
# cat /proc/1/status | grep -i priv
NoNewPrivs:     0
# 
```

## POD Security Policies

cluster level 
under which security condition a pod has to run.

- create a pod security policy, then all pods security context must comply this policy to run the cluster. 

`--enable-admission-plugins=PodSecurityPolicy`

Kind: PodSecurityPolicy

Once a pod security policy has been created, the serviceaccount of the pod must able to access the od security policy 

by default, service accounts wont have access to pod security policies.

so we have to create a role and bind that role to service accounts to provide the access

```
kubectl create role psp-access-view --verb=use --resource=podsecuritypolicies

kubectl create rolebinding psp-access-view --role=psp-access-view --serviceaccount=default:default

```

Q : How to start privileged containers ?

```
containers:
  - name: test
    image: {operator-repo}/test
    securityContext:
      privileged: true
```