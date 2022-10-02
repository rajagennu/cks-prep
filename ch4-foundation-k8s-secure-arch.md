- kubectl talks to API Server to perform any tasks in the k8s cluster.
- A Node can become a worker node by having kubelet service installed in it, with container runtime and by joining a k8s cluster, it can receive the workloads scheduled by API Server.
- the kubelet service running inside the POD will notify API Server for every lifecycle event of every POD thats there in that node. For example, if new pod request received, then creating pod, start pod, if any issues and pod deleted, all these events will be notified to API Server.
- Scheduler: Scheduler talks to API Server, scheduler decides on which node the current pod should run. It has all the logic of taints, affinity rules, tolerations so it will decide the best node on which the pod can be scheduled.
- ETCD ( cluster): A key value pair datastorage, used by k8s for storing all cluster related information. Only API server talks to ETCD ( Cluster)
- Controller Manager: various controller managers to achieve runtime desired status of the pods.
- Cloud Controller manager: for cloud managed k8s cluster and runtimes. 
- kube-proxy: a service in worker nodes, to allow communication between pods, ports and services.
  - service represented in the kube-proxy. mostly IP Tables rules implemented in each node.
  - every pod communicates with every other pod by default in the cluster.
- PKI : Public Key Infrastructure 
- CA: Certificate Authority.
  - trusted root of all certs inside the cluster.
  - all cluster certs ae signed by the CA
  - used by components to validate each other.

## Location of certs

```bash
root@cks-master:~# cd /etc/kubernetes/pki/
root@cks-master:/etc/kubernetes/pki# ls -l
total 60
-rw-r--r-- 1 root root 1155 Oct  2 14:43 apiserver-etcd-client.crt
-rw------- 1 root root 1675 Oct  2 14:43 apiserver-etcd-client.key
-rw-r--r-- 1 root root 1164 Oct  2 14:43 apiserver-kubelet-client.crt
-rw------- 1 root root 1679 Oct  2 14:43 apiserver-kubelet-client.key
-rw-r--r-- 1 root root 1285 Oct  2 14:43 apiserver.crt
-rw------- 1 root root 1675 Oct  2 14:43 apiserver.key
-rw-r--r-- 1 root root 1099 Oct  2 14:43 ca.crt
-rw------- 1 root root 1675 Oct  2 14:43 ca.key
drwxr-xr-x 2 root root 4096 Oct  2 14:43 etcd
-rw-r--r-- 1 root root 1115 Oct  2 14:43 front-proxy-ca.crt
-rw------- 1 root root 1675 Oct  2 14:43 front-proxy-ca.key
-rw-r--r-- 1 root root 1119 Oct  2 14:43 front-proxy-client.crt
-rw------- 1 root root 1675 Oct  2 14:43 front-proxy-client.key
-rw------- 1 root root 1679 Oct  2 14:43 sa.key
-rw------- 1 root root  451 Oct  2 14:43 sa.pub
root@cks-master:/etc/kubernetes/pki# ls -l etcd/
total 32
-rw-r--r-- 1 root root 1086 Oct  2 14:43 ca.crt
-rw------- 1 root root 1679 Oct  2 14:43 ca.key
-rw-r--r-- 1 root root 1159 Oct  2 14:43 healthcheck-client.crt
-rw------- 1 root root 1679 Oct  2 14:43 healthcheck-client.key
-rw-r--r-- 1 root root 1204 Oct  2 14:43 peer.crt
-rw------- 1 root root 1679 Oct  2 14:43 peer.key
-rw-r--r-- 1 root root 1204 Oct  2 14:43 server.crt
-rw------- 1 root root 1675 Oct  2 14:43 server.key
root@cks-master:/etc/kubernetes/pki# vim /etc/kubernetes/scheduler.conf
root@cks-master:/etc/kubernetes/pki# vim /etc/kubernetes/controller-manager.conf
root@cks-master:/etc/kubernetes/pki# vim /etc/kubernetes/kubelet.conf
root@cks-master:/etc/kubernetes/pki# vim /etc/kubernetes/kubelet.conf
root@cks-master:/etc/kubernetes/pki# ls /var/lib/kubelet/pki/
kubelet-client-2022-10-02-14-43-05.pem  kubelet.crt
kubelet-client-current.pem              kubelet.key
root@cks-master:/etc/kubernetes/pki# ls /var/lib/kubelet/pki/ -l
total 12
-rw------- 1 root root 2830 Oct  2 14:43 kubelet-client-2022-10-02-14-43-05.pem
lrwxrwxrwx 1 root root   59 Oct  2 14:43 kubelet-client-current.pem -> /var/lib/kubelet/pki/kubelet-client-2022-10-02-14-43-05.pem
-rw-r--r-- 1 root root 2266 Oct  2 14:43 kubelet.crt
-rw------- 1 root root 1679 Oct  2 14:43 kubelet.key
root@cks-master:/etc/kubernetes/pki#
```

Ref:

# All You Need to Know About Certificates in Kubernetes
https://www.youtube.com/watch?v=gXz4cq3PKdg

# Kubernetes Components
https://kubernetes.io/docs/concepts/overview/components

# PKI certificates and requirements
https://kubernetes.io/docs/setup/best-practices/certificates