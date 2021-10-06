# 创建hadoop环境及执行过程.sh

## 创建基础容器
docker run -d --name=java_ssh_proto --privileged centos:8 /usr/sbin/init
docker exec -it java_ssh_proto bash

## 进入容器后操作
sed -e 's|^mirrorlist=|#mirrorlist=|g' \
         -e 's|^#baseurl=http://mirror.centos.org/$contentdir|baseurl=https://mirrors.ustc.edu.cn/centos|g' \
         -i.bak \
         /etc/yum.repos.d/CentOS-Linux-AppStream.repo \
         /etc/yum.repos.d/CentOS-Linux-BaseOS.repo \
         /etc/yum.repos.d/CentOS-Linux-Extras.repo \
         /etc/yum.repos.d/CentOS-Linux-PowerTools.repo \
         /etc/yum.repos.d/CentOS-Linux-Plus.repo
yum makecache
yum install -y java-1.8.0-openjdk-devel openssh-clients openssh-server
systemctl enable sshd && systemctl start sshd
exit

## 保存镜像
docker stop java_ssh_proto
docker commit java_ssh_proto java_ssh

## 安装hadoop
wget https://archive.apache.org/dist/hadoop/common/hadoop-3.1.4/hadoop-3.1.4.tar.gz
docker run -d --name=hadoop_single --privileged java_ssh /usr/sbin/init
docker cp ./hadoop-3.1.4.tar.gz hadoop_single:/root/
docker exec -it hadoop_single bash

## 进入容器后操作
cd /root
tar -zxf hadoop-3.1.4.tar.gz
mv hadoop-3.1.4 /usr/local/hadoop
echo "export HADOOP_HOME=/usr/local/hadoop" >> /etc/bashrc
source /etc/bashrc
echo "export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin" >> /etc/bashrc 
source /etc/bashrc
echo "export JAVA_HOME=/usr" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
echo "export HADOOP_HOME=/usr/local/hadoop" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
hadoop version

## 配置和启动
adduser hadoop
yum install -y passwd sudo
passwd hadoop # 为hadoop设置密码
# 设置密码，后续密码设为hadoop
chown -R hadoop /usr/local/hadoop
vi /etc/sudoers
# 在"root    ALL=(ALL)       ALL"后添加一行
# "hadoop  ALL=(ALL)       ALL"
exit

## 创建新容器
docker stop hadoop_single
docker commit hadoop_single hadoop_proto
docker run -d --name=hdfs_single --privileged hadoop_proto /usr/sbin/init
docker exec -it hdfs_single su hadoop

## 进入容器后操作
ssh-keygen -t rsa
# 一直按回车
ssh-copy-id hadoop@172.17.0.2
ip addr | grep 172 # 获取ip
cd $HADOOP_HOME/etc/hadoop
# 在 core-site.xml <configure>中添加
# <property>
#     <name>fs.defaultFS</name>
#     <value>hdfs://<你的IP>:9000</value>
# </property>
# 
# 在 hdfs-site.xml <configure>中添加
# <property>
#     <name>dfs.replication</name>
#     <value>1</value>
# </property>
hdfs namenode -format
start-dfs.sh
jps # 查看Java进程
cd /home/hadoop

## 开始测试
mkdir /home/hadoop/HW2
mkdir /home/hadoop/HW2/input
mkdir /home/hadoop/HW2/script
mkdir /home/hadoop/HW2/output
exit

docker cp ./mapper.py hdfs_single:/home/hadoop/HW2/script
docker cp ./reducer.py hdfs_single:/home/hadoop/HW2/script
docker cp ./input hdfs_single:/home/hadoop/HW2
docker exec -it hdfs_single su hadoop

## 进入容器后操作
cd /home/hadoop/HW2/script
hdfs hdfs dfs -put ../input /
# 错误 hadoop jar /usr/local/hadoop/share/hadoop/tools/lib/hadoop-streaming-3.1.4.jar -file ./script/mapper.py -mapper ./script/mapper.py -file ./script/reducer.py -reducer ./script/reducer.py -input /input/* -output /output-first
hadoop jar /usr/local/hadoop/share/hadoop/tools/lib/hadoop-streaming-3.1.4.jar -file mapper.py -mapper "python mapper.py" -file reducer.py -reducer "python reducer.py" -input /input/* -output /output-first
cd ..
hdfs dfs -get /output-first/* /home/hadoop/HW2/output
exit

## 关闭容器
docker stop hdfs_single