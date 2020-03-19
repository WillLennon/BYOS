kubectl delete deployment byos
kubectl apply -f byos.yaml
kubectl scale deployment byos --replicas 3
kubectl get deployment
kubectl get pod
