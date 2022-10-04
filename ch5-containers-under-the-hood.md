## Container and Image
- Dockerfile: Script/text defines how to build an image.
- by docker build we build docker image
- by docker run we run the image and create a container which instance of the image. 

- container is one or multiple applications, with all required dependencies.
- its just a process which runs on the Linux kernel.

- Process hierarchy 
  - Hardware is the bottom layer
  - on top of it, we have Linux kernel to which syscall interface would make the calls.
  - on top of syscalls we have Applications, libs etc.
  - sometime application may communication with syscall interface directly or they can use libs to make the call.
  - syscall interface is where you perform system operations like Unix i.e getpid(), reboot() etc.
  - so the syscall interface and linux kernel though looks different, they consider it as a single component as Kernel space and accessiable only by kernel.
  - The applications and libraries, they are exposed to user directly, so they named as userspace.

    [images/Kernel_userspace.png](images/Kernel_userspace.png)

## Linux Kernel Namespaces
- namespaces are for isolation
- PID, Mount, network, User namespaces.

## Cgroups
- using C Groups we can achieve maintaining resource usage limits per process.

## Container Tools
- Docker : Container Runtime + Tool for managing containers and images
- Containerd: Container Runtime
- Crictl: CLI for CRI-comptabile contianer runtimes.
- Podman: Tool for managing containers and images.


### Using docker to create an image and to run a container
using ./ch5Dockerfile, create an image
```
docker build -t simple -f ch5Dockerfile
```

```bash
root@cks-master:/vagrant/files# docker build -t simple -f ch5Dockerfile .
Sending build context to Docker daemon  2.048kB
Step 1/2 : FROM bash
latest: Pulling from library/bash
9621f1afde84: Pull complete 
1dd831616e40: Pull complete 
fd6cd28e0879: Pull complete 
Digest: sha256:e8b0bcf7fe88eb07bc18e448e329673ba1e3833dead555d1b56c69466706de19
Status: Downloaded newer image for bash:latest
 ---> 8b332999f684
Step 2/2 : CMD ["ping", "killer.sh"]
 ---> Running in 649d3dc32945
Removing intermediate container 649d3dc32945
 ---> 409fa2091b45
Successfully built 409fa2091b45
Successfully tagged simple:latest
root@cks-master:/vagrant/files# docker image ls | grep simple
simple       latest    409fa2091b45   8 seconds ago   13.3MB

root@cks-master:/vagrant/files# docker run simple
PING killer.sh (35.227.196.29): 56 data bytes
64 bytes from 35.227.196.29: seq=0 ttl=61 time=14.859 ms
64 bytes from 35.227.196.29: seq=1 ttl=61 time=16.776 ms
64 bytes from 35.227.196.29: seq=2 ttl=61 time=16.471 ms
64 bytes from 35.227.196.29: seq=3 ttl=61 time=15.860 ms
64 bytes from 35.227.196.29: seq=4 ttl=61 time=14.246 ms
64 bytes from 35.227.196.29: seq=5 ttl=61 time=14.835 ms
64 bytes from 35.227.196.29: seq=6 ttl=61 time=14.874 ms
64 bytes from 35.227.196.29: seq=7 ttl=61 time=17.626 ms
64 bytes from 35.227.196.29: seq=8 ttl=61 time=15.123 ms
64 bytes from 35.227.196.29: seq=9 ttl=61 time=15.194 ms
64 bytes from 35.227.196.29: seq=10 ttl=61 time=15.140 ms
^C
--- killer.sh ping statistics ---
11 packets transmitted, 11 packets received, 0% packet loss
round-trip min/avg/max = 14.246/15.545/17.626 ms
root@cks-master:/vagrant/files# 
```

### Using podman to create an image and run container.
```
podman build -t <tag> -f <file> .
podman image ls
podman run simple
```
To see the running containers we can use crictl

