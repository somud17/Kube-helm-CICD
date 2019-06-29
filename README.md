# Kube-helm-CICD
Deploy app using helm in kubernetes cluster by CI server(jenkins)

jx create cluster would

- Set up a single node kubernetes cluster
- Install and configure helm
- Connect to GitHub account using API Token
- Install ingress Controller
- Install Jenkins X platform for Kubernetes Cluster
	- Create jx namespace
		- Deploys addons like jenkins, ChartMuseum, Docker Registry etc.
	- Create jx-devlopment namespace for development environment
	- Create jx-monitoring namespace for monitoring environment
- Connects to our GitHub and creates two GitHub repository for GitOps
	- Environment-xxxxxxx-development
	- Environment-xxxxxxx-monitoring

# Install Jenkins and configure CI pipelines

1 - Install Java.

		sudo apt update
		sudo apt install openjdk-8-jdk
		
2 - Add the Jenkins Debian repository.

		wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
	Next, add the Jenkins repository to the system with:
		sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

3 - Install Jenkins.

		sudo apt update
		sudo apt install jenkins
		systemctl status jenkins
		
	You should see something similar to this:
	Output:
			
			● jenkins.service - LSB: Start Jenkins at boot time
			Loaded: loaded (/etc/init.d/jenkins; generated)
			Active: active (exited) since Wed 2018-08-22 1308 PDT; 2min 16s ago
				Docs: man:systemd-sysv-generator(8)
				Tasks: 0 (limit: 2319)
			CGroup: /system.slice/jenkins.service

4 - If 8080 port is in use, adjust Firewall as below:

		sudo ufw allow 8080
		Verify the change with:
			sudo ufw status

5 - Setting Up Jenkins
	
	To set up your new Jenkins installation, open your browser, type your domain or IP address followed by port 8080,
		http://your_ip_or_domain:8080.
	
	During the installation, the Jenkins installer creates an initial 32-character long alphanumeric password. 
	Use the following command to print the password on your terminal:
		
		cat /var/lib/jenkins/secrets/initialAdminPassword

6 - Copy the password from your terminal, paste it into the Administrator password field and click Continue.

7 - On the next screen, the setup wizard will ask you whether you want to install suggested plugins or you want to select specific plugins. Click on the Install suggested plugins box, and the installation process will start immediately.

8 - Once the plugins are installed, you will be prompted to set up the first admin user. Fill out all required information and click Save and Continue.

9 - The next page will ask you to set the URL for your Jenkins instance. The field will be populated with an automatically generated URL.

10 - Confirm the URL by clicking on the Save and Finish button and the setup process will be completed.

11 - Click on the Start using Jenkins button and you will be redirected to the Jenkins dashboard logged in as the admin user you have created in one of the previous steps.

12 - At this point, you’ve successfully installed Jenkins on your system.

#  Helm install and Configure:

1 - Install And Configure Helm And Tiller
	The easiest way to run and manage applications in a Kubernetes cluster is using Helm. Helm allows you to perform key operations for managing applications such as install, upgrade or delete. Helm is composed of two parts: Helm (the client) and Tiller (the server). Follow the steps below to complete both Helm and Tiller installation and create the necessary Kubernetes objects to make Helm work with Role-Based Access Control (RBAC):To install Helm, run the following commands:

		curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
		chmod 700 get_helm.sh
		./get_helm.sh
		
2 - Create a ClusterRole configuration file with the content below. In this example, it is named clusterrole.yaml.

		apiVersion: rbac.authorization.k8s.io/v1
		kind: ClusterRole
		metadata:
		annotations:
			rbac.authorization.kubernetes.io/autoupdate: "true"
		labels:
			kubernetes.io/bootstrapping: rbac-defaults
		name: cluster-role
		rules:
		- apiGroups:
		- '*'
		resources:
		- '*'
		verbs:
		- '*'
		- nonResourceURLs:
		- '*'
		verbs:
		- '*'
3 - To create the ClusterRole, run this command:

		kubectl create -f clusterrole.yaml

4 - To create a ServiceAccount and associate it with the ClusterRole, use a ClusterRoleBinding, as below:
		
		kubectl create serviceaccount -n kube-system tiller
		kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-role --serviceaccount=kube-system:tiller

5 - Initialize Helm as shown below:
		
		helm init --service-account tiller

6 - If you have previously initialized Helm, execute the following command to upgrade it:
		
		helm init --upgrade --service-account tiller

7 - Check if Tiller is correctly installed by checking the output of kubectl get pods as shown below:
		
		kubectl --namespace kube-system get pods | grep tiller
		tiller-deploy-2885612843-xrj5m   1/1       Running   0   4d

# Guestbook

