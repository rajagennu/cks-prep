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
- 



