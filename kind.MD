## https://kind.sigs.k8s.io/


```
# Additional users
useradd -m argo
usermod -aG docker argo
kind export kubeconfig --name argo-cd



root@PF3WJGL6:/mnt/c/Users//kind-resources# kind get clusters
milvus-cluster
rx-dev
root@PF3WJGL6:/mnt/c/Users//kind-resources# kind export kubeconfig --name milvus-cluster
Set kubectl context to "kind-milvus-cluster"

root@:/mnt/c/Users//kind-resources# k config set-context kind-milvus-cluster
Context "kind-milvus-cluster" created.
root@PF3WJGL6:/mnt/c/Users/NiranjanJannapureddy/kind-resources# 


```
## get kubeconfig
```
export KUBECONFIG="$(kind get kubeconfig --name=learn-istio)"
```
