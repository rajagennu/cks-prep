# Service Accounts
- namespace bounded. 
- 'default' service account is available in every k8s namespace. 

## Using service accounts 
- service account tokens are temporary, if you trigger another run of `k create sa <sa_name>` you will get another service account. 
- this is a jwt token

```bash
root@cks-master:~# k get sa
NAME      SECRETS   AGE
default   0         16d
root@cks-master:~# k create sa accessor
serviceaccount/accessor created
root@cks-master:~# k get sa
NAME       SECRETS   AGE
accessor   0         4s
default    0         16d
root@cks-master:~# k create token accessor
eyJhbGciOiJSUzI1NiIsImtpZCI6IkUtXzlOQzVJWFJDd0xWMy1MWGpIN3E4ZC0xdlNWUFlFWGNMQjBVbHdYa3cifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNjY2ODA2MDA1LCJpYXQiOjE2NjY4MDI0MDUsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJkZWZhdWx0Iiwic2VydmljZWFjY291bnQiOnsibmFtZSI6ImFjY2Vzc29yIiwidWlkIjoiYzI4MzQ3YjQtNDY3Ni00Mzg4LThiNjktYzM4N2U1MjRjZmNkIn19LCJuYmYiOjE2NjY4MDI0MDUsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDpkZWZhdWx0OmFjY2Vzc29yIn0.Go6jUHVesGwpHbtxOX396HrmiKpsYKaSibxBsHsiS-KRGK4yixvsSR-LbfpKG7U-4xBdlTV-AAkJVn4JpAuXozAjjq-FsLvck85YRo1BI3hYbK5Ghiar-GuNZzHeJF53CjkXpH0iQnlzReeRwvn5m-yZUT2HQmcExIoWaScvIBBvnFLlvfdxZ-Hkl5bLRdUfSDvjVbdIH4JiWxEt8VUARKQHr5CLbZNgGKyFcbup6a1xCqP0l4FxX8-zMN7jCDx3N2TcNLVEQIRy5u6xgAtHWHiBto1ZhpzFCzUs3QOzDXNy6QeHFLV6__-jjrb4oCMTFA7CxQ5DG6sZWUCwoJFs_A
root@cks-master:~# k create token accessor
eyJhbGciOiJSUzI1NiIsImtpZCI6IkUtXzlOQzVJWFJDd0xWMy1MWGpIN3E4ZC0xdlNWUFlFWGNMQjBVbHdYa3cifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNjY2ODA3MDU3LCJpYXQiOjE2NjY4MDM0NTcsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJkZWZhdWx0Iiwic2VydmljZWFjY291bnQiOnsibmFtZSI6ImFjY2Vzc29yIiwidWlkIjoiYzI4MzQ3YjQtNDY3Ni00Mzg4LThiNjktYzM4N2U1MjRjZmNkIn19LCJuYmYiOjE2NjY4MDM0NTcsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDpkZWZhdWx0OmFjY2Vzc29yIn0.gCVEz92Mv9S4lCzte57_Z1kApdXkA_N-5oeq9gueETcnF7Npyrhz1iUcR0K_oF5E8odtuoW8_MjGOfMUeEQ_NvagHn8xDTDFKe59jOHJDY3Pg6t44fMAJX0seKouKjOxgF4xjC5iVguJ4FeqyiN8SPheOQGN7cjfbIaGlGYBoGy3vjmuFSa4JCL-CWMxZ9bKLR8lot3ZsAZfK38Ci4BN6VkjxrDKKsEJK-VhWVlHTTQcWdQJjxY6i2OTJnSr61BUeIH3rhy18jXGKlwupTQ_sIEOz8NfOiv0ET1iTTkRdj6Xseyz010gSWw_AY83aon5qJorW-BUDW3B9KEG8tF5Ng
root@cks-master:~# 
```

URL : **https://jwt.io/** use this to decode the JWT token.

- to start a pod with a custom service account, instead of default.
`spec.serviceAccountName: <service_account_name>`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    name: nginx
spec:
  serviceAccountName: accessor
  containers:
    - image: nginx
       name: nginx
