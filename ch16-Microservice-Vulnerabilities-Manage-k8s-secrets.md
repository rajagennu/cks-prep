# Secrets

## Overview


## Create Secure Secret Scenario

```
k create secret generic secret1 --from-literal user=admin
k create secret generic secret2 --from-literal pass=12345678
```

k run pod --imag=nginx -oyaml > nginx-pod.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    pod: nginx
   name: nginx-pod
spec:
  containers:
  - image: nginx
    name: nginx
    env:
      - name: Password
        valueFrom: 
          secretKeyRef:
            name: secret2
            key: pass
     volumeMounts:
     - name: secret1
       mountPath: "/etc/secret1"
       readOnly: true
    volumes:
      - name: secret1
        secret:
          secretName: secret1
```

$ k exec pod -- env | grep Pass
$ k exec pod -- mount | grep secret1

## Hack some secrets
- find the pod, identify in whcih node its running.
- give crictl inspect <container_id> of that pod which you can find from 
- from inspect output you can read environment variables. 
- if password is mounted, then find the PID of container via inspect command 
- `find /proc/<PID>/root/etc/secret1/user`

## Hack secrets in etcd
- etcd must be encrypted. 
- 
From API Server you can identify the required certs, key from kube-apiserver.yaml file. 

```yaml
ECTDCTL_API=3 etcdctl --cert /etc/kubernetes/pki/apiserver-etcd-client.crt \
--key /etc/kubernetes/pki/apiserver-etcd-client.key --cacert /etc/kubernetes/pki/etcd/ca.crt endpoint health

ECTDCTL_API=3 etcdctl --cert /etc/kubernetes/pki/apiserver-etcd-client.crt \
--key /etc/kubernetes/pki/apiserver-etcd-client.key --cacert /etc/kubernetes/pki/etcd/ca.crt get /registry/secrets/default/secret2


ECTDCTL_API=3 etcdctl --cert /etc/kubernetes/pki/apiserver-etcd-client.crt \
--key /etc/kubernetes/pki/apiserver-etcd-client.key --cacert /etc/kubernetes/pki/etcd/ca.crt get /registry/secrets/default/secret1

```

## ETCD encryption
- apiserver is only component which talks to etcd. its responsible for enc/dec
- encrypt secrets at rest.
- We create a resource named 'EncryptionConfiguration' and refer the yaml file location with '--encryption-provider-config' 
```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
    - secrets
    providers:
    - identify: {} # to read the plain text secrets 
    - aesgcm: # to read the encrypted secrets
        keys:
          - name: key 1
            secret: <SECRET KEY HERE>
```

resources.providers will apply in order, and 'identify {}' : this indicates when storing its stored as plain text but while reading etcd data will be encrypted.

- to encrypt all the secrets in the etcd cluster

```
kubectl get secrets --all-namespaces -o json | kubectl replace -f 
```

### Decrypt the keys 
```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
    - secrets
    providers:
    - identify: {} # to read the plain text secrets 
    - aesgcm: # to read the encrypted secrets
        keys:
          - name: key 1
            secret: <BASE64 encoded SECRET KEY HERE>
```

## Hands On Session

cd /etc/kubernetes/
mkdir etcd
cd etcd
vim ec.yaml 
# search in k8s doc encrypt data

```
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
    - secrets
    providers:
    - aescbc
        keys:
        - name: key1
          secret: <Base 64 encoded secret>
    - identify: {}
```
echo -n passwordwithminlengthof16please | base64 # this is the base64 encoded.
vim /etc/kubernetes/manifests/kube-apiserver.yaml
# add below lines 

```
- -- encryption-provider-config=/etc/kubernetes/etcd/ec.yaml

volumes:
  - hostPath:
      path: /etc/kubernetes/etcd
      type: DirectoryOrCreate
    name: etcd
    
volumeMounts:
  - mountPath: /etc/kubernetes/etcd
    name: etcd
    readOnly: true
```
    
Wait for apiserver pod to restart.

Try to read the default secret from the etcd cluster 

`ECTDCTL_API=3 etcdctl --cert /etc/kubernetes/pki/apiserver-etcd-client.crt \
--key /etc/kubernetes/pki/apiserver-etcd-client.key --cacert /etc/kubernetes/pki/etcd/ca.crt get /registry/secrets/default/default-token-s5fv8`

Note:  /registry/secrets/default/default-token-s5fv8 >> */registry/<resource like pod,development,secret>/namespace like default>/resource name>*

You will find this already created secret in plaintext.

Create a new secret

k create secret generic newsecret --from-literal  cc=1234

`ECTDCTL_API=3 etcdctl --cert /etc/kubernetes/pki/apiserver-etcd-client.crt \
--key /etc/kubernetes/pki/apiserver-etcd-client.key --cacert /etc/kubernetes/pki/etcd/ca.crt get /registry/secrets/default/newsecret`

This secret will be encrypted. 

to encrypt all secrets which are not encrypted you can use 
`k get secrets all -o json | k replace -f -`

if you dont add identity : {}, then unencrypted secrets cant be read unless you replaced all secrets with above command. 
  
## ConfigMaps and Secrets
- configmpas dont have secrets, no need encryption
- secrets meant for password and sensitive info, this need encryption. 

## Notes
```
k create secret generic holy --from-literal creditcard=1111222233334444
k create secret generic diver --from-file  /opt/ks/secret-diver.yaml

k run pod1 --image=nginx -oyaml --dry-run=client > pod1.yaml

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod1
  name: pod1
spec:
  volumes:
  - name: diver
    secret:
      secretName: diver
  containers:
  - image: nginx
    name: pod1
    resources: {}
    volumeMounts:
    - name: diver
      mountPath: "/etc/diver/hosts"
      readOnly: true
    env:
      - name: holy
        valueFrom:
          secretKeyRef:
            name: holy
            key: creditcard
            optional: false 

kubectl create -f pod1.yaml
  

controlplane $ k get secrets -n one
NAME   TYPE     DATA   AGE
s1     Opaque   1      22s
s2     Opaque   1      22s
controlplane $ k get secrets -n one --type Opaque
error: unknown flag: --type
See 'kubectl get --help' for usage.
controlplane $ k get secret s1 -n one
NAME   TYPE     DATA   AGE
s1     Opaque   1      63s
controlplane $ k get secret s1 -n one -o yaml
apiVersion: v1
data:
  data: c2VjcmV0
kind: Secret
metadata:
  creationTimestamp: "2022-11-02T02:54:57Z"
  name: s1
  namespace: one
  resourceVersion: "1012"
  uid: fd2f6206-5851-4424-b271-a68fd691b75b
type: Opaque
controlplane $ base64 -d c2VjcmV0
base64: c2VjcmV0: No such file or directory
controlplane $ base64 -d c2VjcmV0^C
controlplane $ echo c2VjcmV0 | base64 -d
secretcontrolplane $ echo c2VjcmV0 | base64 -d >> /opt/ks/one
controlplane $ k get secret s2 -n one -o yaml
apiVersion: v1
data:
  data: YWRtaW4=
kind: Secret
metadata:
  creationTimestamp: "2022-11-02T02:54:57Z"
  name: s2
  namespace: one
  resourceVersion: "1016"
  uid: fcfc94d0-e394-4365-a13e-a6eee7806ba7
type: Opaque
controlplane $ echo YWRtaW4= | base64 -d 
admincontrolplane $ echo YWRtaW4= | base64 -d  >> /opt/ks/one 
controlplane $ 

