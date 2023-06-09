## Patching Objects
## Source: https://loft.sh/blog/kubectl-patch-what-you-can-use-it-for-and-how-to-do-it/
```
Kubectl patch supports three patch types:

strategic - a strategic patch will merge the configuration you supply with the existing one based on the node’s type.
JSON merge - this type of patch follows the algorithm specified in RFC 7386.
JSON - with this patch, you specify the operation you want kubectl to perform on each configuration node.
```
## Patching Dployment.
## Strategic patch
```
Strategic patch - kubectl get pods -o jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' |grep nginx
kubectl patch deployment nginx-deployment --patch-file nginx_patch.yaml

kubectl get pods -o jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' |grep nginx
```
## Merge Patch
```
kubectl patch deployment nginx-deployment --type merge --patch-file nginx_merge_patch.yaml
```
## JSON patch
```
kubectl patch deployment nginx-deployment --type JSON --patch-file nginx_json_patch.yaml
deployment.apps/nginx-deployment patched
```
