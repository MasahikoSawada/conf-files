# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

alias diff='colordiff'
alias gg='ps aux | grep --color=auto'
alias server='redis-server'
alias cli='redis-cli'
alias emacs='emacs -nw'
alias gdb='emacs -f gdb'

alias c='./configure --prefix=/home/masahiko/pgsql/master --enable-debug --enable-cassert --enable-depend --enable-tap-tests CFLAGS=-g'
alias cc='./configure --prefix=/home/masahiko/pgsql/master --enable-debug --enable-cassert --enable-depend --enable-tap-tests CFLAGS=-g && make clean && make -j 8 install -s'
alias m='make -j 4 -s'
alias remove-uufiles='find . | egrep "\.rej|\.orig" | xargs rm'
alias show-uufiles='find . | egrep "\.rej|\.orig"'
alias gs='git status | egrep -v "rej|orig|TAGS"'

PATH=$PATH:$HOME/bin
GIT_PS1_SHOWDIRTYSTATE=true
export PS1='\u (\W) \[\033[31m\]$(__git_ps1 [%s])\[\033[00m\] \$ '
export PATH
export CLASSPATH=$CLASSPATH:.:/usr/share/java/postgresql-9.2-1004.jdbc4.jar
export PATH=/home/masahiko/pgsql/master/bin:/home/masahiko/go/go/bin:$PATH
export PATH=/usr/local/bin/git:$PATH

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

source ~/conf-files/pgbin.sh

# Spell Checker
export WLIST_DIR=/home/masahiko/.checker/Patch-Spell-Checker/wlist.d
export PATH=$PATH://home/masahiko/.checker/Patch-Spell-Checker/
alias sp='git diff | PatctSpellChecker.py'


# Environemnt variables for regression TAP test
export PERL5LIB=/home/masahiko/pgsql/source/postgresql/src/test/perl
export TESTDIR='/home/masahiko/pgsql/source/postgresql/src/test/recovery'
export PATH="/home/masahiko/pgsql/source/postgresql/tmp_install/home/masahiko/pgsql/master/bin:$PATH"
export LD_LIBRARY_PATH="/home/masahiko/pgsql/source/postgresql/tmp_install/home/masahiko/pgsql/master/lib"
export PGPORT='65432'
export PG_REGRESS='/home/masahiko/pgsql/source/postgresql/src/test/recovery/../../../src/test/regress/pg_regress'

# Set import path
export PYTHONPATH=~/conf-files/PostgresNode/
