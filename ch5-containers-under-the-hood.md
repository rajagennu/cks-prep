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

