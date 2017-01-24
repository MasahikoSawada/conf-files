PGBASE=/home/masahiko/pgsql

# Available functions are;
# - start [version]
# - restart [version]
# - stop [version
# - install_pg [version]
# - init [version]
# - full_setup [version]
# - sync_rep [version] [num]
# - rebuld [version] [options]
# - pp { [version] ...} [options for psql including -c option]
# - p [version]
# - list

function error()
{
    echo "[ERROR] : " $@
}

function start()
{
    VERSION=`s_to_version $1`
    PORT=`s_to_port $1`
    DATA=`s_to_dir $1`
    P=`pwd`
    cd $PGBASE/$VERSION

    bin/pg_ctl start -D $DATA -o "-p $PORT" -c
    cd $P
}

function restart()
{
    VERSION=`s_to_version $1`
    DATA=`s_to_dir $1`
    PORT=`s_to_port $1`
    P=`pwd`
    cd $PGBASE/$VERSION

    bin/pg_ctl restart -D $DATA -mf -c
    cd $P
}

function stop()
{
    VERSION=`s_to_version $1`
    DATA=`s_to_dir $1`
    P=`pwd`
    cd $PGBASE/$VERSION
    bin/pg_ctl stop -D $DATA -mf
    cd $P
}

function install_pg()
{
    VERSION=`s_to_version $1`
    P=`pwd`

    EXISTS=`ls -1 $PGBASE/$VERSION`
    if [ "$EXISTS" != "" ]; then
	error "$VERSION already exits."
	return 1
    fi
    
    wget "https://ftp.postgresql.org/pub/source/v${VERSION}/postgresql-${VERSION}.tar.bz2"
    tar xjf postgresql-${VERSION}.tar.bz2 -C $PGBASE/source
    rm postgresql-${VERSION}.tar.bz2

    cd $P
}

function init()
{
    VERSION=`s_to_version $1`
    P=`pwd`

    cd $PGBASE/$VERSION
    rm -rf data
    bin/initdb -D data -E UTF8 --no-locale

    cd $P
}

function full_setup()
{
    VERSION=`s_to_version $1`
    ORIG_PWD=`pwd`

    install $VERSION
    
    cd $PGBASE/source/postgresql-${VERSION}
    ./configure --prefix=$PGBASE/$VERSION --enable-debug --enable-cassert CFLAGS=-g
    make -j 4 -s
    make install -j 4 -s

    init $VERSION
    
    cd ${ORIG_PWD}
}

function rebuild()
{
    VERSION=`s_to_version $1`
    shift
    OPTIONS=$@
    ORIG_PWD=`pwd`

    cd $PGBASE/source/postgresql-${VERSION}
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
	    [0-9][0-9][0-9] |  [0-9][0-9][0-9][0-9] | 'master' | 'rmaster' | node[0-9] | shd[0-9] | pri)
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
	    [0-9][0-9][0-9] |  [0-9][0-9][0-9][0-9] | 'master' | 'rmaster' | node[0-9] | shd[0-9] | pri)
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
    VERSION=$1
    NUM=$2
    P=`pwd`

    cd $PGBASE/$VERSION
    sh pgbin/syncrep.sh $NUM

    cd $P
}

function list()
{
    ls $PGBASE/
}


# Common functions

function s_to_dir()
{
    case $1 in
	rmaster)
	    echo "master"
	    return
	    ;;
	master | [0-9]*)
	    echo "data"
	    return
	    ;;
	*)
	    echo $1
	    return
    esac
}

# Convert string to version number which is used for directory name
function s_to_version()
{
    case $1 in
	master|rmaster|node[0-9]|shd[0-9]|pri)
	    echo "master"
	    return
	    ;;
	*)
	    VERSION_1=`echo $1 | cut -b1`
	    VERSION_2=`echo $1 | cut -b2`
	    VERSION_3=`echo $1 | cut -b3-`
	    echo "${VERSION_1}.${VERSION_2}.${VERSION_3}"
	    return
    esac
}

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

function port_test()
{
    VERSION=`s_to_version $1`
    PORT=`s_to_port $1`

    echo "Argument = $1"
    echo "version = $VERSION"
    echo "port = $PORT"
}
