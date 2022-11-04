- if something runs a container, that doesnt mean its secure. 
- though all the containers runs in their own kernel group, they all connected to a single linux kernel.
- if a process running inside the container, can break its kernel group and find access to main Kernel, then 
it can access all the process running inside that kernel which includes other containers as well.
- 

# Sanbox
- Additional security layer to limit attack surface.
- Generally a process issues system calls or sys calls to communicate with kernel.
- containers also issues system calls to interact with kernel. 
- The area/space where containers and process runs is called as User space. 
- And the layer from system calls to Kernel is called Kernel space. 
- So we will place/add sandbox for every container and route all system calls via sandbox.
- Using sandbox we will limit the execution scope of the container.
- Sandbox comes not for free
-   more resources needed
-   better for small, not good for heavy workloads of sys calls
-   no direct access to hardware.

## Practice
- Contact the linux kernel from container.
```
kubectl run nginx --image=nginx
kubectl exec -it nginx -- bash
uname -r # prints the kernel version
# but wait, container will not have kernel
# this is the kernel command
# execute via sys call.
```
```bash
@rajagennu ➜ /workspaces/cks-prep (master ✗) $ kubectl exec -it nginx -- bash
root@nginx:/# uname -r
5.4.0-1094-azure
root@nginx:/# exit
exit
@rajagennu ➜ /workspaces/cks-prep (master ✗) $ uname -r
5.4.0-1094-azure
```

## OCI: Open Container Initiative
- Speification and Runtime.
- Kubelet can be configured with custom runtime using 

```
kubelet --container-runtime {string}
kubelet --container-runtime-endpoint {string}
```

## Sandbox runtime - Katacontainers
- Kata containers will achieve isolation with additional isolation with a lightwight VM and individual kernels
- With kata sandboxes, now from top to bottom the layer looklike
  - Process A in Namespace -> Linux Kernel A -> Hardware Virtualization -> Main Linux kernel.
- Via kata containers, now system calls wont reach to main kernel and they are limited to individual kernel of process A.
- string separation layer.
- runs every container in its private VM
- QEMU as default 


## Sandbox Runtime - gVisor - Google
- user kernel space for containeers
- another layer of separation.
- Not Hypervisor or VM Based
- Simulates kernel syscalls with limited functionality, A kernel simulator written in Go.
- Runs in userspace separated from Linux kernel. 
- Runtime call runsc
- RUntimeClass is used to specific runtime for different k8s runtime.
- 

* Create runtime conf

```yaml
controlplane $ cat rc.yaml 
# RuntimeClass is defined in the node.k8s.io API group
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  # The name the RuntimeClass will be referenced by.
  # RuntimeClass is a non-namespaced resource.
  name: myclass 
# The name of the corresponding CRI configuration
handler: runsc
```

* Create a container that uses the runtime class

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sec
  labels:
    name: sec
spec:
  containers:
    - name: nginx
      image: nginx:1.21.5-alpine
  runtimeClassName: myclass
```


```bash 
controlplane $ kubectl exec -it sec -- dmesg
[   0.000000] Starting gVisor...
[   0.192192] Letting the watchdogs out...
[   0.301818] Accelerating teletypewriter to 9600 baud...
[   0.659960] Checking naughty and nice process list...
[   0.963483] Singleplexing /dev/ptmx...
[   1.455365] Mounting deweydecimalfs...
[   1.860794] Preparing for the zombie uprising...
[   2.159499] Reading process obituaries...
[   2.415334] Constructing home...
[   2.612320] Digging up root...
[   2.987906] Creating bureaucratic processes...
[   3.078068] Ready!
controlplane $ 

controlplane $ kubectl exec -it sec -- uname -r
4.4.0
controlplane $ uname -r
5.4.0-88-generic
controlplane $ 
```
* create the pod.

* Installing gvisor or runsc with containerd for above container to be created.
* Need to install runsc in all the worker node

```
# IF THE INSTALL SCRIPT FAILS then you can try to change the URL= further down in the script from latest to a specific release

bash <(curl -s https://raw.githubusercontent.com/killer-sh/cks-course-environment/master/course-content/microservice-vulnerabilities/container-runtimes/gvisor/install_gvisor.sh)


# Example of Pod+RuntimeClass:
https://github.com/killer-sh/cks-course-environment/blob/master/course-content/microservice-vulnerabilities/container-runtimes/gvisor/example.yaml

```

# Container Runtime Landscape
https://www.youtube.com/watch?v=RyXL1zOa8Bw

# Gvisor
https://www.youtube.com/watch?v=kxUZ4lVFuVo

# Kata Containers
https://www.youtube.com/watch?v=4gmLXyMeYWI

