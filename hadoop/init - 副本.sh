#!/bin/bash
bash /etc/init.d/ssh start
hostname=""
master="hadoop-master"
nodes="hadoop-master,hadoop-slave1,hadoop-slave2,hadoop-slave3"
zkServerHosts="hadoop-slave1,hadoop-slave2,hadoop-slave3"
dataHosts="hadoop-slave2,hadoop-slave3"
nnHosts="hadoop-master,hadoop-slave1"

flagFilename="/opt/hadoop/is_dfs_format"
zkFlagFilename="/works/zookeeper/myid"

zkServer="hadoop-slave1;hadoop-slave2;hadoop-slave3"
nm2Server="hadoop-slave1"

# 启动顺序，ZooKeeper -> JournalNode (Hadoop) -> NameNode (Hadoop) -> DataNode (Hadoop) -> 主 ResourceManager/NodeManager (Hadoop)
# -> 备份 ResourceManager (Hadoop) -> ZKFC (Hadoop) -> MapReduce JobHistory (Hadoop) -> 主 Hmaster/HRegionServer (HBase) 
# -> 备份 Hmaster (HBase)

#写入zookeeper的myid
for name in $zkServerHosts;
	do 
		ssh -t -p 22 root@$name "echo ${myline#*"hadoop-slave"} >> ${zkFlagFilename}"
	done


while read myline
	do	
	if [[  $nodes == *$myline* ]]; then
		hostname=$myline
		if [[ $zkServerHosts == *$hostname* ]]; then
			echo ${myline#*"hadoop-slave"} >> $zkFlagFilename
		fi
		break
	fi
done < /etc/hostname

# 创建所需的文件夹
mkdir -p /works/hadoop/dfs/name && mkdir -p /works/hadoop/dfs/data && mkdir -p /works/hadoop/dfs/namesecondary && mkdir $HADOOP_HOME/logs
mkdir -p /works/zookeeper

if [[ $hostname == *$master* ]];	then
	#建立HDFS目录，日志目录. 格式化NameNode
	# 判断namenode是否被格式化过，如果格式化了，就不再格式化，否则就格式化
	if [[ ! -f "$flagFilename" ]]; then  
		$HADOOP_HOME/bin/hdfs zkfc -formatZK  
		$HADOOP_HOME/bin/hdfs namenode -format  # namenode格式化
		echo "true" >> $flagFilename		
	fi
	bash $HADOOP_HOME/sbin/start-all.sh
	bash $HADOOP_HOME/sbin/hadoop-daemon.sh start zkfc
	bash $HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver
fi

if [[ $zkServer == *$hostname* ]];	then
	if [[ ! -f "$zkFlagFilename" ]]; then  
		echo ${hostname#*"hadoop-slave"} >> $zkFlagFilename
	fi
	bash $ZOOKEEPER_HOME/bin/zkServer.sh start
	bash $HADOOP_HOME/sbin/hadoop-daemon.sh start journalnode
	if [[ $nm2Server == *$hostname* ]];	then
		bash $HADOOP_HOME/bin/hdfs namenode -bootstrapStandby
		bash $HADOOP_HOME/sbin/hadoop-daemon.sh restart namenode
		bash $HADOOP_HOME/sbin/yarn-daemon.sh start resourcemanager
		bash $HADOOP_HOME/sbin/hadoop-daemon.sh start zkfc
	fi		 
fi
