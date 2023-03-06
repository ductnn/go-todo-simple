## Setup

- Init:
```sh
minikube start --nodes 2 -p node --vm-driver="virtualbox" --network-plugin=cni --cni=flannel
# minikube start --nodes 2 -p node --vm-driver="virtualbox" --network-plugin=cni --cni=calico
# minikube start --nodes 2 -p node --vm-driver="virtualbox" --extra-config=kubeadm.pod-network-cidr=10.244.0.0/16 --network-plugin=cni --cni=flannel
# minikube start --nodes 2 -p node --vm-driver="hyperkit" --network-plugin=cni --cni=flannel
```

- Create deployment nginx:
```sh
kubectl create deployment nginx --image=nginx
# expose svc
kubectl expose deployment nginx --port=80
```

- Create pod busybox
```sh
kubectl run busybox --image=busybox --restart=Never -- sleep 3600
```

- Create NetworkPolicy file `deny-all.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: block-nginx-ingress-from-other-pods
spec:
  podSelector:
    matchLabels:
      app: nginx
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: busybox
  - from:
    - podSelector: {}
    - namespaceSelector: {}
```

Apply
```sh
kubectl apply -f deny-all.yaml
```

- Test:

```sh
kubectl exec busybox -- wget --spider --timeout=1 <svc nginx>
=> Failed timeout
```


=====

## Setup v2

- Init:
```sh
minikube start --nodes 2 -p node --vm-driver="virtualbox" --network-plugin=cni --cni=flannel
# minikube start --nodes 2 -p node --vm-driver="virtualbox" --network-plugin=cni --cni=calico
```

**Note:** Flannel not support native Network Policy
=> Solution: Using third party like Calico
```sh
kubectl apply -f [canal.yaml](canal.yaml)
```

- Installing with the etcd datastore:
```sh

```

```sh
# Common ns
kubectl create ns policy-demo

# Create deployment nginx
kubectl create deployment --namespace=policy-demo nginx --image=nginx
kubectl expose --namespace=policy-demo deployment nginx --port=80

# Run pod busybox with labels run=access
kubectl run --namespace=policy-demo access --rm -ti --image busybox /bin/sh
#
# Exec to pod
# wget -q <nginx-service-ip> -O -
#
# wget success

# Setup policy deny all
kubectl create -f - <<EOF
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: default-deny
  namespace: policy-demo
spec:
  podSelector:
    matchLabels: {}
EOF

# Test again
kubectl run --namespace=policy-demo access --rm -ti --image busybox /bin/sh
#
# Exec to pod
# wget -q --timeout=5 <nginx-service-ip> -O -
#
# wget: download timed out

# Setup allow policy -> enable for pods with label run=access
kubectl create -f - <<EOF
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: access-nginx
  namespace: policy-demo
spec:
  podSelector:
    matchLabels:
      app: nginx
  ingress:
    - from:
      - podSelector:
          matchLabels:
            run: access
EOF

# Test correct pods
kubectl run --namespace=policy-demo access --rm -ti --image busybox /bin/sh
#
# Exec to pod
# wget -q --timeout=5 <nginx-service-ip> -O -
#
# wget success

# Test incorrect pods
kubectl run --namespace=policy-demo dummy-access --rm -ti --image busybox /bin/sh
#
# Exec to pod
# wget -q --timeout=5 <nginx-service-ip> -O -
#
# wget: download timed out
```



### Examples Calico

```sh
kubectl create -f https://docs.tigera.io/files/00-namespace.yaml
kubectl create -f https://docs.tigera.io/files/01-management-ui.yaml
kubectl create -f https://docs.tigera.io/files/02-backend.yaml
kubectl create -f https://docs.tigera.io/files/03-frontend.yaml
kubectl create -f https://docs.tigera.io/files/04-client.yaml
```