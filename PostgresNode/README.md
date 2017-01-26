# PostgresNode
Postgres script in Python

# Example
Example of building streaming replication with one standby server.

```:python
master = Postgres("master", init = True)
master.start()
backup_name = master.backup("hoge_backup")
standby = Postgres("standby")
standby.init_as_standby(backup_name, master)
standby.start()
```

# Version assignment

We can specify paricular port number for PostgresNode when create instance by giving port number to constracter.
But if not give it, port number is selected with following sequence.

```
1. if port is not given
  |
  - 1. get port number from version number.
      * "master" version will be 5432
      * "9.3.2" versin will be 5932
      * "10.1" version will be 5101
    2. change port number if node name is special name.
      * "rmaster" will be 5550
      * "node1" will be 5551
      * "node2" will be 5552
      * "pri" will be 4440
      * "shd1" will be 4441
2. else (i.g. port is not given)
  |
  - Set given port number.
```