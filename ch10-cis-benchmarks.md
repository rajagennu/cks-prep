# CIS Benchmarks
- use to review. security benchmarks

- CIS: Center for internet security. provides best practices to secure. 
- Provides default recommendations to secure k8s cluster. 
- You can use CIS benchmarks as a base and you can customize as they suits your arch and you can apply the customized benchmarks. 


### Kube-bench


- how to run
https://github.com/aquasecurity/kube-bench/blob/main/docs/running.md


- run on master
docker run --pid=host -v /etc:/etc:ro -v /var:/var:ro -t aquasec/kube-bench:latest run --targets=master --version 1.22

- run on worker
docker run --pid=host -v /etc:/etc:ro -v /var:/var:ro -t aquasec/kube-bench:latest run --targets=node --version 1.22

- Just be familar with reading instructions and apply the rules. 
