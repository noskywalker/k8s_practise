#创建一个sa用于登录dashboard和pod访问
kubectl create serviceaccount admin-role -n kube-system

#绑定角色
kubectl create clusterrolebinding admin-role-binding --clusterrole=cluster-admin --serviceaccount=kube-system:admin-role

#获取token
kubectl get secret `kubectl get secret -n kube-system | grep admin-role | awk '{print $1}'` -o jsonpath={.data.token} -n kube-system | base64 -d

#apiserver请求
curl -k  --header "Authorization: Bearer ${token}" https://192.168.1.201:6443/api
curl -cacert /etc/kubernetes/pki/ca.crt ---header "Authorization: Bearer ${token}" https://192.168.1.201:6443/api