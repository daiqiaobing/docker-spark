搭建分布：

|      主机名      |                部署模块                |                    进程                    |  描述  |
| :-----------: | :--------------------------------: | :--------------------------------------: | :--: |
| hadoop-master |      NameNode、ResourceManager      | NameNode、DFSZKFailoverCroller、ResourceManager、JobHistoryServer |      |
| hadoop-slave1 | NameNode、ResourceManager、Zookeeper | NameNode、DFSZKFailoverCroller、ResourceManager、JobHistoryServer、JurnalNode、QuorumPeerMain |      |
| hadoop-slave2 |   Zookeeper、DataNode、NodeManager   | DataNode、NodeManager、JournalNode、QuorumPeerMain |      |
| hadoop-slave3 |   Zookeeper、DataNode、NodeManager   | DataNode、NodeManager、JournalNode、QuorumPeerMain |      |



