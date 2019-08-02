resource "google_compute_instance" "jenkube" {

        ## for a setup having multiple instances of the same type, you can do
        ## the following, there would be 2 instances of the same configuration
        ## provisioned
        # count        = 2
        # name         = "${var.instance-name}-${count.index}"
        name           = "jenkube1"
        machine_type   = "n1-standard-1"
        zone           = "us-central1-a"

        boot_disk {
                initialize_params {
                        image = "instant-node-244015/jenkins-agent-1563945899"
                }
        }

        tags = [
                "${var.network}-firewall-ssh",
                "${var.network}-firewall-http",
                "${var.network}-firewall-https",
                "${var.network}-firewall-icmp",
        ]

        metadata = {
                        ssh-keys = "../gce/id_rsa.pub"
                        hostname = "instance.jenkube.org"
        }

        provisioner "file" {
                source = "../gce/installscript.sh"
                destination = "/tmp/installscript.sh"
                connection {
							user        = "somu_unixlinux"
                                private_key = "${file("id_rsa")}"
                                host        = "${google_compute_address.static.address}"
                                script_path = "/tmp/installscript.sh"
                                timeout     = "60s"
                        }
        }

        provisioner "remote-exec" {
                        inline = [
                                "echo = ============== Hello, here we GO ===============",
                                "sudo apt-get update",
                                "wget -q -O - https://get.k8s.io | bash",
                                "cd kubernetes/cluster/",
                                "chmod +x kube-up.sh",
                                "./kube-up.sh -y",
                                "cp -p kubectl.sh /usr/bin/",
                                "curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > install-helm.sh",
                                "chmod +x install-helm.sh",
                                "./install-helm.sh",
                                "helm init",
                                "kubectl -n kube-system create serviceaccount tiller",
                                "kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller",
                                "helm init --service-account tiller",
                                "helm init --service-account tiller --upgrade",
                                "kubectl get pods --namespace kube-system",
                                "helm repo add my-repo https://ibm.github.io/helm101/"

                        ]
                        connection {
                                type        = "ssh"
                                user        = "somu_unixlinux"
                                private_key = "${file("id_rsa")}"
								host        = "${google_compute_address.static.address}"
                                script_path = "/tmp/installscript.sh"
                                timeout     = "30s"
                                }
                }

        network_interface {
                network = "default"
                access_config {
                      nat_ip = "${google_compute_address.static.address}"
                    }
        }

        service_account {
                scopes = ["userinfo-email", "compute-rw", "storage-rw"]
        }
}

resource "google_compute_address" "static" {
  name = "ipv4-address"
}
								