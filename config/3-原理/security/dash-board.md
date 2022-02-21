kubectl create serviceaccount dashboard-reader

kubectl create clusterrolebinding dashboard-reader --clusterrole=view --serviceaccount=default:dashboard-reader

kubectl get secret `kubectl get secret -n default | grep dashboard-reader | awk '{print $1}'` -o jsonpath={.data.token} -n default | base64 -d