[Guestbook](https://github.com/kubernetes/examples/tree/master/guestbook) is a simple, multi-tier PHP-based web application that uses redis chart.
## TL;DR;

```console
$ helm install stable/guestbook
```

## Introduction

This chart bootstraps a [guestbook](https://github.com/kubernetes/examples/tree/master/guestbook) deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

It also packages the [Bitnami Redis chart](https://github.com/kubernetes/charts/tree/master/stable/redis) which is required for bootstrapping a Redis deployment for the caching requirements of the guestbook application.

## Prerequisites

- Kubernetes 1.4+ with Beta APIs enabled
- PV provisioner support in the underlying infrastructure

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release stable/guestbook
```

The command deploys the guestbook on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following tables lists the configurable parameters of the WordPress chart and their default values.

| Parameter                            | Description                                | Default                                                    |
| -------------------------------      | -------------------------------            | ---------------------------------------------------------- |
| `image`                              | apapche-php image                          | `google-samples/gb-frontend:{VERSION}`                     |
| `imagePullPolicy`                    | Image pull policy                          | `IfNotPresent`                                             |
| `nodeSelector`                       | Node labels for pod assignment             | `{}`                                                       |

The above parameters map to the env variables defined in [bitnami/wordpress](http://github.com/bitnami/bitnami-docker-wordpress). For more information please refer to the [bitnami/wordpress](http://github.com/bitnami/bitnami-docker-wordpress) image documentation.

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
$ helm install --name my-release \
  --set redis.usePassword=false \
    stable/guestbook
```

```console
$ helm install --name my-release -f values.yaml stable/guestbook
```

> **Tip**: You can use the default [values.yaml](values.yaml)


#  K8S Monitoring: Prometheus, AlertManager and Grafana

This is Work in Progress, but I believe that works

Setup
1. Create a namespace to group our resources and export NAMESPACE env, in our case we named it monitoring

```console
	$ kubectl create namespace monitoring
	namespace "monitoring" created
	$ export NAMESPACE=monitoring
```

2. Create a TLS secret named etcd-tls-client-certs
Our Prometheus Deployment uses TLS keypair and TLS auth for etcd cluster

2.1 Generate keys

```console
$ openssl req \
  -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout tls.key -out tls.crt -subj '/CN=localhost'
Generating a 2048 bit RSA private key
.................................................................+++
............................................................................................+++
writing new private key to 'tls.key'https://prometheus.io/docs/alerting/configuration/
-----
```

2.2 Create secret

$ kubectl create secret tls etcd-tls-client-certs --cert=tls.crt --key=tls.key -n=monitoring
secret "tls-secret" created

3 Configure Alerting
We have only slack alert template and configuration for Slack alerts. Change the slack api url properly according to your Slack Hooks configuration.

Included alert rules
Prometheus alert rules which are already included in this repo:

NodeCPUUsage > 50%
NodeLowRootDisk > 80% (relates to /root-disk mount point inside node-exporter pod)
NodeLowDataDisk > 80% (relates to /data-disk mount point inside node-exporter pod)
NodeSwapUsage > 10%
NodeMemoryUsage > 75%
NodeLoadAverage (alerts when node's load average divided by amount of CPUs exceeds 1)

4 Just run the script deploy.sh

```console
$ cd scripts/
$ . deploy.sh 
configmap "external-url" created
configmap "grafana-imports" created
configmap "prometheus-rules" created
configmap "alertmanager-templates" created
configmap "alertmanager" created
configmap "prometheus" created
deployment "alertmanager" created
service "alertmanager" created
deployment "grafana" created
service "grafana" created
daemonset "node-exporter" created
configmap "prometheus-env" created
deployment "prometheus-deployment" created
service "prometheus-svc" created
Successfully deployed!
NAME                                    READY     STATUS              RESTARTS   AGE
alertmanager-670954578-gw5c0            0/1       ContainerCreating   0          2s
grafana-1556722099-xmkh1                0/2       ContainerCreating   0          1s
node-exporter-mt9c4                     0/1       ContainerCreating   0          1s
node-exporter-pgf51                     0/1       ContainerCreating   0          1s
node-exporter-v028j                     0/1       ContainerCreating   0          1s
node-exporter-vbj2k                     0/1       ContainerCreating   0          1s
prometheus-deployment-534706379-965p6   0/1       ContainerCreating   0          1s
```

Project organization:
The config directory contains the configuration's files used for creation of ConfigMaps by deploy.sh
The config/alertmanager-cm directory contains the configuration file for the alertmanager. The ConfigMap is called by alertmanager deployment. More info in the docs
The config/alertmanager-templates-cm directory contains custom alertmanager templates. The ConfigMap is called by alertmanager deployment. More info here.
The config/grafana-imports-cm directory contains Grafana Dashboards and Prometheus Datasource Plugin. The ConfigMap is called by grafana deployment.
The config/prometheus-cm directory contains the configuration file for Prometheus, including the K8S Service Discovery configs. The ConfigMap is called by prometheus deployment. More info in the docs.
The config/prometheus-rules-cm directory contains the prometheus alert rules. The ConfigMap is called by prometheus deployment. More info in the docs
The deployments directory contains the definitions of our deployments and services. We exposed our services by NodePort, however, you can edit the following files removing the type: NodePort spec of services and use Ingress instead. Both approaches can be found here.
alertmanager-deploy-svc.yaml: Deployment and Service of alertmanager
grafana-deploy-svc.yaml: Deployment and Service of Grafana, including dashboard/datasource imports
node-exporter-ds.yaml: Deamonset to export hardware and OS metrics
prometheus-deploy-svc.yaml: Deployment and Service of Prometheus

The Scripts directory contains automatized routines
deploy.sh: Initialize all resources
undeploy.sh: Delete all resources
update_alertmanager_config.sh: Updates the alertmanager ConfigMap by changes made in alertmanager-cm
update_alertmanager_templates.sh: Updates the alertmanager-templates ConfigMap by changes made in alertmanager-templates-cm
update_grafana_imports.sh: Updates the grafana-imports ConfigMap by changes made in grafana-imports-cm
update_prometheus_config.sh: Updates the prometheus ConfigMap by changes made in prometheus-cm
update_prometheus_rules.sh: Updates the prometheus-rules ConfigMap by changes made in prometheus-rules-cm
