# Kube-helm-CICD
Deploy app using helm in kubernetes cluster by CI server(jenkins)

jx create cluster would

- Set up a single node kubernetes cluster
- Install and configure helm
- Connect to GitHub account using API Token
- Install ingress Controller
- Install Jenkins X platform for Minikube Cluster
	- Create jx namespace
		- Deploys addons like jenkins, ChartMuseum, Docker Registry etc.
	- Create jx-staging namespace for staging environment
	- Create jx-production namespace for production environment
- Connects to our GitHub and creates two GitHub repository for GitOps
	- Environment-xxxxxxx-staging
	- Environment-xxxxxxx-production

Install Jenkins and configure CI pipelines

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

7 - On the next screen, the setup wizard will ask you whether you want to install suggested plugins or you want to select specific plugins. 
	Click on the Install suggested plugins box, and the installation process will start immediately.

8 - Once the plugins are installed, you will be prompted to set up the first admin user. Fill out all required information and click Save and Continue.

9 - The next page will ask you to set the URL for your Jenkins instance. The field will be populated with an automatically generated URL.

10 - Confirm the URL by clicking on the Save and Finish button and the setup process will be completed.

11 - Click on the Start using Jenkins button and you will be redirected to the Jenkins dashboard logged in as the admin user you have created 
	 in one of the previous steps.

12 - At this point, you’ve successfully installed Jenkins on your system.

Helm install and Configure:

1 - Install And Configure Helm And Tiller
	The easiest way to run and manage applications in a Kubernetes cluster is using Helm. Helm allows you to perform key operations for managing 
	applications such as install, upgrade or delete. Helm is composed of two parts: Helm (the client) and Tiller (the server). Follow the steps below 
	to complete both Helm and Tiller installation and create the necessary Kubernetes objects to make Helm work with Role-Based Access Control
	(RBAC):To install Helm, run the following commands:

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

Guestbook
Guestbook is a simple, multi-tier PHP-based web application that uses redis chart.

TL;DR;
$ helm install stable/guestbook
Introduction
This chart bootstraps a guestbook deployment on a Kubernetes cluster using the Helm package manager.

It also packages the Bitnami Redis chart which is required for bootstrapping a Redis deployment for the caching requirements of the guestbook application.

Prerequisites
Kubernetes 1.4+ with Beta APIs enabled
PV provisioner support in the underlying infrastructure
Installing the Chart
To install the chart with the release name my-release:

$ helm install --name my-release stable/guestbook
The command deploys the guestbook on the Kubernetes cluster in the default configuration. The configuration section lists the parameters that can be configured during installation.

Tip: List all releases using helm list

Uninstalling the Chart
To uninstall/delete the my-release deployment:

$ helm delete my-release
The command removes all the Kubernetes components associated with the chart and deletes the release.

Configuration
The following tables lists the configurable parameters of the WordPress chart and their default values.

Parameter	Description	Default
image	apapche-php image	google-samples/gb-frontend:{VERSION}
imagePullPolicy	Image pull policy	IfNotPresent
nodeSelector	Node labels for pod assignment	{}
The above parameters map to the env variables defined in bitnami/wordpress. For more information please refer to the bitnami/wordpress image documentation.

Specify each parameter using the --set key=value[,key=value] argument to helm install. For example,

$ helm install --name my-release \
  --set redis.usePassword=false \
    stable/guestbook
$ helm install --name my-release -f values.yaml stable/guestbook
Tip: You can use the default values.yaml
