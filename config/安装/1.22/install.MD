curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo

yum install -y yum-utils device-mapper-persistent-data lvm2

yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

cat <<EOF > /etc/yum.repos.d/kubernetes.repo

[kubernetes]

name=Kubernetes

baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/

enabled=1

gpgcheck=1

repo_gpgcheck=1

gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg

EOF

sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo

yum install wget jq psmisc vim net-tools telnet yum-utils device-mapper-persistent-data lvm2 git -y

systemctl disable --now firewalld 

systemctl disable --now dnsmasq

systemctl disable --now NetworkManager



setenforce 0

sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/sysconfig/selinux

sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config

swapoff -a && sysctl -w vm.swappiness=0

sed -ri '/^[^#]*swap/s@^@#@' /etc/fstab

ulimit -SHn 65535

echo '* soft nofile 65536' >>/etc/security/limits.conf
echo '* hard nofile 131072' >>/etc/security/limits.conf
echo '* soft nproc 65535' >>/etc/security/limits.conf
echo '* hard nproc 655350' >>/etc/security/limits.conf
echo '* soft memlock unlimited' >>/etc/security/limits.conf
echo '* hard memlock unlimited' >>/etc/security/limits.conf

## 升级系统
yum update -y --exclude=kernel* && reboot

## --------------------------------------------
cd /root

wget http://193.49.22.109/elrepo/kernel/el7/x86_64/RPMS/kernel-ml-devel-4.19.12-1.el7.elrepo.x86_64.rpm

wget http://193.49.22.109/elrepo/kernel/el7/x86_64/RPMS/kernel-ml-4.19.12-1.el7.elrepo.x86_64.rpm

cd /root && yum localinstall -y kernel-ml*
grub2-set-default 0 && grub2-mkconfig -o /etc/grub2.cfg
grubby --args="user_namespace.enable=1" --update-kernel="$(grubby --default-kernel)"

## 启用ipvs

yum install ipvsadm ipset sysstat conntrack libseccomp -y
modprobe -- ip_vs

modprobe -- ip_vs_rr

modprobe -- ip_vs_wrr

modprobe -- ip_vs_sh

modprobe -- nf_conntrack
                                                          
echo 'ip_vs' >>/etc/modules-load.d/ipvs.conf              
                                                          
echo 'ip_vs_lc' >>/etc/modules-load.d/ipvs.conf           
                                                          
echo 'ip_vs_wlc' >>/etc/modules-load.d/ipvs.conf          
                                                          
echo 'ip_vs_rr' >>/etc/modules-load.d/ipvs.conf           
                                                          
echo 'ip_vs_wrr' >>/etc/modules-load.d/ipvs.conf          
                                                          
echo 'ip_vs_lblc' >>/etc/modules-load.d/ipvs.conf         
                                                          
echo 'ip_vs_lblcr' >>/etc/modules-load.d/ipvs.conf        
                                                          
echo 'ip_vs_dh' >>/etc/modules-load.d/ipvs.conf           
                                                          
echo 'ip_vs_sh' >>/etc/modules-load.d/ipvs.conf           
                                                          
echo 'ip_vs_fo' >>/etc/modules-load.d/ipvs.conf           
                                                          
echo 'ip_vs_nq' >>/etc/modules-load.d/ipvs.conf           
                                                          
echo 'ip_vs_sed' >>/etc/modules-load.d/ipvs.conf          
                                                          
echo 'ip_vs_ftp' >>/etc/modules-load.d/ipvs.conf          
                                                          
echo 'ip_vs_sh' >>/etc/modules-load.d/ipvs.conf           
                                                          
echo 'nf_conntrack' >>/etc/modules-load.d/ipvs.conf       
                                                          
echo 'ip_tables' >>/etc/modules-load.d/ipvs.conf          
                                                          
echo 'ip_set' >>/etc/modules-load.d/ipvs.conf             
                                                          
echo 'xt_set' >>/etc/modules-load.d/ipvs.conf             
                                                          
echo 'ipt_set' >>/etc/modules-load.d/ipvs.conf            
                                                          
echo 'ipt_rpfilter' >>/etc/modules-load.d/ipvs.conf       
                                                          
echo 'ipt_REJECT' >>/etc/modules-load.d/ipvs.conf         
                                                          
echo 'ipip' >>/etc/modules-load.d/ipvs.conf               

systemctl enable --now systemd-modules-load.service

## 配置内核参数
cat <<EOF > /etc/sysctl.d/k8s.conf

net.ipv4.ip_forward = 1

net.bridge.bridge-nf-call-iptables = 1

net.bridge.bridge-nf-call-ip6tables = 1

fs.may_detach_mounts = 1

net.ipv4.conf.all.route_localnet = 1

vm.overcommit_memory=1

vm.panic_on_oom=0

fs.inotify.max_user_watches=89100

fs.file-max=52706963

fs.nr_open=52706963

net.netfilter.nf_conntrack_max=2310720



net.ipv4.tcp_keepalive_time = 600

net.ipv4.tcp_keepalive_probes = 3

net.ipv4.tcp_keepalive_intvl =15

net.ipv4.tcp_max_tw_buckets = 36000

net.ipv4.tcp_tw_reuse = 1

net.ipv4.tcp_max_orphans = 327680

net.ipv4.tcp_orphan_retries = 3

net.ipv4.tcp_syncookies = 1

net.ipv4.tcp_max_syn_backlog = 16384

net.ipv4.ip_conntrack_max = 65536

net.ipv4.tcp_max_syn_backlog = 16384

net.ipv4.tcp_timestamps = 0

net.core.somaxconn = 16384

EOF

sysctl --system

reboot

## 查看内核配置是否生效--------------------------------------------------
lsmod | grep --color=auto -e ip_vs -e nf_conntrack

## 安装docker

yum install docker-ce-19.03.* docker-ce-cli-19.03.* -y

## 配置cgroups驱动
mkdir /etc/docker

cat > /etc/docker/daemon.json <<EOF

{

  "exec-opts": ["native.cgroupdriver=systemd"]

}

EOF

systemctl daemon-reload && systemctl enable --now docker

##安装k8s
yum install kubeadm-1.22* kubelet-1.22* kubectl-1.22* -y

## 可选配置，配置阿里云的pause镜像

cat >/etc/sysconfig/kubelet<<EOF

KUBELET_EXTRA_ARGS="--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.5"

EOF

systemctl daemon-reload

systemctl enable --now kubelet


## 集群初始化

cat >/EOF>/root/cfg.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta2
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: 7t2weq.bjbawausm0jaxury
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 10.103.236.201
  bindPort: 6443
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  name: vm81
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
---
apiServer:
  certSANs:
  - vm82
  - vm83
  - vm81
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta2
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controlPlaneEndpoint: 10.103.236.236:16443
controllerManager: {}
dns:
  type: CoreDNS
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers
kind: ClusterConfiguration
kubernetesVersion: v1.22.0 # 更改此处的版本号和kubeadm version一致
networking:
  dnsDomain: cluster.local
  podSubnet: 172.16.0.0/12
  serviceSubnet: 192.168.0.0/16
scheduler: {}
EOF


kubeadm config migrate --old-config cfg.yaml --new-config new.yaml

##提前下载镜像
kubeadm config images pull --config /root/new.yaml


### master初始化

kubeadm init --config /root/new.yaml  --upload-certs