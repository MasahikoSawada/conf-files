PGBASE=/home/masahiko/pgsql

# Available functions are;
# - start <version> [...]
# - restart <version> [...]
# - stop <version> [...]
# - install_pg <version>
# - init <version> [...]
# - full_setup <version>
# - basebackup <version> <directory name>
# - clean <version> [...]
# - sync_rep [version] [num]
# - rebuld <version> <options>
# - pp { [version] ...} [options for psql including -c option]
# - p [version]
# - list

function start()
{
    P=`pwd`

    for OPT in "$@"
    do
	VERSION=`s_to_version $OPT`
	PORT=`s_to_port $OPT`
	DATA=`s_to_dir $OPT`
	cd $PGBASE/$VERSION || return

	bin/pg_ctl start -c -D $DATA -o "-p $PORT" -c
    done

    cd $P
}

function restart()
{
    P=`pwd`
    for OPT in "$@"
    do
	VERSION=`s_to_version $OPT`
	DATA=`s_to_dir $OPT`
	PORT=`s_to_port $OPT`
	cd $PGBASE/$VERSION || return

	bin/pg_ctl restart -c -D $DATA -mf -c
    done
    cd $P
}

function clean()
{
    P=`pwd`
    for OPT in "$@"
    do
	VERSION=`s_to_version $OPT`
	DATA=`s_to_dir $OPT`
	PORT=`s_to_port $OPT`
	cd $PGBASE/$VERSION || break

	rm -rf $DATA
    done
    cd $P
}

function basebackup()
{
    P=`pwd`

    if [ $# -ne 2 ];then
	echo "2 options required; version and backup directory name"
	return
    fi

    VERSION=`s_to_version $1`
    PORT=`s_to_port $OPT`
    DATA=`s_to_dir $2`

    cd $PGBASE/$VERSION || return
    bin/pg_basebackup -D $DATA -p $PORT -P

    cd $P
}

function stop()
{
    P=`pwd`
    for OPT in "$@"
    do
	VERSION=`s_to_version $OPT`
	DATA=`s_to_dir $OPT`
	cd $PGBASE/$VERSION || break
	bin/pg_ctl stop -D $DATA -mf
    done
    cd $P
}

function install_pg()
{
    VERSION=`s_to_version $1`
    P=`pwd`

    EXISTS=`ls -1 $PGBASE/$VERSION`
    if [ "$EXISTS" != "" ]; then
	echo "$VERSION already exits."
	return 1
    fi
    
    wget "https://ftp.postgresql.org/pub/source/v${VERSION}/postgresql-${VERSION}.tar.bz2"
    tar xjf postgresql-${VERSION}.tar.bz2 -C $PGBASE/source
    rm postgresql-${VERSION}.tar.bz2

    cd $P
}

function init()
{
    P=`pwd`

    for OPT in "$@"
    do
	VERSION=`s_to_version $OPT`
	DATA=`s_to_dir $OPT`
	SETTING=`get_setting $VERSION`
	CONF=$DATA/postgresql.conf
	cd $PGBASE/$VERSION || break
	rm -rf $DATA
	bin/initdb -D $DATA -E UTF8 --no-locale
	echo -e "$SETTING" >> $CONF
    done
    cd $P
}

function full_setup()
{
    VERSION=`s_to_version $1`
    ORIG_PWD=`pwd`

    install_pg $1
    
    cd $PGBASE/source/postgresql-${VERSION} || return
    ./configure --prefix=$PGBASE/$VERSION --enable-debug --enable-cassert CFLAGS=-g
    make -j 4 -s
    make install -j 4 -s

    init $1
    
    cd ${ORIG_PWD}
}

function rebuild()
{
    VERSION=`s_to_version $1`
    shift
    OPTIONS=$@
    ORIG_PWD=`pwd`

    cd $PGBASE/source/postgresql-${VERSION} || return
    ./configure --prefix=$PGBASE/$VERSION --enable-debug --enable-cassert ${OPTIONS} CFLAGS=-g

    make clean -j 4 -s
    make -j 4 -s
    make install -j 4 -s

    cd ${ORIG_PWD}
}

function pp()
{
    unset command_opt
    unset before_command
    unset options

    options=""
    versions=()
    command_opt=""
    before_command=""
    command=""
    for OPT in "$@"
    do
	if [ "$before_command" == "true" ];then
	    command="\"$OPT\""
	    before_command="false"
	    continue
	fi

	case $OPT in
	    [0-9][0-9][0-9] |  [0-9][0-9][0-9][0-9] | 'master' | 'rmaster'| 'orig' | node[0-9] | shd[0-9] | pri)
		versions=("${versions[@]}" "$OPT")
		shift
		;;
	    '-c')
		command_opt="-c"
		before_command="true"
		shift
		;;
	    *)
		options="$options $OPT"
		;;
	esac
    done

    if [ "$versions" == "" ];then
	versions=("master")
    fi

    for version in "${versions[@]}"
    do
	VERSION=`s_to_version $version`
	PORT=`s_to_port $version`

	echo "==== $VERSION($version) ===="
	c="$PGBASE/$VERSION/bin/psql -d postgres -p $PORT $options $command_opt $command"
	eval "$c"
    done
}

