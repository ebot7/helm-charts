# Ebot-7 Base Helm Chart
This is a sample e-bot7 helm chart repository. In order to use and deploy this chart, you need to install helm command line on your local machine: https://helm.sh/

Obviously you also need a working EKS K8S cluster with the related kubeconfig file usually in `~/.kube/config`


Add this chart to your local helm chart repositories:
```bash
$ helm repo add eb7-base https://ebot7.github.io/helm-charts
$ helm repo update
```


You can try to check if your templates are working correct, you can try dry-run as follows
```bash
$ helm install --dry-run eb7-base charts/eb7-base