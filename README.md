# kubetnetes


![alt text](https://github.com/jniranjanreddy/kubernetes/blob/main/aws-ingress-controller.png?raw=true)

Kubernetes-SIGs -  Special Interest groups

If unable to delete Namespace, then try below.
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

