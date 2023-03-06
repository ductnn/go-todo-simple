##

Create nginx:
```sh
kubectl create deployment --namespace=n1 nginx --image=nginx
kubectl expose --namespace=n1 deployment nginx --port=80
```

DNS
```
httpbin.n1.svc.cluster.local
```