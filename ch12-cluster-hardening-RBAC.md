# RBAC ( Role based access control)
- controlling access based on roles of the users in the organization. 
- in kubernetes, this access can be controlled at the first gate of k8s cluster which is kube-apiserver.
- `--autorization-mode` default is always allow, we can mention other autorozation modes like ABAC, RBAC , webhook etc.
- restrict the access to users and service accounts.
- works with roles and bindings
- specify what is allowed, everything else is DENIED.
- principle of least privilege. 
- role space: namespaces bounded.
- cluster space: k8s cluster, includes all namespaces. 

### Role
- giving get, watch, list for secrets in blue namespace
```yaml
metadata:
  namespace: blue
  name: secret-manager
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]

```

- giving get permission in red namespace for secrets

```yaml
metadata:
  namespace: red
  name: secret-manager
rules:
- apiGroups: [""]
  resources: [secrets]
  verbs: ["get"]
```

Even though the role name is same, as roles are namespaces bounded, these two roles are different. 

  
### ClusterRole

```yaml
metadata:
  name: secret-manager
rules:
- apiGroups: [""]
  resources: [secrets]
  verbs: ['get']
```
- cluster role is the same across all namespaces. 
- user X can be secret manager in multiple namespaces, permissions are same in each.
- cluster roles and role bindings applies to all current and all future role bindings. 
- if a role is in one namespace then using cluster role bindings we cant apply it across all namespaces. 

Role -> Role binding -> namespace bounded - works
CLuster Role -> Cluster role binding -> cluster bounded - works
Cluster role -> Role binding -> Namespace bounded - works
Role -> Cluster Role binding -> wont work. 

- permissions are additive. 
- Always test your RBAC rules. 

### Role and Rolebinding

- create user jane if not exist
- create a namespace red and blue.
- user jane can only get secrets in namespace red
- user jane can only get and list secrets in namespace blue.
- test it using auth can-i

```bash
root@cks-master:~# k create ns red
namespace/red created
root@cks-master:~# k create ns blue
namespace/blue created
root@cks-master:~# k -n red create role secret-manager --verb=get --resource=secrets -oyaml --dry-run=client
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  creationTimestamp: null
  name: secret-manager
  namespace: red
rules:
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - get
root@cks-master:~# k -n red create role secret-manager --verb=get --resource=secrets
role.rbac.authorization.k8s.io/secret-manager created
root@cks-master:~# k -n red create rolebinding secret-manager --role=secret-manager --user=jane -oyaml --dry=run=client
error: unknown flag: --dry
See 'kubectl create rolebinding --help' for usage.
root@cks-master:~# k -n red create rolebinding secret-manager --role=secret-manager --user=jane -oyaml --dry-run=client
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  creationTimestamp: null
  name: secret-manager
  namespace: red
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: secret-manager
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: jane
root@cks-master:~# k -n red create rolebinding secret-manager --role=secret-manager --user=jane
rolebinding.rbac.authorization.k8s.io/secret-manager created
root@cks-master:~# k -n blue create role secret-manager --verb=get,watch,list --resource=secrets
role.rbac.authorization.k8s.io/secret-manager created
root@cks-master:~# k -n blue create rolebinding secret-manager --role secret-manager --user jane
rolebinding.rbac.authorization.k8s.io/secret-manager created
root@cks-master:~# k auth can-i get secrets --as jane
no
root@cks-master:~# k auth can-i get secrets --as jane -n red
yes
root@cks-master:~# k auth can-i delete secrets --as jane -n red
no
root@cks-master:~# 
```

### Cluster role and cluster role binding

- create a clusterrole 'deploy-deleter' which allows to delete deployments
- user jane can delete deployments in all namespaces
- user jim can delete deployments only in namespace red
- test it using auth can-i

```bash
root@cks-master:~# k create clusterrole deploy-deleter --verb=delete --resource=deployments -oyaml --dry-run=client
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  creationTimestamp: null
  name: deploy-deleter
rules:
- apiGroups:
  - apps
  resources:
  - deployments
  verbs:
  - delete
root@cks-master:~# k create clusterrole deploy-deleter --verb=delete --resource=deployments
clusterrole.rbac.authorization.k8s.io/deploy-deleter created
root@cks-master:~# k create clusterrolebinding deploy-deleter --clusterrole=deploy-deleter --user=janeclusterrolebinding.rbac.authorization.k8s.io/deploy-deleter created
root@cks-master:~# k auth can-i delete deployments --as jane
yes
root@cks-master:~# k auth can-i delete pods --as jane
no
root@cks-master:~# k create rolebinding deploy-deleter -n red --clusterrole=deploy-deleter --user=jim
rolebinding.rbac.authorization.k8s.io/deploy-deleter created
root@cks-master:~# k auth can-i delete deployments --as jim
no
root@cks-master:~# k auth can-i delete deployments --as jim -n red
yes
root@cks-master:~# 
```

# Accounts
- serviceaccounts
  - used by machines
  - managed by k8s api
  - ServiceAccount resource
- norma user accounts
  - no support by k8s
  - cluster-independent service manages normal users. 
  - User is someone with cert and key.
    - cert signe dby cluster CA
    - username under common name /CN=jane.
  - using 'openssl' create a csr and then get that cert signed by API::Resource::CertificateSigningRequest CA and then creates a CRT.
