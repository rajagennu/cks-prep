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
