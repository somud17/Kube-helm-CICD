# Kubernetes monitoring and alerting in less than 5 minutes

Kubelet natively exposes cadvisor metrics at https://kubernetes.default.svc:443/api/v1/nodes/{node-name}/proxy/metrics/cadvisor and we can use a prometheus server to scrape this endpoint. These metrics can then be visualized using Grafana. Metrics can alse be scraped from pods and service endpoints if they expose metircs on /metrics (as in the case of nginx-ingress-controller), alternatively you can sepcify custom scrape target in the prometheus config map.

Some Important metrics which are not exposed by the kubelet, can be fetched using kube-state-metrics and then pulled by prometheus.

Setup:

1. If you have not already deployed the nginx-ingress controller then
    - Uncomment `type: LoadBalancer` field in Alertmanager, Prometheus and Grafana Services.
2. Deployment:
        - Deploy Alertmanger: kubectl apply -f k8s/monitoring/alertmanager
        - Deploy Prometheus: kubectl apply -f k8s/monitoring/prometheus
        - Deploy Kube-state-metrics: kubectl apply -f k8s/monitoring/kube-state-metrics
        - Deploy Node-Exporter: kubectl apply -f k8s/monitoring/node-exporter
        - Deploy Grafana: kubectl apply -f k8s/monitoring/grafana
        - Deploy the Ingress: kubectl apply -f k8s/monitoring/ingress.yaml

3. Once grafana is running:
        - Access grafana at grafana.yourdomain.com in case of Ingress or http://<LB-IP>:3000 in case of type: LoadBalancer
        - Add DataSource:
          - Name: DS_PROMETHEUS - Type: Prometheus
          - URL: http://prometheus-service:8080
          - Save and Test. You can now build your custon dashboards or simply import dashboards from grafana.net. Dasboard #315 and #1471 are good to start with.
          - You can also import the dashboards from k8s/monitoring/dashboards

Note:

1. A Cluster-binding role for prometheus is already being created by the config. The role currently has admin permissions, however you can modify it to a viewer role only.
2. if you need to update the prometheus config, it can be reloaded by making an api call to the prometheus server. `curl -XPOST http://<prom-service>:<prom-port>/-/reload`
3. Some basic alering rules are defined in the prometheus rules file which can be updated before deploying. You can also add more rules under the same groups or create new ones.
4. Before deploying prometheus please create GCP PD-SSD or AWS EBS Volume of size 250Gi or more, and name it `pd-ssd-disk-01`.
5. Please update `00-alertmanager-configmap.yaml` to reflect correct api_url for Slack and VictorOps. You can additionally add more receievers. Ref:  https://prometheus.io/docs/alerting/configuration/
