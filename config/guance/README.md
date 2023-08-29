

helm upgrade datakit . -n datakit -f values.yaml

kubectl describe cm datakit-conf -n datakit

