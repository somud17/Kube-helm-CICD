#  Kubernetes installation on GCE 
 Starting a cluster
 You can install a client and start a cluster with either one of these commands (we list both in case only one is installed on your machine):

```console
curl -sS https://get.k8s.io | bash
```
or
```console
wget -q -O - https://get.k8s.io | bash
```
Once this command completes, you will have a master VM and four worker VMs, running as a Kubernetes cluster.

By default, some containers will already be running on your cluster. Containers like fluentd provide logging, while heapster provides 
monitoring services.

The script run by the commands above creates a cluster with the name/prefix “kubernetes”. It defines one specific cluster config, 
so you can’t run it more than once.

cd kubernetes
cluster/kube-up.sh

# Getting started with your cluster
Inspect your cluster. Once kubectl is in your path, you can use it to look at your cluster. E.g., running:

```console
kubectl get --all-namespaces services
```
should show a set of services that look something like this:
```console
NAMESPACE     NAME          TYPE             CLUSTER_IP       EXTERNAL_IP       PORT(S)        AGE
default       kubernetes    ClusterIP        10.0.0.1         <none>            443/TCP        1d
kube-system   kube-dns      ClusterIP        10.0.0.2         <none>            53/TCP,53/UDP  1d
kube-system   kube-ui       ClusterIP        10.0.0.3         <none>            80/TCP         1d
```
Similarly, you can take a look at the set of pods that were created during cluster startup. You can do this via the
```console
kubectl get --all-namespaces pods
```
command.

You’ll see a list of pods that looks something like this (the name specifics will be different):
```console
NAMESPACE     NAME                                           READY     STATUS    RESTARTS   AGE
kube-system   coredns-5f4fbb68df-mc8z8                       1/1       Running   0          15m
kube-system   fluentd-cloud-logging-kubernetes-minion-63uo   1/1       Running   0          14m
kube-system   fluentd-cloud-logging-kubernetes-minion-c1n9   1/1       Running   0          14m
kube-system   fluentd-cloud-logging-kubernetes-minion-c4og   1/1       Running   0          14m
kube-system   fluentd-cloud-logging-kubernetes-minion-ngua   1/1       Running   0          14m
kube-system   kube-ui-v1-curt1                               1/1       Running   0          15m
kube-system   monitoring-heapster-v5-ex4u3                   1/1       Running   1          15m
kube-system   monitoring-influx-grafana-v1-piled             2/2       Running   0          15m
```
Some of the pods may take a few seconds to start up (during this time they’ll show Pending), but check that they all show as 
Running after a short period.

This section shows the simplest way to get the example work. If you want to know the details, you should skip this and read 
the rest of the example.

Start the guestbook with one command:
```console
$ kubectl create -f guestbook/all-in-one/guestbook-all-in-one.yaml
service "redis-master" created
deployment "redis-master" created
service "redis-slave" created
deployment "redis-slave" created
service "frontend" created
deployment "frontend" created
```
Then, list all your Services:
```console
$ kubectl get services
NAME           CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
frontend       10.0.0.117   <none>        80/TCP     20s
redis-master   10.0.0.170   <none>        6379/TCP   20s
redis-slave    10.0.0.201   <none>        6379/TCP   20s
```
Now you can access the guestbook on each node with frontend Service’s <Cluster-IP>:<PORT>, e.g. 10.0.0.117:80 in this guide. 
<Cluster-IP> is a cluster-internal IP. If you want to access the guestbook from outside of the cluster, add type: NodePort to the 
frontend Service spec field. Then you can access the guestbook with <NodeIP>:NodePort from outside of the cluster. On cloud providers 
which support external load balancers, adding type: LoadBalancer to the frontend Service spec field will provision a load balancer for 
your Service. There are several ways for you to access the guestbook. You may learn from Accessing services running on the cluster.
```console
kubectl get services -l "app=redis,role=slave,tier=backend
```
Clean up the guestbook:
```console
$ kubectl delete -f guestbook/all-in-one/guestbook-all-in-one.yaml
```
Tearing down the cluster
To remove/delete/teardown the cluster, use the kube-down.sh script.
```console
cd kubernetes
cluster/kube-down.sh
```
Likewise, the kube-up.sh in the same directory will bring it back up. You do not need to rerun the curl or wget command: everything 
needed to setup the Kubernetes cluster is now on your workstation.




