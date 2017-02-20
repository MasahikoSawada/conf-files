import os
import random
import re

# versionstr is like "935", "9112" and "101"
# version is "9.3.5", "9.1.12" and "10.1"
def versionstr_to_version(string):
    # HEAD
    if string == "master":
        return "master"
    # version 7 - 9
    elif string[0] in {'7', '8', '9'}:
        major_1 = string[0]
        major_2 = string[1]
        minor = string[2:]
        return major_1 + "." + major_2 + "." + minor
    # version 10 -
    else:
        major = string[0:2]
        minor = string[2:]
        return major + "." + minor

# versionstr is like "935", "9112" and "101"
# port would be like "5935", "59112" and "5101"
def versionstr_to_port(string):
    # HEAD
    if string == "master":
        return 5432
    # version 7 - 9
    else:
        return "5" + string

def name_to_port(string, port):
    if string == "data":
        return port
    elif string == "master":
        return 5432
    elif string == "rmaster":
        return 5550
    elif re.match(r"node[0-9]$", string):
        node_id = string[4]
        return "555" + node_id
    elif string == "pri":
        return 4440
    elif re.match(r"shd[0-9]$", string):
        shd_id = string[3]
        return "444" + shd_id
    else:
        return port

class PostgresNode:
    def __init__(self, name = "data", init = False, port = 0):
        self.name = name
        if port == 0:
            self.port = versionstr_to_port(PGVERSION) # get port from version num
            self.port = name_to_port(self.name, self.port) # if given special data name, port is changed
        else:
            self.port = port
        self.pghome = MYPGHOME + versionstr_to_version(PGVERSION)
        self.pgdata = self.pghome + "/" + name + "/"
        self.pgbin = self.pghome + "/" + "bin/"
        self.pgbackup = self.pghome + "/" + name + "/backup/"
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

    # psql
    def psql(self, sql, dbname='postgres', psqlrc=True):
        if psqlrc:
            os.system(self.pgbin + "psql -d " + dbname + " -p " + str(self.port) + " -c \"" + sql + "\"")
        else:
            os.system(self.pgbin + "psql -d " + dbname + " -p " + str(self.port) + " -Xc \"" + sql + "\"")

    def show(self):
        print "==================== \"%s\" Node Info ====================" % self.name
        print "VERSION\t\t:\t%s" % PGVERSION
        print "MYPGHOME\t:\t%s" % MYPGHOME
        print "name\t\t:\t%s" % self.name
        print "port\t\t:\t%s" % self.port
        print "pghome\t\t:\t%s" % self.pghome
        print "pgdata\t\t:\t%s" % self.pgdata
        print "pgbin\t\t:\t%s" % self.pgbin
        print "pgbackup\t:\t%s" % self.pgbackup
        print "========================================================="

MYPGHOME = "/home/masahiko/pgsql/"
PGVERSION = os.environ.get("MY_PGVERSION")

#
# Sample code.
#
#master = PostgresNode("data")
#master.init(replication = True)
#master.start()
#backup = master.backup("hoge_backup")
#
#standby = PostgresNode("standby")
#standby.init_as_standby(backup, master)
#standby.start()
#
