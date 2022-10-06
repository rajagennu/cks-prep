### Build container
```bash
podman build -t <tag_name> -f <Dockerfile> .
```
### Reset Podman

```
podman system reset -f
```
[podmand reset](https://docs.podman.io/en/latest/markdown/podman-system-reset.1.html)


Issue faced

```bash
root@cks-master:~# podman rmi -fa
Untagged: docker.io/library/bash:latest
Deleted: 8b332999f6845d6cfa352e87d85f0f0abb04d08ef16cdae716850c6e31fa7ac2
root@cks-master:~# podman rmi -fa
root@cks-master:~# podman build -t simple -f /vagrant/files/ch5Dockerfile .
STEP 1/2: FROM bash
Resolving "bash" using unqualified-search registries (/etc/containers/registries.conf)
Trying to pull docker.io/library/bash:latest...
Getting image source signatures
Copying blob fd6cd28e0879 done  
Copying blob 1dd831616e40 done  
Copying blob 9621f1afde84 done  
Copying config 8b332999f6 done  
Writing manifest to image destination
Storing signatures
ERRO[0006] error unmounting /var/lib/containers/storage/overlay/0301d0988b79340c341bcec5cdf37bb141dcd2ac2bef52ee9ca07bc68b3eee90/merged: invalid argument 
Error: error mounting new container: error mounting build container "df58813736cb4c01e4986a6c04326058e986657e4059adc7fe293332c01ffa8e": error creating overlay mount to /var/lib/containers/storage/overlay/0301d0988b79340c341bcec5cdf37bb141dcd2ac2bef52ee9ca07bc68b3eee90/merged, mount_data="nodev,metacopy=on,lowerdir=/var/lib/containers/storage/overlay/l/JFMNCXM3ZSIKM6SIW6OHUOMKY3:/var/lib/containers/storage/overlay/l/SYCHCQU6HA4ZWTACQ55SJTDDC5:/var/lib/containers/storage/overlay/l/YUVWA2XCGQB2HDRNUYEZVDE4BT,upperdir=/var/lib/containers/storage/overlay/0301d0988b79340c341bcec5cdf37bb141dcd2ac2bef52ee9ca07bc68b3eee90/diff,workdir=/var/lib/containers/storage/overlay/0301d0988b79340c341bcec5cdf37bb141dcd2ac2bef52ee9ca07bc68b3eee90/work": invalid argument
root@cks-master:~# podman system reset -f
A storage.conf file exists at /etc/containers/storage.conf
You should remove this file if you did not modified the configuration.
root@cks-master:~# rm /etc/containers/storage.conf
root@cks-master:~# podman system reset -f
root@cks-master:~# podman build -t simple -f /vagrant/files/ch5Dockerfile .
STEP 1/2: FROM bash
Resolving "bash" using unqualified-search registries (/etc/containers/registries.conf)
Trying to pull docker.io/library/bash:latest...
Getting image source signatures
Copying blob 9621f1afde84 done  
Copying blob 1dd831616e40 done  
Copying blob fd6cd28e0879 done  
Copying config 8b332999f6 done  
Writing manifest to image destination
Storing signatures
STEP 2/2: CMD ["ping", "killer.sh"]
COMMIT simple
--> cd1407a69ea
Successfully tagged localhost/simple:latest
cd1407a69ea490496d6635700958f2b5fcf2b1d01f8dd218dea0f83187e55872
root@cks-master:~# podman run --name simple simple
PING killer.sh (35.227.196.29): 56 data bytes
64 bytes from 35.227.196.29: seq=0 ttl=42 time=15.689 ms
64 bytes from 35.227.196.29: seq=1 ttl=42 time=14.662 ms
64 bytes from 35.227.196.29: seq=2 ttl=42 time=15.161 ms
^C
--- killer.sh ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 14.662/15.170/15.689 ms
root@cks-master:~# docker build -t simple -f /vagrant/files/ch5Dockerfile .
Sending build context to Docker daemon  3.141MB
Step 1/2 : FROM bash
latest: Pulling from library/bash
9621f1afde84: Pull complete 
1dd831616e40: Pull complete 
fd6cd28e0879: Pull complete 
Digest: sha256:e4624241e953934fc4c396217253d8322ebda53be3b1863cd7795541d168034f
Status: Downloaded newer image for bash:latest
 ---> 8b332999f684
Step 2/2 : CMD ["ping", "killer.sh"]
 ---> Running in 306963a83d1c
Removing intermediate container 306963a83d1c
 ---> 51dee555fd57
Successfully built 51dee555fd57
Successfully tagged simple:latest
root@cks-master:~#
```


### Start a container

```bash
podman run --name simple simple
```


