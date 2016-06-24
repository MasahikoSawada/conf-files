PGBASE=/home/masahiko/pgsql

# Available functions are;
# - start [version]
# - restart [version]
# - stop [version
# - install [version]
# - init [version]
# - full_setup [version]
# - sync_rep [version] [num]
# - rebuld [version] [options]
# - list

function error()
{
    echo "[ERROR] : " $@
}

function start()
{
    VERSION=$1
    P=`pwd`
    cd $PGBASE/$VERSION

    if [ "$VERSION" == "master" ];then
	PORT=5432
    else
	PORT=5`echo $VERSION | tr -d "."`
    fi

    bin/pg_ctl start -D data -o "-p $PORT"
    cd $P
}

function restart()
{
    VERSION=$1
    P=`pwd`
    cd $PGBASE/$VERSION

    if [ "$VERSION" == "master" ];then
	PORT=5432
    else
	PORT=5`echo $VERSION | tr -d "."`
    fi

    bin/pg_ctl restart -D data -mf
    cd $P
}

function stop()
{
    VERSION=$1
    P=`pwd`
    cd $PGBASE/$VERSION
    bin/pg_ctl stop -D data -mf
    cd $P
}

function install()
{
    VERSION=$1
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
    VERSION=$1
    P=`pwd`

    cd $PGBASE/$VERSION
    bin/initdb -D data -E UTF8 --no-locale

    cd $P
}

function full_setup()
{
    VERSION=$1
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
    VERSION=$1
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

