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
First we will install, configure the kubernetes cluster, helm and then configure jenkins to work with CI/CD.

# Starting a Kubernetes cluster
You can install a client and start a cluster with either one of these commands (we list both in case only one is installed on your machine):
```console
curl -sS https://get.k8s.io | bash
or

wget -q -O - https://get.k8s.io | bash
```
Once this command completes, you will have a master VM and four worker VMs, running as a Kubernetes cluster.

By default, some containers will already be running on your cluster. Containers like fluentd provide logging, while heapster provides monitoring services.

The script run by the commands above creates a cluster with the name/prefix “kubernetes”. It defines one specific cluster config, so you can’t run it more than once.

Alternately, you can download and install the latest Kubernetes release from this page, then run the <kubernetes>/cluster/kube-up.sh script to start the cluster:
```console
cd kubernetes
cluster/kube-up.sh
```

Getting started with your cluster
Inspect your cluster
Once kubectl is in your path, you can use it to look at your cluster. E.g., running:
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
Some of the pods may take a few seconds to start up (during this time they’ll show Pending), but check that they all show as Running after a short period.

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

# Configuring Jenkins plugins
Jenkins requires plugins to create on-demand agents in Compute Engine and to store artifacts in Cloud Storage. You need to install and configure these plugins.

Install plugins
In the Jenkins UI, select Manage Jenkins.
Click Manage Plugins.
Click the Available tab.
Use the Filter bar to find the following plugins and select the boxes next to them:

Compute Engine plugin
Cloud Storage plugin
The following image shows the Cloud Storage plugin selected:

Cloud Storage plugin.

Click Download now and install after restart.

Click the Restart Jenkins when installation is complete and no jobs are running checkbox. Jenkins restarts and completes the plugin installations.

Create plugin credentials
You need to create Google Credentials for your new plugins:

Log in to Jenkins again, and click Jenkins.
Click Credentials.
Click System.
In the main pane of the UI, click Global credentials (unrestricted).
Create the Google credentials:

Click Add Credentials.
Set Kind to Google Service Account from private key.
In the Project Name field, enter your GCP project ID.
Click Choose file.
Select the jenkins-sa.json file that you previously downloaded from Cloud Shell.
Click OK.

JSON key credentials.

Click Jenkins.

Configure the Compute Engine plugin
Configure the Compute Engine plugin with the credentials it uses to provision your agent instances.

Click Manage Jenkins.
Click Configure System.
Click Add a new Cloud.
Click Compute Engine.
Set the following settings and replace [YOUR_PROJECT_ID] with your GCP project ID:

Name: gce
Project ID: [YOUR_PROJECT_ID]
Instance Cap: 8
Choose the service account from the Service Account Credentials drop-down list. It is listed as your GCP project ID.

Configure Jenkins instance configurations
Now that the Compute Engine plugin is configured, you can configure Jenkins instance configurations for the various build configurations you'd like.

On the Configure System page, click Add add for Instance Configurations.
Enter the following General settings:

Name: ubuntu-1604
Description: Ubuntu agent
Labels: ubuntu-1604
Enter the following for Location settings:

Region<: us-central1
Zone: us-central1-f
Click Advanced.

For Machine Configuration, choose the Machine Type of n1-standard-1.

Under Networking, choose the following settings:

Network: Leave at default setting.
Subnetwork: Leave at default setting.
Select Attach External IP?.
Select the following for Boot Disk settings:

For Image project, choose your GCP project.
For Image name, select the image you built earlier using Packer.
Click Save to persist your configuration changes.

Compute Engine configurations for Jenkins.

Creating a Jenkins job to test the configuration
Jenkins is configured to automatically launch an instance when a job is triggered that requires an agent with the ubuntu-1604 label. Create a job that tests whether the configuration is working as expected.

Click Create new job in the Jenkins interface.
Enter test as the item name.
Click Freestyle project, and then click OK.
Select the Execute concurrent builds if necessary and Restrict where this project can run boxes.
In the Label Expression field, enter ubuntu-1604.

New job in Jenkins.

