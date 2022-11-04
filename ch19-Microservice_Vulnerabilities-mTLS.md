* mTLS / POD to Pod comm
- Mutual Auth
- two way auth
- secure channel bi directional

Req -> Ingress(https) -> Pod
Attack insider cluster, comm between pods can be listened via MINMiddle attack. 
Using mTLS, comms between pods can be encrypted. 

pod1->  pod2
pod1: client cert
pod2L server crt

pod1 <- pod2
pod1: server cert
pod2L client crt

with certs, we will have longer valid, if cert leaked , then rotation needed, lot of overhead and maintenance. 



* Service Mesh / Proxy

Pod1: App and proxy 
Pod2: App and proxy

Pod1: App1 -> Proxy1 -> Proxy 2 -> Pod2 and vice versa
Sidecar proxy 

needs NET_ADMIN capability 

```
k run app --image=bash --command -oyaml --dry-run=client -- sh -c 'ping google.com'

k logs app -f

```

Lets add sidecar proxy with NET_ADMIN capability

```
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: app
  name: app
spec:
  containers:
  - command:
    - sh
    - -c
    - ping google.com
    image: bash
    name: app
  - name:proxy
    image: ubuntu
    command: 
    - sh
    - -c
    - 'apt-get update && apt-get install iptables -y && iptables -L && sleep 1d'
    securityContext:
      capabilities:
        add: ["NET_ADMIN"]
```


