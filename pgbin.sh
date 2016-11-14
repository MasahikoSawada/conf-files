#!/bin/bash
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
# - p [version] [connection option for psql]
# - list

function error()
{
    echo "[ERROR] : " $@
}

function start()
{
    VERSION=`s_to_version $1`
    PORT=`s_to_port $1`
    P=`pwd`
    cd $PGBASE/$VERSION

    bin/pg_ctl start -D data -o "-p $PORT" -c
    cd $P
}

function restart()
{
    VERSION=`s_to_version $1`
    PORT=`s_to_port $1`
    P=`pwd`
    cd $PGBASE/$VERSION

    bin/pg_ctl restart -D data -mf -c
    cd $P
}

function stop()
{
    VERSION=`s_to_version $1`
    P=`pwd`
    cd $PGBASE/$VERSION
    bin/pg_ctl stop -D data -mf
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

function s_to_version()
{
    if [ "$1" != "master" ];then
	VERSION_1=`echo $1 | cut -b1`
	VERSION_2=`echo $1 | cut -b2`
	VERSION_3=`echo $1 | cut -b3-`
	echo "${VERSION_1}.${VERSION_2}.${VERSION_3}"
	return
    else
	echo "master"
	return
    fi
}

function s_to_port()
{
    if [ "$1" != "master" ];then
	echo "5$1"
	return
    else
	echo "5432"
	return
    fi
}

function pp()
{
    options=""
    versions=()
    for OPT in "$@"
    do
	if [ "$before_command" == "true" ];then
	    command="\"$OPT\""
	    before_command="false"
	    continue
	fi

	case $OPT in
	    [0-9][0-9][0-9] |  [0-9][0-9][0-9][0-9] | 'master')
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

	echo "==== $VERSION ===="
	c="$PGBASE/$VERSION/bin/psql -d postgres -p $PORT $options $command_opt $command"
	eval "$c"
    done
}

function p()
{
    for OPT in "$@"
    do
	if [ "$before_command" == "true" ];then
	    command="\"$OPT\""
	    before_command="false"
	    continue
	fi

	case $OPT in
	    [0-9][0-9][0-9] |  [0-9][0-9][0-9][0-9] | 'master')
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

    VERSION=`s_to_version $version`
    PORT=`s_to_port $version`

    $PGBASE/$VERSION/bin/psql -d postgres -p $PORT "$options"
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

