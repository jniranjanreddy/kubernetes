## How to use shell commands


# Podname Container name Image name
```
kubectl get pod -o "custom-columns=PodName:.metadata.name,Containers:.spec.containers[*].name,Image:.spec.containers[*].image" 
PodName                                             Containers      Image
authorization-deployment-5f7655b4b4-kvgwr           authorization   packages.gestaltdiagnostics.com:50000/authorization-rke:v1
hello-deployment-56f678cb7b-vx78n                   hello           packages.gestaltdiagnostics.com:50000/hello:latest
```
## Podname Container name
```
root@engg1-ctrl-1:/deployments/authorization# kubectl get pod -o "custom-columns=PodName:.metadata.name,Containers:.spec.containers[*].name"
PodName                                             Containers
authorization-deployment-5f7655b4b4-kvgwr           authorization
hello-deployment-56f678cb7b-vx78n                   hello
postgres-ha-postgresql-ha-pgpool-7b97bccdcc-fbmxb   pgpool
```
