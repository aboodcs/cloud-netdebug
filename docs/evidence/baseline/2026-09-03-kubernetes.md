# Kubernetes Baseline Snapshot — 2026-09-03

Captured from Kubernetes context `minikube` between `2026-09-03T16:33:55+03:00` and `2026-09-03T16:37:09+03:00`.

This is a point-in-time runtime observation. It does not establish AWS or OCI deployment status and should not be treated as current after the cluster changes.

## Workload state

Commands:

```bash
kubectl get namespace netdebug -o name
kubectl get deployment netdebug-app -n netdebug -o wide
kubectl get pods -n netdebug -l app=netdebug-app -o wide --show-labels
```

Observed result:

```text
namespace/netdebug

NAME           READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES         SELECTOR
netdebug-app   2/2     2            2           71m   nginx        nginx:latest   app=netdebug-app

NAME                            READY   STATUS    RESTARTS      AGE   IP              NODE       NOMINATED NODE   READINESS GATES   LABELS
netdebug-app-78687cbd89-ctmzz   1/1     Running   1 (70m ago)   71m   10.244.120.69   minikube   <none>           <none>            app=netdebug-app,pod-template-hash=78687cbd89
netdebug-app-78687cbd89-tjbtz   1/1     Running   1 (70m ago)   71m   10.244.120.68   minikube   <none>           <none>            app=netdebug-app,pod-template-hash=78687cbd89
```

At capture time, both desired replicas were available and both Pods reported Ready. Each Pod had restarted once; this snapshot does not diagnose the earlier restart.

## Service and EndpointSlice

Commands:

```bash
kubectl get service netdebug-service -n netdebug -o wide
kubectl get endpointslice -n netdebug \
  -l kubernetes.io/service-name=netdebug-service -o wide
```

Observed result:

```text
NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE   SELECTOR
netdebug-service   ClusterIP   10.98.133.36   <none>        80/TCP    71m   app=netdebug-app

NAME                     ADDRESSTYPE   PORTS   ENDPOINTS                     AGE
netdebug-service-lbl47   IPv4          80      10.244.120.68,10.244.120.69   71m
```

The EndpointSlice addresses match the two observed Pod IPs.

## Service response

Command:

```bash
kubectl get --raw \
  '/api/v1/namespaces/netdebug/services/http:netdebug-service:80/proxy/'
```

Observed response excerpt:

```html
<title>Welcome to nginx!</title>
<h1>Welcome to nginx!</h1>
<p>If you see this page, nginx is successfully installed and working.
```

The command exited with status `0`. This proves that the Kubernetes API service-proxy path reached an nginx backend through the named Service at capture time. It does not prove ordinary Pod-to-ClusterIP traffic, direct external exposure, or NetworkPolicy allow/deny behavior.

## NetworkPolicy and approved clients

Commands:

```bash
kubectl get networkpolicy allow-approved-client -n netdebug \
  -o jsonpath='name={.metadata.name}{"\n"}podSelector={.spec.podSelector.matchLabels}{"\n"}policyTypes={.spec.policyTypes}{"\n"}allowedPodSelector={.spec.ingress[0].from[0].podSelector.matchLabels}{"\n"}'
kubectl get pods -n netdebug -l access=allowed -o wide
kubectl get pods -n kube-system -l k8s-app=calico-node -o wide
```

Observed result:

```text
name=allow-approved-client
podSelector={"app":"netdebug-app"}
policyTypes=["Ingress"]
allowedPodSelector={"access":"allowed"}

No resources found in netdebug namespace.

NAME                READY   STATUS    RESTARTS   AGE   IP             NODE       NOMINATED NODE   READINESS GATES
calico-node-5vp2p   1/1     Running   0          71m   192.168.49.2   minikube   <none>           <none>
```

Calico was running, but no Pod with `access=allowed` existed. No approved-versus-unapproved connectivity test was performed, so policy enforcement is not marked verified.

## Cluster addressing observed

Commands:

```bash
kubectl get nodes \
  -o custom-columns='NAME:.metadata.name,POD_CIDR:.spec.podCIDR,INTERNAL_IP:.status.addresses[?(@.type=="InternalIP")].address'
kubectl get --raw '/apis/crd.projectcalico.org/v1/ippools'
kubectl get pod kube-apiserver-minikube -n kube-system \
  -o jsonpath='{.spec.containers[0].command}'
```

Observed values:

```text
Node: minikube
Node .spec.podCIDR: 10.244.0.0/24
Node internal IP: 192.168.49.2
Calico IPPool: 10.244.0.0/16
API server --service-cluster-ip-range: 10.96.0.0/12
```

The Calico IPPool contains the observed Pod addresses. The node's `.spec.podCIDR` is narrower and does not contain the two observed `10.244.120.x` Pod addresses, so this cluster's Calico IPPool—not the node field alone—is the relevant allocation evidence.