In the Build section, click Add build step.

Click Execute Shell.

In the command box, enter a test string:

echo "Hello world!"
Hello World typed in the command box for Jenkins.

Click Save.

Click Build Now to start a build.

Build Now.

Uploading build artifacts to Cloud Storage
You might want to store build artifacts for future analysis or testing. Configure your Jenkins job to generate an artifact and upload it to Cloud Storage. The build log is uploaded to the same bucket.

In Cloud Shell, create a storage bucket for your artifacts:
```console
export PROJECT=$(gcloud info --format='value(config.project)')
gsutil mb gs://$PROJECT-jenkins-artifacts
```
In the job list in the Jenkins UI, click test.

Click Configure.

Under Build, set the Command text field to:

env > build_environment.txt
Under Post-build Actions, click Add post-build action.

Click Cloud Storage Plugin.

In the Storage Location field, enter your artifact path, substituting your GCP project ID for [YOUR_PROJECT_ID]:
```console
gs://[YOUR_PROJECT_ID]-jenkins-artifacts/$JOB_NAME/$BUILD_NUMBER
```
Click Add Operation.

Click Classic Upload.

In the File Pattern field, enter build_environment.txt.

In the Storage Location field, enter your storage path, substituting your GCP project ID for [YOUR_PROJECT_ID]:
```console
gs://[YOUR_PROJECT_ID]-jenkins-artifacts/$JOB_NAME/$BUILD_NUMBER
```
Post-build actions for Cloud Storage plugin.

Click Save.

Click Build Now to start a new build. The build runs on the Compute Engine instance that you provisioned previously. When the build completes, it uploads the artifact file, build_environment.txt, to the configured Cloud Storage bucket.

In Cloud Shell, view the build artifact using gsutil:
```console
export PROJECT=$(gcloud info --format='value(config.project)')
gsutil cat gs://$PROJECT-jenkins-artifacts/test/2/build_environment.txt
```
Configuring object lifecycle management
You're more likely to access recent build artifacts. To save costs on infrequently accessed objects, use object lifecycle management to move your artifacts from higher-performance storage classes to lower-cost and higher-latency storage classes.

In Cloud Shell, create the lifecycle configuration file to transition all objects to Nearline storage after 30 days and Nearline objects to Coldline storage after 365 days.
```console
cat > artifact-lifecycle.json <<EOF
{
"lifecycle": {
  "rule": [
  {
    "action": {
      "type": "SetStorageClass",
      "storageClass": "NEARLINE"
    },
    "condition": {
      "age": 30,
      "matchesStorageClass": ["MULTI_REGIONAL", "STANDARD", "DURABLE_REDUCED_AVAILABILITY"]
    }
  },
  {
    "action": {
      "type": "SetStorageClass",
      "storageClass": "COLDLINE"
    },
    "condition": {
      "age": 365,
      "matchesStorageClass": ["NEARLINE"]
    }
  }
]
}
}
EOF
```
Upload the configuration file to your artifact storage bucket:
```console
export PROJECT=$(gcloud info --format='value(config.project)')
gsutil lifecycle set artifact-lifecycle.json gs://$PROJECT-jenkins-artifacts
```
Cleaning up
Delete any Jenkins agents that are still running:
```console
gcloud compute instances list --filter=metadata.jclouds-group=ubuntu-1604 --uri | xargs gcloud compute instances delete
```
Using Cloud Deployment Manager, delete the Jenkins instance:
```console
gcloud deployment-manager deployments delete jenkins-1
```
Delete the Cloud Storage bucket:
```console
export PROJECT=$(gcloud info --format='value(config.project)')
gsutil -m rm -r gs://$PROJECT-jenkins-artifacts
```
Delete the service account:
```console
export SA_EMAIL=$(gcloud iam service-accounts list --filter="displayName:jenkins" --format='value(email)')
gcloud iam service-accounts delete $SA_EMAIL
```
Now we will deploy guestbook app with helm from CI/CD with jenkins pipeline.
For this clone below repo:
```console
git clone https://github.com/somud17/CI-CDPipeline
```
