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
