import os
import random

MYPGHOME = "/home/masahiko/pgsql/master"

class PostgresNode:
    def __init__(self, name, init = False):
        self.name = name
        self.port = 5432 + random.randint(1, 1000)
        self.pgdata = MYPGHOME + "/" + name + "/"
        self.pgbin = MYPGHOME + "/" + "bin/"
        self.pgbackup = MYPGHOME + "/" + name + "/backup/"
        self.enable_repl = False

        # Do initdb as well
        if init:
            self.init()

    # Append configuration to config file
    def append_conf(self, settings, conf = 'postgresql.conf'):
        f = open(self.pgdata + conf, 'a')
        f.write(settings)
        f.close()

    # Take backup
    def backup(self, name):
        backup_dir = self.pgbackup + name
        os.mkdir(backup_dir)
        os.system(self.pgbin + "pg_basebackup -D " + backup_dir + " -p " + str(self.port))
        return name

    # initialize as a standby
    def init_as_standby(self, backup_name, master):
        if os.path.exists(self.pgdata):
            self.stop(imm = True, wait = True)
            os.system("rm -rf " + self.pgdata)

        # Check backup name
        backup_dir = master.pgbackup + backup_name
        if not os.path.exists(backup_dir):
            print "Invalid backup name : \"%s\"" % backup_name
            raise

        # cp pgdata directory instead of initdb
        os.system("cp -r " + master.pgbackup + "/" + backup_name + " " + self.pgdata)
        os.chmod(self.pgdata, 0700)
        self.append_conf('port = ' + str(self.port) + '\n' + 
                         'wal_level = replica \n' + 
                         'max_wal_senders = 10 \n' +
                         'max_replication_slots = 10 \n' +
                         'hot_standby = on\n')
        self.append_conf('local   replication     masahiko                                trust\n', 'pg_hba.conf')
        self.append_conf('standby_mode = on\n' +
                         "primary_conninfo = 'port=" + str(master.port) + " dbname=postgres'\n", 'recovery.conf')

    # Do init db
    def init(self, replication = False):
        if os.path.exists(self.pgdata):
            self.stop(imm = True, wait = True)
            os.system("rm -rf " + self.pgdata)

        os.system(self.pgbin + "initdb -E UTF8 --no-locale -D " + self.pgdata)
        os.mkdir(self.pgbackup)
        self.append_conf('port = ' + str(self.port) + '\n' + 
                         'wal_level = replica \n' + 
                         'max_wal_senders = 10 \n' +
                         'max_replication_slots = 10 \n')
        self.append_conf('local   replication     masahiko                                trust\n', 'pg_hba.conf')

    # Start node
    def start(self, wait = True):
        if wait:
            wait_flag = " -w "
        os.system(self.pgbin + "pg_ctl start -D " + self.pgdata + wait_flag)

    # Stop node
    def stop(self, wait = True, imm = False):
        wait_flag = " -w " if wait else ""
        imm_flag = " -mi " if imm else ""
        os.system(self.pgbin + "pg_ctl stop -D " + self.pgdata + wait_flag + imm_flag)

    # Restart node
    def restart(self, wait = True, imm = False):
        wait_flag = " -w " if wait else ""
        imm_flag = " mi " if imm else ""
        os.system(self.pgbin + "pg_ctl restart -D " + self.pgdata + wait_flag + imm_flag)

    # Reload node
    def reload(self):
        os.system(self.pgbin + "pg_ctl reload -D " + self.pgdata)

    # Promote node
    def promote(self):
        os.system(self.pgbin + "pg_ctl promote -D " + self.pgdata)

    def show(self):
        print self.name
        print self.port
        print self.pgdata
        print self.pgbin

master = PostgresNode("data")
master.init(replication = True)
master.start()
backup = master.backup("hoge_backup")

standby = PostgresNode("standby")
standby.init_as_standby(backup, master)
standby.start()
