#!/bin/bash
bash /etc/init.d/ssh start
nm1="hadoop-master"
nm2="hadoop-slave1"
nodes="hadoop-master hadoop-slave1 hadoop-slave2 hadoop-slave3"
declare -A zookeeper
zookeeper=([1]="hadoop-slave1" [2]="hadoop-slave2" [3]="hadoop-slave3")
journalnodes="hadoop-slave1 hadoop-slave2 hadoop-slave3"

flagFilename="/opt/hadoop/is_dfs_format"
zkFlagFilename="/works/zookeeper/myid"

# 创建所需的文件夹
mkdir_cmd="mkdir -p /works/hadoop/dfs/name && mkdir -p /works/hadoop/dfs/data && mkdir -p /works/hadoop/dfs/namesecondary && mkdir $HADOOP_HOME/logs&&mkdir -p /works/zookeeper"
for name in $nodes;
	do 
		ssh -t -p 22 root@$name ${mkdir_cmd}
	done


# 启动顺序，ZooKeeper -> JournalNode (Hadoop) -> NameNode (Hadoop) -> DataNode (Hadoop) -> 主 ResourceManager/NodeManager (Hadoop)
# -> 备份 ResourceManager (Hadoop) -> ZKFC (Hadoop) -> MapReduce JobHistory (Hadoop) -> 主 Hmaster/HRegionServer (HBase) 
# -> 备份 Hmaster (HBase)

#判断并且写入zookeeper的myid
if [[ ! -f "$flagFilename" ]]; then  
	for key in $(echo ${!zookeeper[*]});
		do  
			cmd="echo ${key} >> ${zkFlagFilename}"
			ssh -t -p 22 root@${zookeeper[$key]}  $cmd			
		done
fi

#启动zoopeeer服务
for key in $(echo ${!zookeeper[*]});
	do  
		cmd="$ZOOKEEPER_HOME/bin/zkServer.sh start"
		echo $cmd
		ssh -t -p 22 root@${zookeeper[$key]}  $cmd
	done

# 如果是首次启动，则格式化nm1，以及nm2
if [[ ! -f "$flagFilename" ]]; then  
	cmd="$HADOOP_HOME/bin/hdfs zkfc -formatZK"
	ssh -t -p 22 root@$nm1 ${cmd}
fi
# 启动journalnode服务
for journalnode in $journalnodes;
	do
		ssh -t -p 22 root@$journalnode  "$HADOOP_HOME/sbin/hadoop-daemon.sh start journalnode"
	done

# 如果是首次启动，则格式化nm1，以及nm2
if [[ ! -f "$flagFilename" ]]; then  
	cmd="$HADOOP_HOME/bin/hdfs namenode -format"
	ssh -t -p 22 root@$nm1 ${cmd}
	# ssh -t -p 22 root@$nm2 "$HADOOP_HOME/bin/hdfs namenode -bootstrapStandby"
	echo '1' >> $flagFilename
fi

# 启动namnode
ssh -t -p 22 root@$nm1 "$HADOOP_HOME/sbin/hadoop-daemon.sh start namenode"
ssh -t -p 22 root@$nm2 "$HADOOP_HOME/sbin/hadoop-daemon.sh start namenode"

# 启动datanode和yarn
ssh -t -p 22 root@$nm1 "$HADOOP_HOME/sbin/hadoop-daemon.sh start datanode&&$HADOOP_HOME/sbin/start-yarn.sh"
ssh -t -p 22 root@$nm2 "$HADOOP_HOME/sbin/yarn-daemon.sh start resourcemanager"

# 启动zkfc
ssh -t -p 22 root@$nm1 "$HADOOP_HOME/sbin/hadoop-daemon.sh start zkfc"
ssh -t -p 22 root@$nm2 "$HADOOP_HOME/sbin/hadoop-daemon.sh start zkfc"
ssh -t -p 22 root@$nm1 "$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver"
ssh -t -p 22 root@$nm2 "$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver"

