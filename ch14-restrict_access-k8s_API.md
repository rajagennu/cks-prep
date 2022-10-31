# Restrict Access

- 3 levels of access control
- Authentication : who 
- Authorization : permissions
- Admission control : limit has been reache ?
  - own admission controllers
  - 3rd party adminission controllers

API requests are always tied to 
  - a normal user
  - a serviceaccount
  - Are trated as anonymouse requests

Every request must authenticate
  - or be trated as an anonymouse user

## Restrictions

1. Dont allow anonymous access
2. close insecure port 8080 ((( Deprecated, skip)))
3. dont expose apiserver to the outside
4. restrict access from Nodes to API(NodeRestriction)
5. Prevent unauthorized access
6. prevent pods from accessing API.

## Anonymouse Access

kube-apiserver `--anonymouse-auth=true|false`
1. Go to master node
2. vim /etc/kubernetes/manifests/kube-apiserver.yaml
3. look for /anony: if not found any
4. check if anonymous is default enabled 

```yaml
curl -k https://localhost:6443
```
5. to disable add `- --anonymouse=false`
6. As changed, kube api server pod will be rebooted
7. k -n kube-system get pod | grep api
8. check again with point 4. 
9. anonymouse access needed for liveness probe checks, so if diabled, enable it back.


**Note:** Since 1.20 , --insecure-port=8080 is decprecated and removed. 
If you have cluster < 1.20, you can add this to kubeapi server yaml and reload the pod(will happen automatically) try accessing the apiserver cluster on http via 8080 port.

## Sending manual API Requests
- To see current config file of k8s ( one of below works)
-   k config view
-   k config view --raw
-   vim .kube/config

* using the --raw command, copy the client ceritificate, client key and CA certificate from kubeconfig
* these are base64 encoded, so decode them into base64 -d 
* store them in crt, key and ca files respectivily 
* API server request: `curl https://<IP>:6443 --cacert ca --cert crt --key key`
  
## Sendint API Request from outside.

- to send external requests to k8s cluster service: kubernetes must be NodePort instead of ClusterIP(local)
- k edit svc kubernetes, switch from ClusterIP to NodePort
- copy the .kube/config to local machine. 
- copy the port of the nodeport for kubernetes service
- use the curl command as above to get the access. 
- we can also send  remote commands from local kubectl
- copy the .kube/config file from your cluster to local machine and save it like conf.
- Note: using we can use a custom conf file with kubectl as below

```
k --kubeconfig conf get ns
```
- there will be a field called 'server' in the kubeconfig file. which represents the API server IP Address, if your conf file have NAT IP Address, make you replace the IP with public IP Address.
- you might get invalid certificate as you are trying to connect with IP Address for which the certificate not generated, verify for what IP Addresses the certificate has been generated using below command,

```
openssl req -in <apiserver.crt> -text
```
- so instead of using public IP, by editing local /etc/hosts and a host entry for one of the CI Name with public IP and try again
**<IP> kubernetes** 
  
- then try again 
  
  
```
k --kubeconfig conf get ns
```
  
## Node restriction - Admission controller
kube-apiserver --enable-admission-plugins=NodeRestriction
Limit the node labels a kubelet can modify
  
- Ensure secure workload isolation via labels.

- check in the master node, manifest kube api server yaml, check for --enable-admission-plugins, NodeRestriction is default. 
  - login to a worker node and run k config view
  - vim /etc/kubernetes/kubelet.conf
  - export KUBECONFIG=/etc/kubernetes/kubelet.conf
  - then from worker node, try 
  k get ns # this wont work , because of node restriction
  k get nodes # this works
  
- k label node cks-worker node-restriction.kubernetes.io/test=yes # this wont work as api server has blocked this via above mentioned config param.
  
  
 ## Log locations
 
/var/log/pods
/var/log/containers
crictl ps + crictl logs
docker ps + docker logs (in case when Docker is used)
kubelet logs: /var/log/syslog or journalctl



