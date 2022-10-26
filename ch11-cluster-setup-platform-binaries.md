# verify platform binaries

## hashes
- file, validate if file from orginal author or sender, then verify finger print of the file called Hash, SHA Md5.

## verify the k8s version after downloading.
- go to kubernetes github page
- download the k8s release from the tags section of github
  - open the change log for checksum hashes
- Ex: https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.25.md#changelog-since-v1252
- then you can copy the sha512hash 

```bash
root@cks-master:/tmp# sha512sum kubernetes.tar.gz 
401fa061d339f5e9d03e06a5c3145cd805bc9fe16d8f1cab112e6f7c3f80e2bcc9116b7ca018afae9e77f1c5b84b388d65cd3e996a43c3546c55483dd3ef698e  kubernetes.tar.gz
root@cks-master:/tmp# 
```

## compare apiserver binary running inside container.
- login into master node control plane
- download the k8s server binary https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.25.md#changelog-since-v1252
- url : https://dl.k8s.io/v1.25.3/kubernetes-server-linux-amd64.tar.gz
- extract the file
- inside the kubernetes folder, you can see all the binaries. 
```bash
root@cks-master:/tmp# cd kubernetes/
root@cks-master:/tmp/kubernetes# ls
LICENSES  addons  kubernetes-src.tar.gz  server
root@cks-master:/tmp/kubernetes# cd server/
root@cks-master:/tmp/kubernetes/server# ls
bin
root@cks-master:/tmp/kubernetes/server# cd bin/
root@cks-master:/tmp/kubernetes/server/bin# ls
apiextensions-apiserver             kube-controller-manager.tar  kube-scheduler.tar
kube-aggregator                     kube-log-runner              kubeadm
kube-apiserver                      kube-proxy                   kubectl
kube-apiserver.docker_tag           kube-proxy.docker_tag        kubectl-convert
kube-apiserver.tar                  kube-proxy.tar               kubelet
kube-controller-manager             kube-scheduler               mounter
kube-controller-manager.docker_tag  kube-scheduler.docker_tag
root@cks-master:/tmp/kubernetes/server/bin# 
```
- get the sha512sum of kube-apiserver binary

```
root@cks-master:/tmp/kubernetes/server/bin# sha512sum ./kube-apiserver
d710ca5bf511bef684e962ced6e6ae20c4263e6707865c52245d0a60a032b9aa7ae93f7eada1484d825059240767831a817f1507dbb4d29fc82e0174a0c820c5  ./kube-apiserver
root@cks-master:/tmp/kubernetes/server/bin# 
```

- now lets verify same for the kube-apiserver inside our controlplane.
- Note: k8s images are hardened, so we cant find sha512sum command inside those containers.lets see the way of finding apiserver pod.

```

```bash
root@cks-master:/tmp/kubernetes/server/bin# kubectl get pods -n kube-system | grep api
kube-apiserver-cks-master                  1/1     Running   7 (58m ago)   16d
root@cks-master:/tmp/kubernetes/server/bin#

root@cks-master:/tmp/kubernetes/server/bin# kubectl get pods kube-apiserver-cks-master -n kube-system -oyaml | grep image
    image: k8s.gcr.io/kube-apiserver:v1.24.3
    imagePullPolicy: IfNotPresent
    image: k8s.gcr.io/kube-apiserver:v1.24.3
    imageID: k8s.gcr.io/kube-apiserver@sha256:a04609b85962da7e6531d32b75f652b4fb9f5fe0b0ee0aa160856faad8ec5d96
root@cks-master:/tmp/kubernetes/server/bin# 

root@cks-master:/tmp/kubernetes/server/bin# crictl ps | grep kube-apiserver-cks-master
8f665d8091520       d521dd763e2e3       58 minutes ago      Running             kube-apiserver            7                   ea5e9e56f156f       kube-apiserver-cks-master

# make sure you are running validations for correct version. 

root@cks-master:/tmp/kubernetes/server/bin# kubectl get pods kube-apiserver-cks-master -n kube-system -oyaml | grep image
    image: k8s.gcr.io/kube-apiserver:v1.24.3
    imagePullPolicy: IfNotPresent
    image: k8s.gcr.io/kube-apiserver:v1.24.3
    imageID: k8s.gcr.io/kube-apiserver@sha256:a04609b85962da7e6531d32b75f652b4fb9f5fe0b0ee0aa160856faad8ec5d96

# use kube-apiserver to find the current running PID of the container. 

root@cks-master:/tmp/kubernetes/server/bin# ps aux | grep kube-apiserver
root      3405  4.0 17.4 1174588 356644 ?      Ssl  06:39   2:28 kube-apiserver --advertise-address=192.168.56.10 --allow-privileged=true --authorization-mode=Node,RBAC --client-ca-file=/etc/kubernetes/pki/ca.crt --enable-admission-plugins=NodeRestriction --enable-bootstrap-token-auth=true --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key

# use the process to read files used by to find its binary

root@cks-master:/tmp/kubernetes/server/bin# find /proc/3405/root/ | grep kube-api
/proc/3405/root/usr/local/bin/kube-apiserver
root@cks-master:/tmp/kubernetes/server/bin# sha512sum /proc/3405/root/usr/local/bin/kube-apiserver
825d54af6bb4ea6f33d8581cf79e50b0c1067ff14a6e3e611742bb072a1b6100419ccf40ce993db78d0478d4d97c4722b74ce25c5b62e0a78451c3730c80d0b9  /proc/3405/root/usr/local/bin/kube-apiserver

```

Note: Kubelet is not a pod, its a process :), in case if you dont catch in the first read.