```
root@cks-master:/vagrant/files# crictl ps
CONTAINER           IMAGE               CREATED             STATE               NAME                      ATTEMPT             POD ID              POD
e5730094d9287       a4ca41631cc7a       38 minutes ago      Running             coredns                   1                   cab4198fa16a6       coredns-6d4b75cb6d-gkxhk
c975b1ea05f13       a4ca41631cc7a       38 minutes ago      Running             coredns                   1                   c819a63510bb8       coredns-6d4b75cb6d-cl78v
0fd376a187054       8522d622299ca       38 minutes ago      Running             kube-flannel              1                   551f9e27178cb       canal-jpvfk
6b166110412f7       48d8a30c26b64       38 minutes ago      Running             calico-node               1                   551f9e27178cb       canal-jpvfk
afebaf1adfe54       2ae1ba6417cbc       38 minutes ago      Running             kube-proxy                1                   90ccf43d12869       kube-proxy-wx569
a7f4b58c40990       3a5aa3a515f5d       39 minutes ago      Running             kube-scheduler            1                   edc586cecbaa0       kube-scheduler-cks-master
3d8b820f2b465       d521dd763e2e3       39 minutes ago      Running             kube-apiserver            1                   6b88dc2a2d0ff       kube-apiserver-cks-master
629fc70566132       aebe758cef4cd       39 minutes ago      Running             etcd                      1                   c192e335a054c       etcd-cks-master
f77a9d9802a69       586c112956dfc       39 minutes ago      Running             kube-controller-manager   1                   fb1f045f9da53       kube-controller-manager-cks-master
root@cks-master:/vagrant/files# 
```

Runtime
```
root@cks-master:/vagrant/files# cat /etc/crictl.yaml 
runtime-endpoint: unix:///run/containerd/containerd.sock
root@cks-master:/vagrant/files# 
```

### Docker isolation

To containers created and both were executed with sleep commmands with 1d, 2d. 
two containers created but in different namespace, so they got same PIDs

```
root@cks-master:/vagrant/files# docker run --name c1 -d ubuntu sh -c 'sleep 1d'
Unable to find image 'ubuntu:latest' locally
latest: Pulling from library/ubuntu
2b55860d4c66: Pull complete 
Digest: sha256:20fa2d7bb4de7723f542be5923b06c4d704370f0390e4ae9e1c833c8785644c1
Status: Downloaded newer image for ubuntu:latest
888bc44b24e2d05d159c91f7a48b088f8a6ac75021119300fefa469f7ca3d6af
root@cks-master:/vagrant/files# docker exec c1 ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.5  0.0   2884  1008 ?        Ss   02:21   0:00 sh -c sleep 1d
root         7  0.0  0.0   2784  1048 ?        S    02:21   0:00 sleep 1d
root         8  0.0  0.0   7056  1644 ?        Rs   02:21   0:00 ps aux
root@cks-master:/vagrant/files# docker run --name c2 -d ubuntu sh -c 'sleep 2d'
1b059071548a83a353197632f33f535792f9e233e6742f86a94a1f528689ff8e
root@cks-master:/vagrant/files# docker exec c2 ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  1.2  0.0   2884   936 ?        Ss   02:21   0:00 sh -c sleep 2d
root         7  0.0  0.0   2784  1016 ?        S    02:21   0:00 sleep 2d
root         8  0.0  0.0   7056  1592 ?        Rs   02:21   0:00 ps aux
root@cks-master:/vagrant/files# 
```

### Containers running in same namespace

multiple containers sharing same namespace


```
root@cks-master:/vagrant/files# docker rm c2 --force
c2
root@cks-master:/vagrant/files# docker run --name c2 --pid=container:c1 -d ubuntu sh -c 'sleep 2d'
d03288fd22c6b42f2c6ce66724e96f26690a52799d0880f75e795d2843e83fd0
root@cks-master:/vagrant/files# docker exec c2 ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   2884  1008 ?        Ss   02:21   0:00 sh -c sleep 1d
root         7  0.0  0.0   2784  1048 ?        S    02:21   0:00 sleep 1d
root        14  0.7  0.0   2884   940 ?        Ss   02:24   0:00 sh -c sleep 2d
root        20  0.0  0.0   2784  1016 ?        S    02:24   0:00 sleep 2d
root        21  0.0  0.0   7056  1560 ?        Rs   02:24   0:00 ps aux
root@cks-master:/vagrant/files# docker exec c1 ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   2884  1008 ?        Ss   02:21   0:00 sh -c sleep 1d
root         7  0.0  0.0   2784  1048 ?        S    02:21   0:00 sleep 1d
root        14  0.2  0.0   2884   940 ?        Ss   02:24   0:00 sh -c sleep 2d
root        20  0.0  0.0   2784  1016 ?        S    02:24   0:00 sleep 2d
root        28  0.0  0.0   7056  1584 ?        Rs   02:24   0:00 ps aux
root@cks-master:/vagrant/files# 
```

### Ref
# What have containers done for you lately?
https://www.youtube.com/watch?v=MHv6cWjvQjM
