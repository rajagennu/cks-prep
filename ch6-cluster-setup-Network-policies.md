# Network Policies
- firewall rules in k8s
- implemented by the network plugins CNI ( calico / weave)
- Namespace level
- Restrict the ingress and Egress for a group of Pods based on certain rules and conditions

- without network policies, every pod can access every pod, by default.
- pods are not isolated.

- using podSelector we apply network policies to pods
- Ingress : Incoming traffic
- Egress: outgoing traffic

- using namespaceSelector : in namespace level
- ipBlock: blocking the communication based on IP Range.



```yaml
kind: NetworkPolicy
metadata:
  name: example
  namespace: default
spec:
  podSelector:
    matchLabels:
      id: frontend
  policyTypes:
    - Egress # till this line meaning is, block all outgoing traffic from pods with label as frontend in the namespace 'default'
  egress: # with this line we are defining where outgoing traffice allowed from default:label:frontend
    - to:
      - namespaceSelector:
          matchLabels:
            id: ns1 # allow the traffice to namespace ns1
      ports:
      - protocol: TCP
        port: 80    # to port 80, so all services which are listening on port 80 can receive this traffic in the ns1 namespace.
        
    - to:   # this is the 2nd to rule, that means or logic, one should be true, above one or this.
      - podSelector:
          matchLabels:
            id: backend # all pods with label is backend will receive the traffic across the same namespace.
            
```

** Multiple Network Policies **
- Possible to have multiple NPs selecting the same pods
- if a pod has more than one NP
  - then the union of all NPs is applied.
  - order doesnt affect the policy result.
  
 NetworkPolicy: Example 2
 
 ```yaml
kind: NetworkPolicy
metadata:
  name: example2
  namespace: default
spec:
  podSelector:
    matchLabels:
      id: frontend
  policyTypes:
    - Egress # till this line meaning is, block all outgoing traffic from pods with label as frontend in the namespace 'default'
  egress: # with this line we are defining where outgoing traffice allowed from default:label:frontend
    - to:
      - namespaceSelector:
          matchLabels:
            id: ns1 # allow the traffice to namespace ns1
      ports:
      - protocol: TCP
        port: 80    # to port 80, so all services which are listening on port 80 can receive this traffic in the ns1 namespace.
```

Network Poliocy: Example 3

```yaml
kind: NetworkPolicy
metadata:
  name: example3
  namespace: default
spec:
  podSelector:
    matchLabels:
      id: frontend
  policyTypes:
    - Egress # till this line meaning is, block all outgoing traffic from pods with label as frontend in the namespace 'default'
  egress: # with this line we are defining where outgoing traffice allowed from default:label:frontend
   - to:   # this is the 2nd to rule, that means or logic, one should be true, above one or this.
      - podSelector:
          matchLabels:
            id: backend # all pods with label is backend will receive the traffic across the same namespace.
```

The first example = example 2 + example 3 policies.

# Default Deny
- if you apply a default deny ( default-deny.yaml ), even DNS resolution will not work. so one pod cant reach another pod by name even though later you applied network policies

```bash
kubectl run frontend --image=nginx
kubectl run backend --image=nginx

# expose the port to send/receive the traffic
kubectl expose pod frontend --port 80
kubectl expose pod backend--port 80

# get the services
kubectl get pod,svc

# check the access between ports and pods
kubectl exec frontend -- curl backend 
kubectl exec backend -- curl frontend
```

Now lets write a default deny network policy that will deny both incoming and outgoing traffic between all pods in a namespace

file: default-deny.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: default
spec:
  podSelector: {} # empty i.e to all pods in the namespace: default
  policyTypes:
  - Ingress # block incoming
  - Egress # block outgoing
```
Lets create the policy and check the access again between front end and backend 
```
kubectl create -f default-deny.yaml
kubectl exec frontend -- curl backend # it wont work 
kubectl exec backend -- curl frontend # it wont work.
```

Now lets allow outgoing traffic to front end and allow incoming traffic to backend

file: front-engress-policy.yaml 
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend
  namespace: default
spec:
  podSelector:
    matchLabels:
      run: frontend
  policyTypes:
  - Egress # allow external traffic from frontend pods
  egress:
    - to
      - podSelector:
          matchLabels:
            run: backend
            
```

