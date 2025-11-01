## istio
```
     https://www.youtube.com/watch?v=A9cG1QnmrFU
     https://www.youtube.com/watch?v=F-skxSQf4Jw
     https://github.com/marcel-dempers/docker-development-youtube-series/tree/master/kubernetes/servicemesh/istio
     ## https://github.com/marcel-dempers/docker-development-youtube-series/tree/master/kubernetes/servicemesh/istio



## https://imesh.ai/blog/what-are-istio-virtual-services-and-destination-rules/


```
This is where the open-source Istio service mesh comes in. Istio provides 5 traffic management API resources to handle traffic from the edge and also between service subsets:

Virtual services
Destination rules
Gateways
Service entries
Sidecars

Istio uses Envoy proxy as its data plane. Envoy proxy runs as a sidecar container with each application pod and intercepts the traffic going in and out of the pod.


```

```
<img width="802" height="267" alt="image" src="https://github.com/user-attachments/assets/5f60d689-e54e-4bd8-8caa-d36bca2a1a60" />

<img width="910" height="311" alt="image" src="https://github.com/user-attachments/assets/e44f26a5-21a4-4bb0-b276-09c57bf636c7" />


```
curl -L https://istio.io/downloadIstio | sh -
cd istio-1.*
export PATH=$PWD/bin:$PATH


istioctl install --set profile=demo -y

kubectl label namespace default istio-injection=enabled


kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml

```
