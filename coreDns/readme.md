## DNS mappings..
![image](https://user-images.githubusercontent.com/83489863/233294910-be058b1a-3501-47a3-967f-4e39f0545c2f.png)

![image](https://user-images.githubusercontent.com/83489863/233295623-877f4270-d91f-4c4d-83e8-d697a5edf523.png)


```
root@minikube02:~/mySpace/kubernetes# kubectl get endpoints kube-dns --namespace=kube-system
NAME       ENDPOINTS                                     AGE
kube-dns   172.17.0.2:53,172.17.0.2:53,172.17.0.2:9153   3h16m






root@minikube02:/etc# kubectl -n kube-system edit configmap coredns

# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
data:
  Corefile: |
    .:53 {
        log
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        hosts {
           127.0.0.1 host.minikube.internal
           fallthrough
        }
        forward . /etc/resolv.conf {
"/tmp/kubectl-edit-1888813516.yaml" 39L, 947C
```
