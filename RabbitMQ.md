## RabbitMQ in kubernetes.
```
Source: https://www.youtube.com/watch?v=GxdyQSUEj5U
```

## Rancher ingress
![image](https://github.com/jniranjanreddy/kubernetes/assets/83489863/0f5b08dd-9f68-4b07-b4ae-6eec8cd6b1b8)
![image](https://github.com/jniranjanreddy/kubernetes/assets/83489863/8eace0ba-5614-4b97-839a-1602b6254ae1)
![image](https://github.com/jniranjanreddy/kubernetes/assets/83489863/797f824a-f47f-4b4c-975e-8f0b1462459d)
![image](https://github.com/jniranjanreddy/kubernetes/assets/83489863/6deb497d-a120-4b25-b9e1-7cab3abfcde6)
![image](https://github.com/jniranjanreddy/kubernetes/assets/83489863/f83ccf94-6db7-479c-81a4-4b6dc85f0dcc)
![image](https://github.com/jniranjanreddy/kubernetes/assets/83489863/8369241e-6049-453e-ad92-1557b2d71ee6)


```
root@uat-clus01:~# k get pods
NAME                    READY   STATUS    RESTARTS   AGE
postgres-postgresql-0   1/1     Running   0          146m
rabbitmq-0              1/1     Running   0          3m35s

root@uat-clus01:~# k get svc
NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                                 AGE
postgres-postgresql   NodePort    10.43.16.235    <none>        5432:32259/TCP                          23h
rabbitmq              ClusterIP   10.43.202.104   <none>        5672/TCP,4369/TCP,25672/TCP,15672/TCP   4m9s
rabbitmq-headless     ClusterIP   None            <none>        4369/TCP,5672/TCP,25672/TCP,15672/TCP   4m9s

root@uat-clus01:~# k get ing
NAME               CLASS   HOSTS                ADDRESS         PORTS     AGE
postgres-ingress   nginx   postgres.rlabs.com   192.168.9.134   80, 443   19d
rabbitmq           nginx   rabbitmq.rlabs.com   192.168.9.134   80, 443   42m
==================================================================================
root@uat-clus01:~# k describe pod rabbitmq-0
Name:             rabbitmq-0
Namespace:        devops
Priority:         0
Service Account:  rabbitmq
Node:             uat-clus01/192.168.9.134
Start Time:       Wed, 17 May 2023 21:59:18 +0530
Labels:           app.kubernetes.io/instance=rabbitmq
                  app.kubernetes.io/managed-by=Helm
                  app.kubernetes.io/name=rabbitmq
                  controller-revision-hash=rabbitmq-d8dbb66d8
                  helm.sh/chart=rabbitmq-11.15.2
                  statefulset.kubernetes.io/pod-name=rabbitmq-0
Annotations:      checksum/config: eab694dbde1557069676eff329c51ba7a2211f7b65a9c75f5d87bc4e02f710ef
                  checksum/secret: ffba4d126b49edaeabbebb78134e05662ac3012d3b2256b48975bcf665e62b1d
                  cni.projectcalico.org/containerID: 542deae5e5f6badac561651091d23c6b56404c45a00ec0a88625a436acf7819d
                  cni.projectcalico.org/podIP: 10.42.0.93/32
                  cni.projectcalico.org/podIPs: 10.42.0.93/32
Status:           Running
IP:               10.42.0.93
IPs:
  IP:           10.42.0.93
Controlled By:  StatefulSet/rabbitmq
Containers:
  rabbitmq:
    Container ID:   docker://9c590abe5c350b0b43cc2df98a5d0afb5f58af5f0396db63d5d3ec75eed364b5
    Image:          docker.io/bitnami/rabbitmq:3.11.16-debian-11-r0
    Image ID:       docker-pullable://bitnami/rabbitmq@sha256:e741e30f1b6b8a11a8a4354e35073bac8084770d4b5c0b86d6a470bf421aba39
    Ports:          5672/TCP, 25672/TCP, 15672/TCP, 4369/TCP
    Host Ports:     0/TCP, 0/TCP, 0/TCP, 0/TCP
    State:          Running
      Started:      Wed, 17 May 2023 21:59:39 +0530
    Ready:          True
    Restart Count:  0
    Liveness:       exec [sh -ec curl -f --user gestaltAdmin:$RABBITMQ_PASSWORD 127.0.0.1:15672/api/health/checks/virtual-hosts] delay=120s timeout=20s period=30s #success=1 #failure=6
    Readiness:      exec [sh -ec curl -f --user gestaltAdmin:$RABBITMQ_PASSWORD 127.0.0.1:15672/api/health/checks/local-alarms] delay=10s timeout=20s period=30s #success=1 #failure=3
    Environment:
      BITNAMI_DEBUG:              false
      MY_POD_IP:                   (v1:status.podIP)
      MY_POD_NAME:                rabbitmq-0 (v1:metadata.name)
      MY_POD_NAMESPACE:           devops (v1:metadata.namespace)
      K8S_SERVICE_NAME:           rabbitmq-headless
      K8S_ADDRESS_TYPE:           hostname
      RABBITMQ_FORCE_BOOT:        no
      RABBITMQ_NODE_NAME:         rabbit@$(MY_POD_NAME).$(K8S_SERVICE_NAME).$(MY_POD_NAMESPACE).svc.cluster.local
      K8S_HOSTNAME_SUFFIX:        .$(K8S_SERVICE_NAME).$(MY_POD_NAMESPACE).svc.cluster.local
      RABBITMQ_MNESIA_DIR:        /bitnami/rabbitmq/mnesia/$(RABBITMQ_NODE_NAME)
      RABBITMQ_LDAP_ENABLE:       no
      RABBITMQ_LOGS:              -
      RABBITMQ_ULIMIT_NOFILES:    65536
      RABBITMQ_USE_LONGNAME:      true
      RABBITMQ_ERL_COOKIE:        <set to the key 'rabbitmq-erlang-cookie' in secret 'rabbitmq'>  Optional: false
      RABBITMQ_LOAD_DEFINITIONS:  no
      RABBITMQ_DEFINITIONS_FILE:  /app/load_definition.json
      RABBITMQ_SECURE_PASSWORD:   yes
      RABBITMQ_USERNAME:          rlabsAdmin
      RABBITMQ_PASSWORD:          <set to the key 'rabbitmq-password' in secret 'rabbitmq'>  Optional: false
      RABBITMQ_PLUGINS:           rabbitmq_management, rabbitmq_peer_discovery_k8s, rabbitmq_auth_backend_ldap
    Mounts:
      /bitnami/rabbitmq/conf from configuration (rw)
      /bitnami/rabbitmq/mnesia from data (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-lvrf5 (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  data:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  data-rabbitmq-0
    ReadOnly:   false
  configuration:
    Type:                Projected (a volume that contains injected data from multiple sources)
    SecretName:          rabbitmq-config
    SecretOptionalName:  <nil>
  kube-api-access-lvrf5:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason                  Age                    From                     Message
  ----     ------                  ----                   ----                     -------
  Warning  FailedScheduling        5m47s (x2 over 5m48s)  default-scheduler        0/1 nodes are available: 1 pod has unbound immediate PersistentVolumeClaims. preemption: 0/1 nodes are available: 1 Preemption is not helpful for scheduling.
  Normal   Scheduled               5m45s                  default-scheduler        Successfully assigned devops/rabbitmq-0 to uat-clus01
  Normal   SuccessfulAttachVolume  5m34s                  attachdetach-controller  AttachVolume.Attach succeeded for volume "pvc-4f6d3da3-2d68-4c6d-927d-fbc601212d26"
  Normal   Pulled                  5m25s                  kubelet                  Container image "docker.io/bitnami/rabbitmq:3.11.16-debian-11-r0" already present on machine
  Normal   Created                 5m24s                  kubelet                  Created container rabbitmq
  Normal   Started                 5m24s                  kubelet                  Started container rabbitmq
  Warning  Unhealthy               4m32s (x2 over 5m1s)   kubelet                  Readiness probe failed:   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
\r  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0\r  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
curl: (7) Failed to connect to 127.0.0.1 port 15672: Connection refused
====================================================================
root@uat-clus01:~# k describe svc rabbitmq
Name:              rabbitmq
Namespace:         devops
Labels:            app.kubernetes.io/instance=rabbitmq
                   app.kubernetes.io/managed-by=Helm
                   app.kubernetes.io/name=rabbitmq
                   helm.sh/chart=rabbitmq-11.15.2
Annotations:       meta.helm.sh/release-name: rabbitmq
                   meta.helm.sh/release-namespace: devops
Selector:          app.kubernetes.io/instance=rabbitmq,app.kubernetes.io/name=rabbitmq
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.43.202.104
IPs:               10.43.202.104
Port:              amqp  5672/TCP
TargetPort:        amqp/TCP
Endpoints:         10.42.0.93:5672
Port:              epmd  4369/TCP
TargetPort:        epmd/TCP
Endpoints:         10.42.0.93:4369
Port:              dist  25672/TCP
TargetPort:        dist/TCP
Endpoints:         10.42.0.93:25672
Port:              http-stats  15672/TCP
TargetPort:        stats/TCP
Endpoints:         10.42.0.93:15672
Session Affinity:  None
Events:            <none>

root@uat-clus01:~# k describe ing rabbitmq
Name:             rabbitmq
Labels:           <none>
Namespace:        devops
Address:          192.168.9.134
Ingress Class:    nginx
Default backend:  rabbitmq:15672 (10.42.0.93:15672)
TLS:
  bar-tls terminates rabbitmq
Rules:
  Host        Path  Backends
  ----        ----  --------
  *           *     rabbitmq:15672 (10.42.0.93:15672)
Annotations:  <none>
Events:
  Type    Reason  Age                From                      Message
  ----    ------  ----               ----                      -------
  Normal  Sync    44m (x2 over 45m)  nginx-ingress-controller  Scheduled for sync


```
