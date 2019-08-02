# Kube-helm-CICD
# task2

# Create a service account
1. Create the service account itself:

```console
gcloud iam service-accounts create jenkins --display-name jenkins
```

2. Store the service account email address and your current Google Cloud Platform (GCP) project ID in environment variables for use in later commands:
```console
export SA_EMAIL=$(gcloud iam service-accounts list \
    --filter="displayName:jenkins" --format='value(email)')
export PROJECT=$(gcloud info --format='value(config.project)')
```
3. Bind the following roles to your service account:
```console
gcloud projects add-iam-policy-binding $PROJECT \
    --role roles/storage.admin --member serviceAccount:$SA_EMAIL
gcloud projects add-iam-policy-binding $PROJECT --role roles/compute.instanceAdmin.v1 \
    --member serviceAccount:$SA_EMAIL
gcloud projects add-iam-policy-binding $PROJECT --role roles/compute.networkAdmin \
    --member serviceAccount:$SA_EMAIL
gcloud projects add-iam-policy-binding $PROJECT --role roles/compute.securityAdmin \
    --member serviceAccount:$SA_EMAIL
gcloud projects add-iam-policy-binding $PROJECT --role roles/iam.serviceAccountActor \
    --member serviceAccount:$SA_EMAIL
```
# Download the service account key
Now that you've granted the service account the appropriate permissions, you need to create and download its key. Keep the key in a safe place. You'll use it later step when you configure the JClouds plugin to authenticate with the Compute Engine API.

1. Create the key file:
```console
gcloud iam service-accounts keys create jenkins-sa.json --iam-account $SA_EMAIL
```
2. In Cloud Shell, click More :, and then click Download file.

3. Type jenkins-sa.json.

4. Click Download to save the file locally.

# Create a Jenkins agent image
Next, you create a reusable Compute Engine image that contains the software and tools needed to run as a Jenkins executor.

Create an SSH key for Cloud Shell
Use Packer to build your images, which requires the ssh command to communicate with your build instances. To enable SSH access, create and upload an SSH key in Cloud Shell:

Create a SSH key pair. If one already exists, this command uses that key pair; otherwise, it creates a new one:
```console
ls ~/.ssh/id_rsa.pub || ssh-keygen -N ""
```
Add the Cloud Shell public SSH key to your project's metadata:
```console
gcloud compute project-info describe \
    --format=json | jq -r '.commonInstanceMetadata.items[] | select(.key == "ssh-keys") | .value' > sshKeys.pub
echo "$USER:$(cat ~/.ssh/id_rsa.pub)" >> sshKeys.pub
gcloud compute project-info add-metadata --metadata-from-file ssh-keys=sshKeys.pub
```
Create the baseline image

The next step is to use Packer to create a baseline virtual machine (VM) image for your build agents, which act as ephemeral build executors in Jenkins. The most basic Jenkins agent only requires Java to be installed. You can customize your image by adding shell commands in the provisioners section of the Packer configuration or by adding other Packer provisioners.

In Cloud Shell, download and unpack Packer:
```console
wget https://releases.hashicorp.com/packer/0.12.3/packer_0.12.3_linux_amd64.zip
unzip packer_0.12.3_linux_amd64.zip
```
Create the configuration file for your Packer image builds:
```console
export PROJECT=$(gcloud info --format='value(config.project)')
cat > jenkins-agent.json <<EOF
{
  "builders": [
    {
      "type": "googlecompute",
      "project_id": "$PROJECT",
      "source_image_family": "ubuntu-1604-lts",
      "source_image_project_id": "ubuntu-os-cloud",
      "zone": "us-central1-a",
      "disk_size": "10",
      "image_name": "jenkins-agent-{{timestamp}}",
      "image_family": "jenkins-agent",
      "ssh_username": "ubuntu"
    }
  ],
  "provisioners": [
    {
      "type": "shell",
      "inline": ["sudo apt-get update",
                  "sudo apt-get install -y default-jdk"]
    }
  ]
}
EOF
```
Build the image by running Packer:
```console
./packer build jenkins-agent.json
```
When the build completes, the name of the disk image is displayed with the format jenkins-agent-[TIMESTAMP], where [TIMESTAMP] is the epoch time when the build started.
```console
==> Builds finished. The artifacts of successful builds are:
--> googlecompute: A disk image was created: jenkins-agent-{timestamp}
```

# Now we will create an Jenkins instance via terraform .

Clone the repository https://github.com/somud17/Kube-helm-CICD
```console
git clone https://github.com/somud17/Kube-helm-CICD
````

Create jenkins instance with ready kubernetes cluster, follow below steps:
```console
terraform init
terraform plan
terraform validate
terraform apply

```



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