- There is no way to invalidate a certificate, once a cert created, its valid till expiry.
- If a certificate has been leaked
  - remove all access via RBAC
  - username cannot be used until cert expired

## Steps to create a certificate and key
- create key
- create CSR
- send to API
- sign 
- download CRT from API
- use CRT+Key to auth
  - create the username as given at CN or FQDN
  - create the context for above created username

```bash
root@cks-master:~# openssl genrsa -out raja.key 2048
Generating RSA private key, 2048 bit long modulus (2 primes)
.........................................+++++
.....+++++
e is 65537 (0x010001)
root@cks-master:~# openssl req -new -key raja.key -out raja.csr
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
root@cks-master:~# vim raja
raja-csr.yaml  raja.csr       raja.key       
root@cks-master:~# vim raja
raja-csr.yaml  raja.csr       raja.key       
root@cks-master:~# vim raja-csr.yaml 
root@cks-master:~# kubectl create -f raja-csr.yaml 
certificatesigningrequest.certificates.k8s.io/raja created
root@cks-master:~# kubectl get csr
NAME   AGE   SIGNERNAME                            REQUESTOR          REQUESTEDDURATION   CONDITION
raja   4s    kubernetes.io/kube-apiserver-client   kubernetes-admin   <none>              Pending
root@cks-master:~# kubectl certificate approve raja
certificatesigningrequest.certificates.k8s.io/raja approved

root@cks-master:~# k get csr
NAME   AGE     SIGNERNAME                            REQUESTOR          REQUESTEDDURATION   CONDITION
raja   2m52s   kubernetes.io/kube-apiserver-client   kubernetes-admin   <none>              Approved,Issued
root@cks-master:~# 

root@cks-master:~# kubectl get csr/raja -o yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  creationTimestamp: "2022-10-26T12:36:55Z"
  name: raja
  resourceVersion: "33321"
  uid: 75cced1c-1203-456f-8cb2-a57f69e002ef
spec:
  groups:
  - system:masters
  - system:authenticated
  request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJQ21UQ0NBWUVDQVFBd1ZERUxNQWtHQTFVRUJoTUNRVlV4RXpBUkJnTlZCQWdNQ2xOdmJXVXRVM1JoZEdVeApJVEFmQmdOVkJBb01HRWx1ZEdWeWJtVjBJRmRwWkdkcGRITWdVSFI1SUV4MFpERU5NQXNHQTFVRUF3d0VjbUZxCllUQ0NBU0l3RFFZSktvWklodmNOQVFFQkJRQURnZ0VQQURDQ0FRb0NnZ0VCQUxkN01qRGhnMTN2WkE2cDdkYWsKb0pkQmlLWGxpcGF5QURueXF6c2ZKTkpUc2szWUFjY3RaeUVBRjV0c0RBZUMyZkw2NThkRjluMUZlQjA4cWFKYwpQK1VQTm5yU1BUNUNoZk92VFhkQ2FKcUVkdFUvb3JweDZsZm1hcGNRQnNmY1pKaEN2aXoxV0MzYXJ0cnlYR3FTCld3MlgxSHlxbHBZa3BVWXBMNFZNV1hiNi9VV0JMVW16SkdYeE5oOG1IeUJvV3BhVU5LN0dERDY0Zlo3Z1M1RG0KQUIrei9namlPT0ZZSkpmKzNLT0RmM2RtSkdqenlIM1ZTcWN1R2NRUTNYYS85b2w2TTk4eWxpOVU1SnhUZmJlYwpoMkc5Y2k2N1JnOWhJMlRtdmd4ODE0YXZ5blh0b1FJUnlRQzBxUEpVRkV4Sk5WTjgrVUM4RG5zbHgyZXdLMk0xCitRTUNBd0VBQWFBQU1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQjhhRG5RR3V4V3cvT1ZwMWdRZWtaaDdRSk8KeEFyY0ZUeTlPZ3hWNmgwRFdIOWZlQlB5eUcwV204OHVqeDBaM1I2L2dqV3QxVU5qd2JnLzhqOUZiK3ZrWnR6aApUb25LMWJEV1MxS21WelRCTFRHYytLVldjd0ZWV1VUL25xLzdwbkczbXRwcE1GOWphZnBKVnJvQm0wOHJTWkplCmE1KzZ0Y2E3clVDMGQ3eUJ3STYydTU1MFhRQ2dHSjErRFJDMVVIaW9FeTFwTFBFYVlZbW9aM0lzYkFIcVZNOEQKZnVUcUIrUlFpeTRoUlFYQUV5a2VIazlnRzhEaDZkSXQ0bFczSGRUWjVPWlpRUThyemVCWDFRN0c2RzdXcmVMeApCMGQ2bVllUWFGTHVNWHQ3YWJzZmVZM3cwcUY5LzVGYmVoQ0RKZW9qOVM3dDNlM2tiMkhsTHo4d3pJS3UKLS0tLS1FTkQgQ0VSVElGSUNBVEUgUkVRVUVTVC0tLS0tCg==
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
  username: kubernetes-admin
status:
  certificate: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURPVENDQWlHZ0F3SUJBZ0lRTkNsZStvZzh3RjRaRzNMbXRqZ0daakFOQmdrcWhraUc5dzBCQVFzRkFEQVYKTVJNd0VRWURWUVFERXdwcmRXSmxjbTVsZEdWek1CNFhEVEl5TVRBeU5qRXlNekl4TWxvWERUSXpNVEF5TmpFeQpNekl4TWxvd1ZERUxNQWtHQTFVRUJoTUNRVlV4RXpBUkJnTlZCQWdUQ2xOdmJXVXRVM1JoZEdVeElUQWZCZ05WCkJBb1RHRWx1ZEdWeWJtVjBJRmRwWkdkcGRITWdVSFI1SUV4MFpERU5NQXNHQTFVRUF4TUVjbUZxWVRDQ0FTSXcKRFFZSktvWklodmNOQVFFQkJRQURnZ0VQQURDQ0FRb0NnZ0VCQUxkN01qRGhnMTN2WkE2cDdkYWtvSmRCaUtYbAppcGF5QURueXF6c2ZKTkpUc2szWUFjY3RaeUVBRjV0c0RBZUMyZkw2NThkRjluMUZlQjA4cWFKY1ArVVBObnJTClBUNUNoZk92VFhkQ2FKcUVkdFUvb3JweDZsZm1hcGNRQnNmY1pKaEN2aXoxV0MzYXJ0cnlYR3FTV3cyWDFIeXEKbHBZa3BVWXBMNFZNV1hiNi9VV0JMVW16SkdYeE5oOG1IeUJvV3BhVU5LN0dERDY0Zlo3Z1M1RG1BQit6L2dqaQpPT0ZZSkpmKzNLT0RmM2RtSkdqenlIM1ZTcWN1R2NRUTNYYS85b2w2TTk4eWxpOVU1SnhUZmJlY2gyRzljaTY3ClJnOWhJMlRtdmd4ODE0YXZ5blh0b1FJUnlRQzBxUEpVRkV4Sk5WTjgrVUM4RG5zbHgyZXdLMk0xK1FNQ0F3RUEKQWFOR01FUXdFd1lEVlIwbEJBd3dDZ1lJS3dZQkJRVUhBd0l3REFZRFZSMFRBUUgvQkFJd0FEQWZCZ05WSFNNRQpHREFXZ0JUMitvRmVnTE9xOXpVa0Q1MCtOS0ltbVk5WGNUQU5CZ2txaGtpRzl3MEJBUXNGQUFPQ0FRRUFvaTcrClNidkRXN1ppRFBqQ2I0UVBUc081VXY3VnRhdmxMTCtKc1VWeHFYZmN0OG4vZjRwUmlEYklJZG5kRFF2SWRELzkKTGhsOGdLUVFsTE1wY0RqcDdha0huR3lzdGlCOUk5YWRZS1hrNUFyVzRWenR5d095cjVtdHVGYkNkYmtWSkh6ZApOeDN5SjN4emoyY1dtMUs4RnNyODRYMUEra1FPaWRxWGo5aWpQWGlGNTB1VnpwcGpJLzQ5bmFKK2V5dmxEY2dDCnBQYy9RVjJkWG5Xa2lBQVk3bmxLNnVlRW10bTR4V05ud0dGVUIxamMvS0YrSzBIU0RFeFJGRzRLNTUrWUh1UDUKdWxpUHN6Y1hDMWlYZkdlZ0s0WXgxbGYxZmFueFdiQ2FXTHRCcFFpZDdnYWZMWlRzVXRIS2duWWlISjlRQWNkQQpIeFlZeHdKSHJZeHl6d0FiZHc9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
  conditions:
  - lastTransitionTime: "2022-10-26T12:37:12Z"
    lastUpdateTime: "2022-10-26T12:37:12Z"
    message: This CSR was approved by kubectl certificate approve.
    reason: KubectlApprove
    status: "True"
    type: Approved

root@cks-master:~# kubectl get csr raja -o jsonpath='{.status.certificate}'| base64 -d > raja.crt
root@cks-master:~# ls
myuser.crt  raja-csr.yaml  raja.crt  raja.csr  raja.key
root@cks-master:~# cat raja-csr.yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: raja
spec:
  request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJQ21UQ0NBWUVDQVFBd1ZERUxNQWtHQTFVRUJoTUNRVlV4RXpBUkJnTlZCQWdNQ2xOdmJXVXRVM1JoZEdVeApJVEFmQmdOVkJBb01HRWx1ZEdWeWJtVjBJRmRwWkdkcGRITWdVSFI1SUV4MFpERU5NQXNHQTFVRUF3d0VjbUZxCllUQ0NBU0l3RFFZSktvWklodmNOQVFFQkJRQURnZ0VQQURDQ0FRb0NnZ0VCQUxkN01qRGhnMTN2WkE2cDdkYWsKb0pkQmlLWGxpcGF5QURueXF6c2ZKTkpUc2szWUFjY3RaeUVBRjV0c0RBZUMyZkw2NThkRjluMUZlQjA4cWFKYwpQK1VQTm5yU1BUNUNoZk92VFhkQ2FKcUVkdFUvb3JweDZsZm1hcGNRQnNmY1pKaEN2aXoxV0MzYXJ0cnlYR3FTCld3MlgxSHlxbHBZa3BVWXBMNFZNV1hiNi9VV0JMVW16SkdYeE5oOG1IeUJvV3BhVU5LN0dERDY0Zlo3Z1M1RG0KQUIrei9namlPT0ZZSkpmKzNLT0RmM2RtSkdqenlIM1ZTcWN1R2NRUTNYYS85b2w2TTk4eWxpOVU1SnhUZmJlYwpoMkc5Y2k2N1JnOWhJMlRtdmd4ODE0YXZ5blh0b1FJUnlRQzBxUEpVRkV4Sk5WTjgrVUM4RG5zbHgyZXdLMk0xCitRTUNBd0VBQWFBQU1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQjhhRG5RR3V4V3cvT1ZwMWdRZWtaaDdRSk8KeEFyY0ZUeTlPZ3hWNmgwRFdIOWZlQlB5eUcwV204OHVqeDBaM1I2L2dqV3QxVU5qd2JnLzhqOUZiK3ZrWnR6aApUb25LMWJEV1MxS21WelRCTFRHYytLVldjd0ZWV1VUL25xLzdwbkczbXRwcE1GOWphZnBKVnJvQm0wOHJTWkplCmE1KzZ0Y2E3clVDMGQ3eUJ3STYydTU1MFhRQ2dHSjErRFJDMVVIaW9FeTFwTFBFYVlZbW9aM0lzYkFIcVZNOEQKZnVUcUIrUlFpeTRoUlFYQUV5a2VIazlnRzhEaDZkSXQ0bFczSGRUWjVPWlpRUThyemVCWDFRN0c2RzdXcmVMeApCMGQ2bVllUWFGTHVNWHQ3YWJzZmVZM3cwcUY5LzVGYmVoQ0RKZW9qOVM3dDNlM2tiMkhsTHo4d3pJS3UKLS0tLS1FTkQgQ0VSVElGSUNBVEUgUkVRVUVTVC0tLS0tCg==
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
root@cks-master:~# 

root@cks-master:~# k config view
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://192.168.56.10:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: jane
  name: jean-context
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: jane
  user:
    client-certificate: /home/jane/.certs/jane.crt
    client-key: /home/jane/.certs/jane.key
- name: kubernetes-admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
root@cks-master:~# k config set-credentials raja --client-key=raja.key --client-certificate=raja.crt
User "raja" set.
root@cks-master:~# k config view
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://192.168.56.10:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: jane
  name: jean-context
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: jane
  user:
    client-certificate: /home/jane/.certs/jane.crt
    client-key: /home/jane/.certs/jane.key
- name: kubernetes-admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
- name: raja
  user:
    client-certificate: /root/raja.crt
    client-key: /root/raja.key
root@cks-master:~# k config set-credentials raja --client-key=raja.key --client-certificate=raja.crt --embed-certs
User "raja" set.
root@cks-master:~# k config view
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://192.168.56.10:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: jane
  name: jean-context
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: jane
  user:
    client-certificate: /home/jane/.certs/jane.crt
    client-key: /home/jane/.certs/jane.key
- name: kubernetes-admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
- name: raja
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
root@cks-master:~# k config view --raw
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMvakNDQWVhZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeU1UQXhNREF5TXpBME5Gb1hEVE15TVRBd056QXlNekEwTkZvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTXJvCnJGWUNvVzdLaXhtcml6dzlvaEM0ekxWanpIZ2pQNmQwbm5HcXp5OFp1UU1BUDdPNm8xYWhXcGM5elI3K2Jha3YKZkdyUEtuRzBNejNJWlo1TE1iQklaT3RQeHN4Zmlrd0RiSjltL2pMUnkzOXBCUHNUN1hkQ3UzWVBSNHo3WmxLWgpjY1FkdXZ4dkgzZUR5VjZZdVNQeXJERDdKb3YrakpKZ0VEZnBjMnhEeC9BQ3Z0SnJRaTE4ZnNjR2VHRGZ6aVVaCkNpZTBKK3pMTjhzRnBQazI5elJhVlN3dk44Z2dwaHluSlBxMkJNWVU0a3ZUcXlBcGVJbTJrZkJjMUMrZWduRVAKK2VMTy9vYXNHKzgxcFQyaUN4ejVOdFJ4WE5uSWIvWmY5Zy9GQkltU25ScTEzcEthTWs2VDVTaXpYVVZiZDRlaQpBb25RSGVYOE9rdjhKam9yVno4Q0F3RUFBYU5aTUZjd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZQYjZnVjZBczZyM05TUVBuVDQwb2lhWmoxZHhNQlVHQTFVZEVRUU8KTUF5Q0NtdDFZbVZ5Ym1WMFpYTXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBSnpnczI3eTZWODFxWnIwYkZEbQpmMFJ3YXdZY2tCeU5PTlIwekVaUkludmg2dENlZW9ObFVSWGcrT2dDdkF4cXZjQjJWN1JCWkc2RVNEQkw3SytnCjJndUxuSE5UZm1sSThjNEErRnNoRGZtR3JPY3RWZGhVa3BhTlkxU0RDbXgzV3JlaDBVRkkvemc2SHh4MVRwYUIKWVdZbHY0N3RpNEpIbU5KajRUSlhmZkplcTJBZ1lxV21OaWY4N2k2ZytIUVNOeWRpUlJOMGp5bVA3Y1o3RytGNApzazdrdkJRMXRJZXh3OWt2U1FiWXIxVldMbTNieTZudkw5TzErcnlzRWRZM3BTVy9XdmVaQXpmRmVCbkZ6alBHCjk5U1JuZm9BbmR2dFZ0a1QwZ0VRT1pkNEc2N28xRDRaYmROd1VycTVGWXpGUTI1UDFWRnpxR3ZGUmdxa0ZJQkUKaWZRPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    server: https://192.168.56.10:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: jane
  name: jean-context
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: jane
  user:
    client-certificate: /home/jane/.certs/jane.crt
    client-key: /home/jane/.certs/jane.key
- name: kubernetes-admin
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURJVENDQWdtZ0F3SUJBZ0lJVnZwN1F5Y2s0cTh3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TWpFd01UQXdNak13TkRSYUZ3MHlNekV3TVRBd01qTXdORFZhTURReApGekFWQmdOVkJBb1REbk41YzNSbGJUcHRZWE4wWlhKek1Sa3dGd1lEVlFRREV4QnJkV0psY201bGRHVnpMV0ZrCmJXbHVNSUlCSWpBTkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQTRDWFJQMWUxY0hCQmhmWDUKTmRMSFNhS1cxOUhkbEkrUW9YTGk4cW5OK0l2T1EyeU1ab0hDZXVrdm1RZkoxckxoaUxjMXBPWS9VR2hqY094cAovU3RJalhnL0dpc0cxN0NQUmw1Y3plMnVESGZnOWJaQnVjN3pUVk9tN3hMRGNoc3Z0RGdCQm93VkRRRllMUC83CmR3QVROZWx0L25DNHdVMXVFL05RcmxJNlIrUFUrU01Kczd1SlBTWXg4eG9ma204UkwxalV0L3RYMGUrZHlSUGgKTWRGNk9LazVtRTFaTEFXeTR1b1kvQWNmUWE1blQwa0dFMGM2ZE5pZjFjeGJMQlhqSFdZdU5jd3FpcytFeXdYbgpZWVByZGVKMWdkejRnZWZrSDZOMVU1MHV2OG5Sdm15bVZoMWtVSjdORWxxditmbWFkeDRZcjZVdTZrT083bWtQCnZYQ3B1d0lEQVFBQm8xWXdWREFPQmdOVkhROEJBZjhFQkFNQ0JhQXdFd1lEVlIwbEJBd3dDZ1lJS3dZQkJRVUgKQXdJd0RBWURWUjBUQVFIL0JBSXdBREFmQmdOVkhTTUVHREFXZ0JUMitvRmVnTE9xOXpVa0Q1MCtOS0ltbVk5WApjVEFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBTFEyNjNJV1dLdDBwY0M4RE9QMWpRRjJzSjI3b2IxUk11TFdUCm9pV2lObDl1RWJJTlFLWFVBMnNoZ2d3a2NwMjJ3bk5xNWxkODBENE5nK291NW9Kbkw3anNXc05nYkVQb0NWdlkKUWdQV0ZrYmp0RGYzUjRESnpmL2p5MGdBUVBiL1JFaW1DL0gwbitXZzB2RHUwUkEwcFo2MVBpMHkxSzBYUmd1UQpxZlh0WGx5REgxTmJTWVdnU2ZiSmlkaXRwL3hFOFY4YkNOS3N5M2JEN0xIdHJidFl2cE9raTZvVjJ2KzVabzA5CllBMndsUG5sWEFld3ZhbWYySmRUYldoRTJCSHloY0h1akI4Z2RTbkpacmhqWGNyU2VmVVhyT1dhRWJ5Rjh1QnIKejhqMkZYSkFua0xBR0hmV1FQT28zY0FCQTZqdXFreUl4anlyTWNzR08wbDhHK09tbGc9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcEFJQkFBS0NBUUVBNENYUlAxZTFjSEJCaGZYNU5kTEhTYUtXMTlIZGxJK1FvWExpOHFuTitJdk9RMnlNClpvSENldWt2bVFmSjFyTGhpTGMxcE9ZL1VHaGpjT3hwL1N0SWpYZy9HaXNHMTdDUFJsNWN6ZTJ1REhmZzliWkIKdWM3elRWT203eExEY2hzdnREZ0JCb3dWRFFGWUxQLzdkd0FUTmVsdC9uQzR3VTF1RS9OUXJsSTZSK1BVK1NNSgpzN3VKUFNZeDh4b2ZrbThSTDFqVXQvdFgwZStkeVJQaE1kRjZPS2s1bUUxWkxBV3k0dW9ZL0FjZlFhNW5UMGtHCkUwYzZkTmlmMWN4YkxCWGpIV1l1TmN3cWlzK0V5d1huWVlQcmRlSjFnZHo0Z2Vma0g2TjFVNTB1djhuUnZteW0KVmgxa1VKN05FbHF2K2ZtYWR4NFlyNlV1NmtPTzdta1B2WENwdXdJREFRQUJBb0lCQUZrdGNwUzY5b3JuZm9vbgpsS0RmWFQ1a201TCtBaVJMQWdYWnlZVTJIYVpYS1JjV0pyM1p2bUJjU2YyZVphVXZ3aDg4bFBFb1VlUlJ3ODUzCm9LdUMvdmlaOExFZWtUaGJISVdvb1UrazBteFBmWWNFbmgyb3dvL3ZTaWt2MCthZi9saTdOMTA5ZWxxVVFGcVcKOVpzZ3dvUGVmVTZQMWxIQjFwdkZZRUlhb09sY2NzL0JKY2doOVlkdjRHMlNWMG5wc3VXcU9kYkRrUzRZODJacAoyWUFiSlFRVFl4SEVuazcyaS81RXNBeEZrekZORWJMbU0zbW5ZRkNRNldiK0VPeDF5cHVHTjEya0JnaDRtRXp5CjNVZWREUGlDazV5S2JzOWJMR0ZrVUZ2QzJTRDZZbHNiWVVjTGEwQ29NRWZIM1FSVFBYTjRaMFVJNVVFODNsWW4KMFVCdDNJRUNnWUVBL0VVNTB5bDFNRHNYVVR2Y21TNGZ3ZnkyYlY0V3gxby94Wks4RlFzM05HYktxUFNXQjAwKworYUx6eUZvN2hKSzFWN1h6anJwV3o0SDlyQVJ0YkUvUDFEZHA0Y3dQak0zd2Y4eDA5d1pDTVJ3cHcyMmdzdEdlCllySzlWc3pBRTdJdERRdUlYQXcxWUUrbkJnTy9uZWFFRURjaGhqUndZQzJ5SStCRU9tUDA4aUVDZ1lFQTQzWW4KcEV1UEFYbU5NMERKTUx3N1k5eU9rMmZTSlZxcHVSTTlpMTdrMTBFNVBCZm9hUHlFWE45RUNHWmNEaFAvN0lKTgpJdjJrSEdkT2pXVXQ2OTdiMEk4NVI4ekU3UEk4bm1ZSjVhRmJBNDh5SlV0cDBNRjlJZDU0R1UyRGRPbEFJVmt4Cjk5VEpzYS9xQ3VHdEc5Qlczc0lVVGl2enVzamcvVGY4MGZnN21Gc0NnWUVBb1BzWC9GMGZVQ2pWSjF4NDJETXIKeHVHYUZFNlBZS1dCdm5WMW1rUXU5VHlISkt2M3RTOGcrYkozdUttRUE0U1BQaXA1QXVKOEZTMFJrSnkrcXZoLwpXaUFHYkRXSTBzUjBMVWx1ZGxoREV3Mnl4T2dIUFRVd3lqRGZUQzJhZ0xjWnNwSmljTUxGcVBFTFYzWTY1K3M2CjZSSVZUWXZYRGpqNnpaUUdWZkNGVmFFQ2dZRUF0MmR1NFZlWFVGNGREeVYrMDlBQ3B5dVF2cVJvMm51Mi9DYmEKYWdVeXlhbXFwNXl6WmV1dUltQlhyOW94QVp6NHIxQUZPR0NCc2ZGT2NrNFI3K3o3R3JoUlBHYU1wbTFQbVh5MwpJRE94ZWpZOC9idEg3KzREb29xS0ZnVGRLU2hsOEQzR1A0bVFzN2dmSTNVQ0tyb2JRWFFHQVY0SklTT1YzamNGCm9KdmlHWjhDZ1lBSTIyM1ZoUFRubm5nbW81bkI4dnAwcDJyMG9mS3cwWCttbjdTODZDcmJpQ05vODVTVWRKbTYKWFRYclV3VnpXYUlobG9iOTZad1FCVDRNOFI1R3o1QmQwVFdBSTh3UWFaU0Y0aUdTSWFjZ1p4K2sxZ2hHZk52dwprUExhWnZ6elExYWttdDYyMWVYTURaWnh4OHNzYktkaHp1VlF0WHJRQk05ZE4rTTIxcWwzdkE9PQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo=
- name: raja
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURPVENDQWlHZ0F3SUJBZ0lRTkNsZStvZzh3RjRaRzNMbXRqZ0daakFOQmdrcWhraUc5dzBCQVFzRkFEQVYKTVJNd0VRWURWUVFERXdwcmRXSmxjbTVsZEdWek1CNFhEVEl5TVRBeU5qRXlNekl4TWxvWERUSXpNVEF5TmpFeQpNekl4TWxvd1ZERUxNQWtHQTFVRUJoTUNRVlV4RXpBUkJnTlZCQWdUQ2xOdmJXVXRVM1JoZEdVeElUQWZCZ05WCkJBb1RHRWx1ZEdWeWJtVjBJRmRwWkdkcGRITWdVSFI1SUV4MFpERU5NQXNHQTFVRUF4TUVjbUZxWVRDQ0FTSXcKRFFZSktvWklodmNOQVFFQkJRQURnZ0VQQURDQ0FRb0NnZ0VCQUxkN01qRGhnMTN2WkE2cDdkYWtvSmRCaUtYbAppcGF5QURueXF6c2ZKTkpUc2szWUFjY3RaeUVBRjV0c0RBZUMyZkw2NThkRjluMUZlQjA4cWFKY1ArVVBObnJTClBUNUNoZk92VFhkQ2FKcUVkdFUvb3JweDZsZm1hcGNRQnNmY1pKaEN2aXoxV0MzYXJ0cnlYR3FTV3cyWDFIeXEKbHBZa3BVWXBMNFZNV1hiNi9VV0JMVW16SkdYeE5oOG1IeUJvV3BhVU5LN0dERDY0Zlo3Z1M1RG1BQit6L2dqaQpPT0ZZSkpmKzNLT0RmM2RtSkdqenlIM1ZTcWN1R2NRUTNYYS85b2w2TTk4eWxpOVU1SnhUZmJlY2gyRzljaTY3ClJnOWhJMlRtdmd4ODE0YXZ5blh0b1FJUnlRQzBxUEpVRkV4Sk5WTjgrVUM4RG5zbHgyZXdLMk0xK1FNQ0F3RUEKQWFOR01FUXdFd1lEVlIwbEJBd3dDZ1lJS3dZQkJRVUhBd0l3REFZRFZSMFRBUUgvQkFJd0FEQWZCZ05WSFNNRQpHREFXZ0JUMitvRmVnTE9xOXpVa0Q1MCtOS0ltbVk5WGNUQU5CZ2txaGtpRzl3MEJBUXNGQUFPQ0FRRUFvaTcrClNidkRXN1ppRFBqQ2I0UVBUc081VXY3VnRhdmxMTCtKc1VWeHFYZmN0OG4vZjRwUmlEYklJZG5kRFF2SWRELzkKTGhsOGdLUVFsTE1wY0RqcDdha0huR3lzdGlCOUk5YWRZS1hrNUFyVzRWenR5d095cjVtdHVGYkNkYmtWSkh6ZApOeDN5SjN4emoyY1dtMUs4RnNyODRYMUEra1FPaWRxWGo5aWpQWGlGNTB1VnpwcGpJLzQ5bmFKK2V5dmxEY2dDCnBQYy9RVjJkWG5Xa2lBQVk3bmxLNnVlRW10bTR4V05ud0dGVUIxamMvS0YrSzBIU0RFeFJGRzRLNTUrWUh1UDUKdWxpUHN6Y1hDMWlYZkdlZ0s0WXgxbGYxZmFueFdiQ2FXTHRCcFFpZDdnYWZMWlRzVXRIS2duWWlISjlRQWNkQQpIeFlZeHdKSHJZeHl6d0FiZHc9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcEFJQkFBS0NBUUVBdDNzeU1PR0RYZTlrRHFudDFxU2dsMEdJcGVXS2xySUFPZktyT3g4azBsT3lUZGdCCnh5MW5JUUFYbTJ3TUI0TFo4dnJueDBYMmZVVjRIVHlwb2x3LzVRODJldEk5UGtLRjg2OU5kMEpvbW9SMjFUK2kKdW5IcVYrWnFseEFHeDl4a21FSytMUFZZTGRxdTJ2SmNhcEpiRFpmVWZLcVdsaVNsUmlrdmhVeFpkdnI5UllFdApTYk1rWmZFMkh5WWZJR2hhbHBRMHJzWU1Qcmg5bnVCTGtPWUFIN1ArQ09JNDRWZ2tsLzdjbzROL2QyWWthUFBJCmZkVktweTRaeEJEZGRyLzJpWG96M3pLV0wxVGtuRk45dDV5SFliMXlMcnRHRDJFalpPYStESHpYaHEvS2RlMmgKQWhISkFMU284bFFVVEVrMVUzejVRTHdPZXlYSFo3QXJZelg1QXdJREFRQUJBb0lCQUNKMkJBNUVQTjBtdWo4NgowVTN3SzYxZEJLSk1BNFNjT0FpcU9GanBWNHdkWmk3U3REckpuMFlHYzJpZ21YM0xxTTNITEVNME04Q0JqTGJKCkR2OU1uaitTWk9RYW1xQVg5SHE1WVM1V0RibC95YVh4eHNtSDNjRFdxUXhvV1MydWlrSkN2dDlJMFdBRFk3WUIKc1RQZSt6VUpZRUp0ODh5TlkzRlRDUGJiU1M1Y1VqUnp3Z004R1ZJTnZaai9ZUEw4RmhoVzVzdTRvMCsxSElLRgpPdUhJRFJHNjIwMmN6QlhxcldXdFRiNVU2d2lnYjBUMU9MQUQvR01hd1hwN2pSSGljTC95RXFwZEt4bjhHVGR5Ckt5KzA1UWRnTnVKTnRHeDRMUUNuN0x0RnBsSE8za0QrWXYvVGhTRE5MdnVZSU9HQkNrb3luK00razAza1NFZzgKUW5CSkdERUNnWUVBNDdxN2lCTlZSRXIzNCt2QmgzUHFmVmc0T2V2LzR6cnREZjgxbFpIaDRtR2tqZFBoM29ORApIYlRRMEFsVWlOUko3eFVweDlPaFFTdUZ3bFBEc24rYW94RzNBV2VjK0NJZjlKMFFEMW1lWTlFZ01tQkFlWkJSCklndFJUT2tqakV6M3diOVRUQWRmRDM0M3lJVEF1SVRUUDE3VDl2Zm41MjB0Z3FoYkROTnYzWHNDZ1lFQXprSkEKUFJsS0FJRlJqWFdIeUkvVTRXcERkTVM5cHpxN3ovZDdBMkp1VUJQZm41M0IvSmlpQWpOWFBhditUMDYrbnRPSwpLU2M1djREZjlxbGV0YTE0SzljS2RWMVIvbnpkcjhNaEJMZUwzRTVZOGFNLzU3ZU93Z3VDcDBxYmF5UDdOYWtDCk1qNFh6WWdEZHJKYUFsWGl2TXhsdjBHRTRYbnJQdG5SVDB6Z2lCa0NnWUVBdHVNSUtFZ2VlaklhMHBoTFhCVGoKaExhTXNUZXUwVFpKbXF3U3hJUGIvSXFlTktpdEJKNDJFRzFlSlRUWkJ1bzJWaU9RNGtJN2hyTUZRUU0wYnUyNwpxcXBYWm5GbnhuN2hXdm1vSkN1ODREemF0cHBHTFZxUlRkMzQ5T05uQVEzdkMxSXoreU1RWE1qbzA4aUpYYWFPCllKNHZiRys3ZGtoZi9FWm9tT3hWTW5FQ2dZQXFaOUNSUHp2SnNzeXppckJwK2JoSXgvSXFkYkNRU3pFRjV0bXgKcm5FRG9iSmVQSzcvWWRvZEhiVVlCdDU0SzdaaExSakFzVUhjTDREY1U2SVhOQno2MW5GZUE5dXh1TFpUUm9qcApVVnM5NWhXL1NGTUJMdW40MXlqN2dBbElFOU80Q3BGYkJ3MFp3cGNEdGxOdkczMU1WN0dyaXFycE9JbTNHRTFDClFvbi9NUUtCZ1FEVFRzdjNWT0xIRlRPZmQyTUhYQm5aNVM1RlhDRFkzNWZnZEltWVJZRmlnZUloWmVlRDNDYTQKMkx4L1pPUEhzcXVPNUYrWEtSVGpSMTlML3BSWXRZUC9tQVo1L2IzcjFidkd3NWRmZ2daMFdzZzNTRXQxNTkzcgpJV1EzRDZBZkhLbmFhUXNqWkhaOUZJcE0rUXRGOGhDNk81cmlpN1VZTXZsOTBrRks5TnkvK2c9PQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo=
root@cks-master:~# k config set-context raja --user raja --cluster kubernetes
Context "raja" created.
root@cks-master:~# k config get-contexts
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
          jean-context                  kubernetes   jane               
*         kubernetes-admin@kubernetes   kubernetes   kubernetes-admin   
          raja                          kubernetes   raja               
root@cks-master:~# k get pods
NAME    READY   STATUS    RESTARTS       AGE
nginx   1/1     Running   2 (6h3m ago)   16d
root@cks-master:~# k config use-context raja
Switched to context "raja".
root@cks-master:~# k get pods
Error from server (Forbidden): pods is forbidden: User "raja" cannot list resource "pods" in API group "" in the namespace "default"
root@cks-master:~# k create role viewpods --verb get --resource pods
Error from server (Forbidden): roles.rbac.authorization.k8s.io is forbidden: User "raja" cannot create resource "roles" in API group "rbac.authorization.k8s.io" in the namespace "default"
root@cks-master:~# k config use-context kubernetes-admin@kubernetes
Switched to context "kubernetes-admin@kubernetes".
root@cks-master:~# k create role viewpods --verb get --resource pods
role.rbac.authorization.k8s.io/viewpods created
root@cks-master:~# k create rolebinding viewpods --user raja --role viewpods
rolebinding.rbac.authorization.k8s.io/viewpods created
root@cks-master:~# k config use-context raja
Switched to context "raja".
root@cks-master:~# k get pods
Error from server (Forbidden): pods is forbidden: User "raja" cannot list resource "pods" in API group "" in the namespace "default"
root@cks-master:~# 

root@cks-master:~# k config use-context kubernetes-admin@kubernetes
Switched to context "kubernetes-admin@kubernetes".
root@cks-master:~# k get roles
NAME       CREATED AT
viewpods   2022-10-26T12:44:41Z
root@cks-master:~# k describe role viewpods
Name:         viewpods
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
  pods       []                 []              [get]
root@cks-master:~# k delete role viewpods
role.rbac.authorization.k8s.io "viewpods" deleted
root@cks-master:~# k get role
No resources found in default namespace.
root@cks-master:~# k get rolebindings
NAME       ROLE            AGE
viewpods   Role/viewpods   2m53s
root@cks-master:~# k create role viewpods --verb list,get,view --resource pods
Warning: 'view' is not a standard resource verb
role.rbac.authorization.k8s.io/viewpods created
root@cks-master:~# k auth can-i list pods --as raja
yes
root@cks-master:~# k config use-context raja
Switched to context "raja".
root@cks-master:~# k get pods
NAME    READY   STATUS    RESTARTS       AGE
nginx   1/1     Running   2 (6h8m ago)   16d
root@cks-master:~# 
```

### For service accounts

```bash
# create Namespaces
k -n ns1 create sa pipeline
k -n ns2 create sa pipeline

# use ClusterRole view
k get clusterrole view # there is default one
k create clusterrolebinding pipeline-view --clusterrole view --serviceaccount ns1:pipeline --serviceaccount ns2:pipeline

# manage Deployments in both Namespaces
k create clusterrole -h # examples
k create clusterrole pipeline-deployment-manager --verb create,delete --resource deployments
# instead of one ClusterRole we could also create the same Role in both Namespaces

k -n ns1 create rolebinding pipeline-deployment-manager --clusterrole pipeline-deployment-manager --serviceaccount ns1:pipeline
k -n ns2 create rolebinding pipeline-deployment-manager --clusterrole pipeline-deployment-manager --serviceaccount ns2:pipeline

# namespace ns1 deployment manager
k auth can-i delete deployments --as system:serviceaccount:ns1:pipeline -n ns1 # YES
k auth can-i create deployments --as system:serviceaccount:ns1:pipeline -n ns1 # YES
k auth can-i update deployments --as system:serviceaccount:ns1:pipeline -n ns1 # NO
k auth can-i update deployments --as system:serviceaccount:ns1:pipeline -n default # NO
```