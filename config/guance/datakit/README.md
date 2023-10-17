
$ helm repo add datakit https://pubrepo.guance.com/chartrepo/datakit
$ helm install datakit-service -n datakit --set dataway_url="https://openway.guance.com?token=<your-token>" --create-namespace