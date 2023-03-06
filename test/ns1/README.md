## Demo Basic NetworkPolicy

### Setup

Init K8s cluster with `minikube` and cni `Calico`:

```sh
minikube start --nodes 2 -p node --vm-driver="virtualbox" --network-plugin=cni --cni=calico
# minikube start --nodes 2 -p node --vm-driver="virtualbox" --network-plugin=cni --cni=flannel
```

Check pods in ns `kube-system`:

```sh
➜  test git:(main) ✗ kubectl get pods -A -o wide
NAMESPACE     NAME                                     READY   STATUS    RESTARTS      AGE   IP               NODE       NOMINATED NODE   READINESS GATES
kube-system   calico-kube-controllers-c44b4545-s4g4w   1/1     Running   0             29m   10.88.0.3        node       <none>           <none>
kube-system   calico-node-dskfb                        1/1     Running   0             29m   192.168.59.156   node       <none>           <none>
kube-system   calico-node-vnxfg                        1/1     Running   0             28m   192.168.59.157   node-m02   <none>           <none>
kube-system   coredns-6d4b75cb6d-275xr                 1/1     Running   0             29m   10.88.0.2        node       <none>           <none>
kube-system   etcd-node                                1/1     Running   0             29m   192.168.59.156   node       <none>           <none>
kube-system   kube-apiserver-node                      1/1     Running   0             29m   192.168.59.156   node       <none>           <none>
kube-system   kube-controller-manager-node             1/1     Running   0             29m   192.168.59.156   node       <none>           <none>
kube-system   kube-proxy-cwf5m                         1/1     Running   0             28m   192.168.59.157   node-m02   <none>           <none>
kube-system   kube-proxy-qlk54                         1/1     Running   0             29m   192.168.59.156   node       <none>           <none>
kube-system   kube-scheduler-node                      1/1     Running   0             29m   192.168.59.156   node       <none>           <none>
kube-system   storage-provisioner                      1/1     Running   1 (28m ago)   29m   192.168.59.156   node       <none>           <none>
```

Set pods `coredns` using CIDR `10.244.0.0/16`:

Set Master node `label` -> `node-role.kubernetes.io/master=true`:

```sh
kubectl label nodes node node-role.kubernetes.io/master=true
```

Edit `coredns deployment` and add label `node-role.kubernetes.io/master=true` in
`nodeSelector`:

```sh
kubectl edit deployment <coredns> -n kube-system
```

Then, restart `coredns`:

```sh
➜  test git:(master) kubectl -n kube-system rollout restart deployment coredns
deployment.apps/coredns restarted
➜  test git:(master) kubectl get pods -A -o wide
NAMESPACE     NAME                                     READY   STATUS    RESTARTS      AGE   IP               NODE       NOMINATED NODE   READINESS GATES
kube-system   calico-kube-controllers-c44b4545-s4g4w   1/1     Running   0             34m   10.88.0.3        node       <none>           <none>
kube-system   calico-node-dskfb                        1/1     Running   0             34m   192.168.59.156   node       <none>           <none>
kube-system   calico-node-vnxfg                        1/1     Running   0             33m   192.168.59.157   node-m02   <none>           <none>
kube-system   coredns-767fdb8cdb-kndvs                 1/1     Running   0             8s    10.244.167.130   node       <none>           <none>
kube-system   etcd-node                                1/1     Running   0             34m   192.168.59.156   node       <none>           <none>
kube-system   kube-apiserver-node                      1/1     Running   0             34m   192.168.59.156   node       <none>           <none>
kube-system   kube-controller-manager-node             1/1     Running   0             34m   192.168.59.156   node       <none>           <none>
kube-system   kube-proxy-cwf5m                         1/1     Running   0             33m   192.168.59.157   node-m02   <none>           <none>
kube-system   kube-proxy-qlk54                         1/1     Running   0             34m   192.168.59.156   node       <none>           <none>
kube-system   kube-scheduler-node                      1/1     Running   0             34m   192.168.59.156   node       <none>           <none>
kube-system   storage-provisioner                      1/1     Running   1 (33m ago)   34m   192.168.59.156   node       <none>           <none>
```

### Demo

Setup 2 pods [httpbin](httpbin.yaml) and [curl](sleep.yaml):

```sh
# First, creat NS n1
kubectl create ns n1

# Apply pods
kubectl apply -f httpbin.yaml
kubectl apply -f sleep.yaml
```

Check result:

