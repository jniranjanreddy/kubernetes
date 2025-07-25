# kubetnetes 


## Ingress
```
three Types of Ingress paths
1. ImplementationSpecific: With this path type, matching is up to the IngressClass. Implementations can treat this as a separate pathType or treat it identically to Prefix or Exact path types.

2. Exact: Matches the URL path exactly and with case sensitivity.

3. Prefix: Matches based on a URL path prefix split by /. Matching is case sensitive and done on a path element by element basis. 
A path element refers to the list of labels in the path split by the / separator. A request is a match for path p if every p is an 
element-wise prefix of p of the request path.

Note: If the last element of the path is a substring of the last element in request path, it is not a match (
for example: 
/foo/bar matches 
/foo/bar/baz, but does not match /foo/barbaz).

```
## Kind - Kubernetes in Docker - https://www.youtube.com/watch?v=eKr75oClPZ4&t=6s

![alt text](https://github.com/jniranjanreddy/kubernetes/blob/main/aws-ingress-controller.png?raw=true)

Kubernetes-SIGs -  Special Interest groups

If unable to delete Namespace, then try below.
```
![alt text](https://github.com/jniranjanreddy/kubernetes/blob/main/aws-ingress-controller.png?raw=true)
```
```
NAMESPACE=ingress-nginx
kubectl proxy &
kubectl get namespace $NAMESPACE -o json |jq '.spec = {"finalizers":[]}' >temp.json
curl -k -H "Content-Type: application/json" -X PUT --data-binary @temp.json 127.0.0.1:8001/api/v1/namespaces/$NAMESPACE/finalize

```

```
How to access kubernets cluster from jumphost.
I have two minishift running in different VM's and having two files..
/root/.kube/minikube02-config
/root/.kube/minikube03-config
```
```
[root@docswarm01 kubetnetes]# kubectl --kubeconfig=/root/.kube/minikube02-config get pods --all-namespaces
NAMESPACE       NAME                                              READY   STATUS      RESTARTS   AGE
ingress-nginx   ingress-nginx-admission-create-mzg6p              0/1     Completed   0          22d
ingress-nginx   ingress-nginx-admission-patch-rxxqh               0/1     Completed   2          22d
ingress-nginx   ingress-nginx-controller-5d88495688-sb2w9         1/1     Running     2          22d
kube-system     coredns-74ff55c5b-ptrq2                           1/1     Running     2          22d
kube-system     etcd-minikube02.nirulabs.com                      1/1     Running     2          22d
kube-system     kube-apiserver-minikube02.nirulabs.com            1/1     Running     2          22d
kube-system     kube-controller-manager-minikube02.nirulabs.com   1/1     Running     2          22d
kube-system     kube-proxy-9wtwk                                  1/1     Running     2          22d
kube-system     kube-scheduler-minikube02.nirulabs.com            1/1     Running     2          22d
kube-system     metrics-server-7894db45f8-cktfz                   1/1     Running     2          22d
kube-system     storage-provisioner                               1/1     Running     4          22d

```
```
[root@docswarm01 kubetnetes]# kubectl --kubeconfig=/root/.kube/minikube03-config get pods --all-namespaces
NAMESPACE       NAME                                              READY   STATUS      RESTARTS   AGE
ingress-nginx   ingress-nginx-admission-create-mcnzc              0/1     Completed   0          22d
ingress-nginx   ingress-nginx-admission-patch-56g4n               0/1     Completed   2          22d
ingress-nginx   ingress-nginx-controller-5d88495688-nlt8v         1/1     Running     2          22d
kube-system     coredns-74ff55c5b-l7ggr                           1/1     Running     2          22d
kube-system     etcd-minikube03.nirulabs.com                      1/1     Running     2          22d
kube-system     kube-apiserver-minikube03.nirulabs.com            1/1     Running     2          22d
kube-system     kube-controller-manager-minikube03.nirulabs.com   1/1     Running     2          22d
kube-system     kube-proxy-l2wgg                                  1/1     Running     2          22d
kube-system     kube-scheduler-minikube03.nirulabs.com            1/1     Running     2          22d
kube-system     metrics-server-7894db45f8-k6t4n                   1/1     Running     3          22d
kube-system     storage-provisioner                               1/1     Running     4          22d
You have new mail in /var/spool/mail/root
```
```
[root@devkmas01 ~]# k get nodes --show-labels
NAME                     STATUS   ROLES                  AGE   VERSION   LABELS
devkmas01.example.com   Ready    control-plane,master   8d    v1.21.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubern                           etes.io/arch=amd64,kubernetes.io/hostname=devkmas01.example.com,kubernetes.io/os=linux,node-role.kubernetes.io/control-plane=,node-role.                           kubernetes.io/master=,node.kubernetes.io/exclude-from-external-load-balancers=
devkwor01.example.com   Ready    <none>                 8d    v1.21.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubern                           etes.io/arch=amd64,kubernetes.io/hostname=devkwor01.example.com,kubernetes.io/os=linux
devkwor02.example.com   Ready    <none>                 8d    v1.21.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubern                           etes.io/arch=amd64,kubernetes.io/hostname=devkwor02.example.com,kubernetes.io/os=linux
```
```
kubectl create ns dev01 -o yaml --dry-run=client > ns.yml

[root@minikube01 1-assesment]# cat ns.yml
apiVersion: v1
kind: Namespace
metadata:
  creationTimestamp: null
  name: dev01
spec: {}
status: {}

kubectl apply -f ns.yml
```
```
```
![image](https://github.com/jniranjanreddy/kubernetes/assets/83489863/b39e1596-5978-43ed-8fb2-0845117cf672)

## CLoud Native Compute Foundation
![image](https://github.com/jniranjanreddy/kubernetes/assets/83489863/0c99db61-1fe1-4051-9450-1fba43d401af)
![image](https://github.com/jniranjanreddy/kubernetes/assets/83489863/f04ea0a4-af4b-4e4b-be77-3dbe12d5b8fb)
![image](https://github.com/jniranjanreddy/kubernetes/assets/83489863/117eb95f-d15f-46cb-acbd-c115ea993ca8)
![image](https://github.com/jniranjanreddy/kubernetes/assets/83489863/aa4bfa3a-d4d8-4d8a-b3af-4d22ad28f9e8)
![image](https://github.com/jniranjanreddy/kubernetes/assets/83489863/3fe1924b-58fd-47eb-92f0-c907f00b7ac2)
![image](https://github.com/jniranjanreddy/kubernetes/assets/83489863/8ef3235b-d0fb-47c6-bc01-ac59de1d3ec2)