function p()
{
    unset command_opt
    unset before_command
    unset options
    unset command

    options=""
    version=""
    command_opt=""
    before_command=""
    command=""

    for OPT in "$@"
    do
	if [ "$before_command" == "true" ];then
	    command="\"$OPT\""
	    before_command="false"
	    continue
	fi

	case $OPT in
	    [0-9][0-9][0-9] |  [0-9][0-9][0-9][0-9] | 'master' | 'rmaster' | 'orig' | node[0-9] | shd[0-9] | pri)
		version="$OPT"
		shift
		;;
	    '-c')
		command_opt="-c"
		before_command="true"
		shift
		;;
	    *)
		options="$options $OPT"
		;;
	esac
    done

    if [ "$version" == "" ];then
	version="master"
    fi

    VERSION=`s_to_version $version`
    PORT=`s_to_port $version`

    c="$PGBASE/$VERSION/bin/psql -d postgres -p $PORT $options $command_opt $command"
    eval "$c"
}

function sync_rep()
{

    if [ $# -ne 2 ];then
	echo "Required 2 options; the number of slaves and the replication type(p/l)"
	return
    fi

    SLALVE_NUM=$1
    REPL_TYPE=$2

    if [ "$REPL_TYPE" != "p" -a "$REPL_TYPE" != "l" ];then
	echo "invalid replication type : \"${REPL_TYPE}\""
	return
    fi
	
    P=`pwd`
    cd $PGBASE/$VERSION

    # Stop and remove all servers
    stop rmaster
    clean rmaster
    for i in `seq 1 $SLAVE_NUM`
    do
	stop node${i}
	clean node${i}
    done

    if [ "$REPL_TYPE" == "l" ];then # logical replication
	# Initialize all servers
	init rmaster
	start rmaster
	
	for i in `seq 1 $SLAVE_NUM`
	do
	    init node${i}
	    start node${i}
	done
    elif [ "$REPL_TYPE" == "p" ];then # physical repliction
	echo "hgoe"
    fi
    cd $P
}

function list()
{
    ls $PGBASE/
}


##################################### Common functions #####################################

# Convert (version string) -> (database cluster directory name)
function s_to_dir()
{
    case $1 in
	rmaster)
	    echo "master"
	    return
	    ;;
	node[0-9])
	    echo $1
	    return
	    ;;
	rmaster)
	    echo $1
	    return
	    ;;
	master | [0-9]* | orig)
	    echo "data"
	    return
	    ;;
	*)
	    echo $1
	    return
    esac
}

# Convert (version string like 950) -> (comma-separated version number, which is also used as the directory name)
function s_to_version()
{
    case $1 in
	master|rmaster|node[0-9]|shd[0-9]|pri)
	    echo "master"
	    return
	    ;;
	orig)
	    echo "orig"
	    return
	    ;;
	*)
	    VERSION_1=`echo $1 | cut -b1`
	    if [ "$VERSION_1" == "1" ];then

		# PostgreSQL 10 or later supports two-number version style.
		# Perhaps it's enough to check whether the first number is 1 or not
		# until PostgreSQL 20.0 released.
		VERSION_1=`echo $1 | cut -b1-2`
		VERSION_2=`echo $1 | cut -b3`
		echo "${VERSION_1}.${VERSION_2}"
	    else
		VERSION_2=`echo $1 | cut -b2`
		VERSION_3=`echo $1 | cut -b3-`
		echo "${VERSION_1}.${VERSION_2}.${VERSION_3}"
	    fi
	    return
    esac
}

# Convert (version number) -> (port number)
function s_to_port()
{
    case $1 in
	master)
	    echo "5432"
	    return
	    ;;
	rmaster)
	    echo "5550"
	    return
	    ;;
	orig)
	    echo "9999"
	    return
	    ;;
	node[0-9])
	    node_id=`echo $1 | cut -b 5`
	    echo "555${node_id}"
	    return
	    ;;
	shd[0-9])
	    shd_id=`echo $1 | cut -b 4`
	    echo "444${shd_id}"
	    return
	    ;;
	pri)
	    echo "4440"
	    return
	    ;;
	*)
	    echo "5$1"
	    return
    esac
}

function get_conf()
{
    DATA=`s_to_dir $1`
    echo ${PGBASE}/${DATA}/postgresl.conf
    return
}

# Test function of conversion
function conv_test()
{
    VERSION=`s_to_version $1`
    PORT=`s_to_port $1`
    DIR=`s_to_dir $1`

    echo "Argument = $1"
    echo "version = $VERSION"
    echo "Dir = $DIR"
    echo "port = $PORT"
}

# Get setting string using version identifier
function get_setting()
{
    r=""
    case $1 in
	master|orig)
	    r="
wal_level = logical\n
max_wal_size = 10GB\n
checkpoint_timeout = 1h\n
wal_sender_timeout = 0\n
wal_receiver_timeout = 0\n
"
	    ;;
	9.6.*|10.*)
	    r="
max_wal_size = 10GB\n
checkpoint_timeout = 1h\n
"
	    ;;
    esac

    # Add common setting
    r=$r"
max_prepared_transactions = 10\n
log_line_prefix = '%m [%p] '\n
"
    echo -e $r
    unset s
}
