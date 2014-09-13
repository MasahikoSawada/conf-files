# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

alias diff='colordiff'
PATH=$PATH:$HOME/bin
export PS1="\u [\W] \\$ "
export PATH
export CLASSPATH=$CLASSPATH:.:/usr/share/java/postgresql-9.2-1004.jdbc4.jar
export PATH=/home/masahiko/pgsql/master/bin:$PATH