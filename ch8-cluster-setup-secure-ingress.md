# Ingress Objects with security Control

## What is ingress
- services in kubernetes always points to PODs via daemon sets.
- 1st service type : cluster IP is a service type and that means the service is reachable internally inside the cluster by that IP and DNS Name.
- 2nd service type : Node Port is another service type, but inside its like a "port forwarding" + Cluster IP.
- Internally we know cluster IP can be used to refer the service or dnS Name indeed.
- Along with this, when we can NodePort service, it will open a port across each node where the respective pod running which represents this service, kube-proxy will open the port for node port.
- Whenever a service requests came to that port of node, that request will be forwarded to cluster IP of the service.
- something like this
  - NodeIP:Node Port ----->>> CLusterIP:Pod Port

- 3rd Service Type: Load Balancer
  - Load Balancer is a Node Port service which internally calls cluster IP service.
  - available only for cloud k8s providers.


# Lab - Create an Ingress
- use the install nginx ingress from ref links
- inspect the namespaces, pods, services created along.
- check the yaml code.
- try to access the nodeport service.
- then create a ingress.yaml with reference to code from k8s ingress documentation for services
- https://kubernetes.io/docs/concepts/services-networking/ingress/

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx-example
  rules:
  - http:
      paths:
      - path: /service1 # when nodeIP:nodeport/service1 types it will redirect to backend.service.name
        pathType: Prefix
        backend:
          service:
            name: service1 # to this service.
            port:
              number: 80
  - http:
      paths:
      - path: /service2 # when nodeIP:nodeport/service1 types it will redirect to backend.service.name
        pathType: Prefix
        backend:
            service:
            name: service2 # to this service
            port:
                number: 80

```

So now setup is like
Ref: https://kubernetes.io/docs/concepts/services-networking/ingress/#what-is-ingress 
Ingress controller for nginx -> Ingress routings -> Service(pending) -> Pods(pending)

so lets create pods and their respective services

```
kubectl run pod1 --image=nginx
kubectl run pod2 --image=httpd
kubectl expose pod pod1 --port 80 --name service1
kubectl expose pod pod2 --port 80 --name service2
```

Now try to access
nodeIPO:nodeport/service1 and service2

## Secure Ingress
Ingress + TLS

1. create the self signed certs for TLS

```
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
```
Common-name (CN) is the domain name: secure-ingress.com as exaample

2. lets create the secret

```
kubectl create tls secure-ingress --cert=cert.pem --key=key.pem
```

3. open the ingress yaml we have above and update the TLS section from https://kubernetes.io/docs/concepts/services-networking/ingress/#tls 

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-example-ingress
spec:
  tls:
  - hosts:
      - https-example.foo.com
    secretName: testsecret-tls
  rules:
```

so updated yaml looks like , edit the yaml and use apply command 
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  tls:
    - hosts:
      - secure-ingress.com
    secretName: secure-ingress
  ingressClassName: nginx-example
  rules:
  - host: secure-ingress.com
  - http:
      paths:
      - path: /service1 # when nodeIP:nodeport/service1 types it will redirect to backend.service.name
        pathType: Prefix
        backend:
          service:
            name: service1 # to this service.
            port:
              number: 80
  - http:
      paths:
      - path: /service2 # when nodeIP:nodeport/service1 types it will redirect to backend.service.name
        pathType: Prefix
        backend:
            service:
            name: service2 # to this service
            port:
                number: 80
```

- so the created TLS certs will be used only when we are accessing the services via that URL: secure-ingress.com
  - secure-ingress.com/service1
  - secure-ingress.com/service2
  - We can do this two methods, either provide an entry in /etc/hosts for secure-ingress.com DNS resolution.
  - or, tell the curl command to resolve as well

```
curl https://secure-ingress.com:<nodeport>/service2 -kv --resolve secure-ingress.com:31047:<node IP>
```

check the ingress-example image at images/ingress_example.png for more understanding what we are trying to achieve.




# Ref

# Install NGINX Ingress
kubectl apply -f https://raw.githubusercontent.com/killer-sh/cks-course-environment/master/course-content/cluster-setup/secure-ingress/nginx-ingress-controller.yaml


# Complete Example
https://github.com/killer-sh/cks-course-environment/tree/master/course-content/cluster-setup/secure-ingress


# K8s Ingress Docs
https://kubernetes.io/docs/concepts/services-networking/ingress
