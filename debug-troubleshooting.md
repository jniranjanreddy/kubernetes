## 
```
If want to troubleshooting anything in the exiting pod, then attach debug tool pods for temporaray

# kubectl get pods
  api-portal-6b8758f87f-9khkb

 
 kubectl debug -it api-portal-6b8758f87f-9khkb --image=nicolaka/netshoot --target=api-portal --profile=netadmin

```