```sh
# Get info
➜  ns1 git:(master) kubectl get pods,svc -n n1
NAME                           READY   STATUS    RESTARTS   AGE
pod/httpbin-847f64cc8d-rrc9c   1/1     Running   0          2m41s
pod/sleep-8494d75958-d99p7     1/1     Running   0          66s

NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/httpbin   ClusterIP   10.96.8.24      <none>        8000/TCP   2m41s
service/sleep     ClusterIP   10.110.20.175   <none>        80/TCP     66s

# Describe services
➜  ns1 git:(master) kubectl describe svc -n n1
Name:              httpbin
Namespace:         n1
Labels:            app=httpbin
                   service=httpbin
Annotations:       <none>
Selector:          app=httpbin
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.96.8.24
IPs:               10.96.8.24
Port:              http  8000/TCP
TargetPort:        80/TCP
Endpoints:         10.244.197.65:80
Session Affinity:  None
Events:            <none>


Name:              sleep
Namespace:         n1
Labels:            app=sleep
                   service=sleep
Annotations:       <none>
Selector:          app=sleep
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.110.20.175
IPs:               10.110.20.175
Port:              http  80/TCP
TargetPort:        80/TCP
Endpoints:         10.244.197.66:80
Session Affinity:  None
Events:            <none>
```

**Demo NetworkPolicy**

First, exec into pod sleep and curl httpbin:

```sh
➜  ns1 git:(master) kubectl exec -it sleep-8494d75958-d99p7 -n n1 -- sh
/ $ curl -v httpbin.n1.svc.cluster.local:8000
*   Trying 10.96.8.24:8000...
* Connected to httpbin.n1.svc.cluster.local (10.96.8.24) port 8000 (#0)
> GET / HTTP/1.1
> Host: httpbin.n1.svc.cluster.local:8000
> User-Agent: curl/7.77.0-DEV
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Server: gunicorn/19.9.0
< Date: Mon, 06 Mar 2023 12:58:28 GMT
< Connection: keep-alive
< Content-Type: text/html; charset=utf-8
< Content-Length: 9593
< Access-Control-Allow-Origin: *
< Access-Control-Allow-Credentials: true
<
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <title>httpbin.org</title>
    <link href="https://fonts.googleapis.com/css?family=Open+Sans:400,700|Source+Code+Pro:300,600|Titillium+Web:400,600,700"
        rel="stylesheet">
    <link rel="stylesheet" type="text/css" href="/flasgger_static/swagger-ui.css">
    <link rel="icon" type="image/png" href="/static/favicon.ico" sizes="64x64 32x32 16x16" />
    <style>
        html {
            box-sizing: border-box;
            overflow: -moz-scrollbars-vertical;
            ...
```

Create [deny policy](default-policy.yaml):

```sh
➜  ns1 git:(master) kubectl apply -f default-policy.yaml
networkpolicy.networking.k8s.io/n1-deny-ns1 created
➜  ns1 git:(master) kubectl exec -it sleep-8494d75958-d99p7 -n n1 -- sh
/ $ curl -v httpbin.n1.svc.cluster.local:8000
*   Trying 10.96.8.24:8000...
# .... timeout
```

Create policy allow pods has `label: app=sleep`:

```sh
➜  ns1 git:(master) ✗ kubectl apply -f allow-policy.yaml
networkpolicy.networking.k8s.io/access-httpbin-1 created
➜  ns1 git:(master) ✗ kubectl exec -it sleep-8494d75958-d99p7 -n n1 -- sh
/ $ curl -v httpbin.n1.svc.cluster.local:8000
*   Trying 10.96.8.24:8000...
* Connected to httpbin.n1.svc.cluster.local (10.96.8.24) port 8000 (#0)
> GET / HTTP/1.1
> Host: httpbin.n1.svc.cluster.local:8000
> User-Agent: curl/7.77.0-DEV
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Server: gunicorn/19.9.0
< Date: Mon, 06 Mar 2023 13:30:01 GMT
< Connection: keep-alive
< Content-Type: text/html; charset=utf-8
< Content-Length: 9593
< Access-Control-Allow-Origin: *
< Access-Control-Allow-Credentials: true
<
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <title>httpbin.org</title>
    <link href="https://fonts.googleapis.com/css?family=Open+Sans:400,700|Source+Code+Pro:300,600|Titillium+Web:400,600,700"
        rel="stylesheet">
    <link rel="stylesheet" type="text/css" href="/flasgger_static/swagger-ui.css">
    <link rel="icon" type="image/png" href="/static/favicon.ico" sizes="64x64 32x32 16x16" />
    <style>
        html {
            box-sizing: border-box;
            overflow: -moz-scrollbars-vertical;
            overflow-y: scroll;
        }
        ...
```

Done !!!
