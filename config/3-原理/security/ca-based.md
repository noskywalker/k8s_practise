#多集群证书访问

##新建一个秘钥
openssl genrsa -out developer.key 2048
##新建一个证书前面请求文件(csr)
openssl req -new -key developer.key -out developer.csr -subj "/CN=developer"
##给用户签发证书（私钥是关键）
openssl x509 -req -in developer.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out developer.crt -days 365

##创建绑定，将developer绑定到viewer的role上，具有只读权限
kubectl create clusterrolebinding kubernetes-viewer --clusterrole=view --user=developer

##修改config文件
### 1、命令操作
kubectl config set-cluster developer --server=https://192.168.1.201:6443 --certificate-authority=/etc/kubernetes/pki/ca.crt
kubectl config set-credentials developer --client-certificate=/root/.kube/developer.crt --client-key=/root/.kube/developer.key
kubectl config set-context developer@developer --cluster=developer --namespace=default --user=developer

##切换上下文到不同的集群
kubectl config --kubeconfig=config use-context developer@developer

##只有只读权限，无写权限
### 2、直接修改config

#### 2.1 分别将私钥和客户端证书base64编码
cat developer.crt | base64 --wrap=0 >client-certificate-data
cat developer.key | base64 --wrap=0 >client-key-data

#### 2.2 配置文件
```cfml
apiVersion: v1
clusters:
##################
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://192.168.1.201:6443
  name: developer
##################
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://192.168.1.201:6443
  name: kubernetes
contexts:
##################
- context:
    cluster: developer
    user: developer
  name: developer@developer
##################
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: developer@developer
kind: Config
preferences: {}
users:
##################
- name: developer
  user:
    client-certificate-data: "客户端证书的base64内容"
    client-key-data: "客户端私钥内容"
##################
- name: kubernetes-admin
  user:
    client-certificate-data: ""
    client-key-data: REDACTED

```

##参考多集群配置
https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/