create the policy
```
kubectl create -f front-engress-policy.yaml
```

file: backend-ingress-policy.yaml 
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend
  namespace: default
spec:
  podSelector:
    matchLabels:
      run: backend
  policyTypes:
  - Ingress # allow incoming traffic from frontend pods
  ingress:
    - from
      - podSelector:
          matchLabels:
            run: frontend
            
```

create the policy
```
kubectl create -f backend-ingress-policy.yaml
```

Now check the access again 
```
kubectl exec frontend -- curl backend
```
Still it wont work, because default deny will block DNS Resolution as well, Pod cant reached by name from another pod in the network layer. But it works in the IP Level
```
curl exec front -- curl <ip of backend pod from 'k get pods -o wide' command>
```

Now it should work.

Now lets create a new database pod in a new namespace 'namespace-casandra'
Then allow the backend traffic to pod-cassandra [backend:Egress]
and allow pod-cassanda to accept that traffic so [cassandra:Igress]

```
kubectl create ns cassandra
kubectl edit ns cassandra << to add a label >>

apiVersion: v1
kind: Namespace
metadata:
  <here add the label section>
  labels:
    ns: cassandra
```
- Network policies uses selectors that always needs labels to match. podSelector, namespaceSelector etc.

```
k -n cassandra run cassandra --image=linux
```
Now we have to allow backend traffic to cassandra but to namespace cassandra, so it will external traffic, so policy will be Egress and there will be a 'to' policy

So take the earlier policy we have created for backend

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend
  namespace: default
spec:
  podSelector:
    matchLabels:
      run: backend
  policyTypes:
  - Ingress # allow incoming traffic from frontend pods
  - Egress # allow outgoing traffic to cassadra namespace
  ingress:
    - from
      - podSelector:
          matchLabels:
            run: frontend
  egress
    - to
      - namespaceSelector:
        matchLabels:
          ns: cassandra
          
```

```
kubectl apply -f policy.file.yaml
kubectl exec  backend -- curl <ip of cassandra>
```
As network polices are namesapce bounded, lets apply a default deny policy for cassandra namespace as well.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-cassandra
  namespace: cassandra
spec:
  podSelector: {} # empty i.e to all pods in the namespace: default
  policyTypes:
  - Ingress # block incoming
  - Egress # block outgoing
```
Now if you try access(income) backend from cassandra pod, it wont work. Lets add a Ingress rule for cassandra namespace to access traffice from default namespace.

```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: cassandra
  namespace: cassandra
spec:
  podSelector:
    matchLabels:
      run: cassandra
  policyTypes:
  - Ingress # allow incoming traffic from frontend pods
  
  ingress:
    - from
     - namespaceSelector:
        matchLabels:
          ns: default
```
- As above edit the default namespace and add a label as "ns: default"

Now check again.
```
kubectl apply -f policy.file.yaml
kubectl exec  backend -- curl <ip of cassandra>
```

Egress traffic policy with DNS

```yaml
controlplane $ cat network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np
  namespace: space1
spec:
  podSelector: {}
  policyTypes:
  - Egress
  
  egress:
    - to:
      - namespaceSelector:
          matchLabels:
            ns: space2
    - ports:
      - protocol: TCP
        port: 53
      - protocol: UDP
        port: 53
```

Ingress traffic policy with DNS

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np
  namespace: space2
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            ns: space1
    - ports:
      - protocol: TCP
        port: 53
      - protocol: UDP
        port: 53
```

# Exercise
- From default namespace, allow traffic to cassandra namespace only port 80 and from only a specifc pod.
- 

# References

### frontend->backend NP
https://github.com/killer-sh/cks-course-environment/tree/master/course-content/cluster-setup/network-policies/frontend-backend

### default-deny NP which still allows DNS resolution
https://github.com/killer-sh/cks-course-environment/blob/master/course-content/cluster-setup/network-policies/default-deny/default-deny-allow-dns.yaml

### docs - network-policies
https://kubernetes.io/docs/concepts/services-networking/network-policies