```
- create the pod and enter into -it console of the pod

```bash
root@cks-master:/vagrant# kubectl create -f definitions/nginx-pod.yaml 
pod/nginx-pod created
root@cks-master:/vagrant# kubectl get pods
NAME        READY   STATUS    RESTARTS        AGE
nginx       1/1     Running   3 (3m40s ago)   17d
nginx-pod   1/1     Running   0               4s
root@cks-master:/vagrant# kubectl exec -it nginx-pod -it -- bash
```

- check for service account mount with 

```bash
root@nginx-pod:/# mount | grep ser
tmpfs on /run/secrets/kubernetes.io/serviceaccount type tmpfs (ro,relatime,size=1938312k)
```
- so service account mounted in that location. see the contents of that file.

```bash
root@nginx-pod:/# cd /run/secrets/kubernetes.io/serviceaccount
root@nginx-pod:/run/secrets/kubernetes.io/serviceaccount# ls
ca.crt  namespace  token
root@nginx-pod:/run/secrets/kubernetes.io/serviceaccount# cat token 
eyJhbGciOiJSUzI1NiIsImtpZCI6IkUtXzlOQzVJWFJDd0xWMy1MWGpIN3E4ZC0xdlNWUFlFWGNMQjBVbHdYa3cifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNjk4Mzc1ODUwLCJpYXQiOjE2NjY4Mzk4NTAsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJkZWZhdWx0IiwicG9kIjp7Im5hbWUiOiJuZ2lueC1wb2QiLCJ1aWQiOiIyMmQwMjgyNi1mYmM5LTRhZTgtYThjOS0yMTIxY2FkZTMyYTgifSwic2VydmljZWFjY291bnQiOnsibmFtZSI6ImFjY2Vzc29yIiwidWlkIjoiYzI4MzQ3YjQtNDY3Ni00Mzg4LThiNjktYzM4N2U1MjRjZmNkIn0sIndhcm5hZnRlciI6MTY2Njg0MzQ1N30sIm5iZiI6MTY2NjgzOTg1MCwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmRlZmF1bHQ6YWNjZXNzb3IifQ.r2N332XcwGlalhHFLIblNIWkBWObvbj_OCvgaKzOsBS9YLDbHS7Vrfs8Vwd3kL6TXeYnfXB950vqVs6d7bqIdFZFEr7cA-1mJRcVZel7HqiCI7vlDMnxbhGMFUrfA7mDpdz30Gd0WHZv5gK2wFE6JyMYW81VP7KsuFmM-ZUHrOp0597-tGrjsjOM71TNuNRuzhvOmg_3PVTAmej5mJhzA_8CXU1QD0MQXZvGHri74sBIivFGNWth046uTz2IQHmXCDgA3ITRnD2DkI4Onlca62I9R-BXNET3sZ3FKlGyZ_WsUT7LdlHAiOv4HW74xXVam9LjDdDaHE
root@nginx-pod:/run/secrets/kubernetes.io/serviceaccount# 
```

### Checking serviceaccount access over API.
( Please stay inside of the pod bash shell )
- get the API IP Address from kubernetes environment variables. 
```
root@cks-master:/vagrant# kubectl exec -it nginx-pod -it -- bash
root@nginx-pod:/# env | grep KUB
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_SERVICE_PORT=443
KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP_PROTO=tcp
KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
KUBERNETES_SERVICE_HOST=10.96.0.1 # this is what we are looking for.
KUBERNETES_PORT=tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP_PORT=443
root@nginx-pod:/# 
```

Then trigger the curl call to the API server

```bash
root@nginx-pod:/# curl -k https://10.96.0.1
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "forbidden: User \"system:anonymous\" cannot get path \"/\"",
  "reason": "Forbidden",
  "details": {},
  "code": 403
}
```
- lets pass JWT token which have information about service account as authorization bearer token and pass along. 
```bash
root@ngix-pod:/# curl -k https://10.96.0.1 -H "Authorization: Bearer $(cat /run/secrets/kubernetes.io/serviceaccount/token)"
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "forbidden: User \"system:serviceaccount:default:accessor\" cannot get path \"/\"",
  "reason": "Forbidden",
  "details": {},
  "code": 403
}root@nginx-pod:/# 
```
- lets include some path parameters like pods

```bash
root@nginx-pod:/# curl -k https://10.96.0.1/api/v1/namespaces/default/pods -H "Authorization: Bearer $(cat /run/secrets/kubernetes.io/serviceaccount/token)" | grep nginx  
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0        "name": "nginx",
          "run": "nginx"
                  "k:{\"name\":\"nginx\"}": {
            "name": "nginx",
            "image": "nginx",
            "name": "nginx",
            "image": "docker.io/library/nginx:latest",
            "imageID": "docker.io/library/nginx@sha256:47a8d86548c232e44625d813b45fd92e81d07c639092cd1f9a49d98e1fb5f737",
        "name": "nginx-pod",
          "run": "nginx-pod"
                  "k:{\"name\":\"nginx-pod\"}": {
            "name": "nginx-pod",
            "image": "nginx",
            "name": "nginx-pod",
            "image": "docker.io/library/nginx:latest",
            "imageID": "docker.io/library/nginx@sha256:47a8d86548c232e44625d813b45fd92e81d07c639092cd1f9a49d98e1fb5f737",
100 16584    0 16584    0     0  1245k      0 --:--:-- --:--:-- --:--:-- 1245k
root@nginx-pod:/# 
```

```
root@cks-master:/vagrant# k get po
NAME        READY   STATUS    RESTARTS      AGE
nginx       1/1     Running   3 (20m ago)   17d
nginx-pod   1/1     Running   0             17m
root@cks-master:/vagrant#
```

## Disable service account mount. 

- why we have to disable the service account in a pod ? Unless your pod has been created to interact with current k8s cluster specifically, you dont have to have a serviceaccount in your pod. 
- so by default, always disable serviceAccount mount in your k8s Pod.
- by using the property `spec.automountServiceAccountToken: false` we can disable serviceaccount mount.

@Q: will there be any situation where `spec.serviceAccountName` and `spec.automountServiceAccountToken` will be used at same time ?  if yes, what is the  use case ?

```bash
root@cks-master:/vagrant/definitions# k replace -f nginx-pod.yaml --force
pod "nginx-pod" deleted
pod/nginx-pod replaced
root@cks-master:/vagrant/definitions# k exec -it nginx-pod -it -- bash
root@nginx-pod:/# mount | grep ser
root@nginx-pod:/# 
```
- by default service account will not have any permissions.
- so as a principle of least privilege, have different service accounts for different application, give them required permissions and use.

```bash
root@cks-master:/vagrant/definitions# k auth can-i delete secrets --as system:serviceaccount:default:accessor
no
root@cks-master:/vagrant/definitions# k create clusterrolebinding accessor --clusterrole edit --serviceaccount default:accessor
clusterrolebinding.rbac.authorization.k8s.io/accessor created
root@cks-master:/vagrant/definitions# k auth can-i delete secrets --as system:serviceaccount:default:accessor
yes
root@cks-master:/vagrant/definitions# 
```

