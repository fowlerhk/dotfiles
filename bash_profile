# Handy function to attach directories to $PATH, but only if not already present.
pathmunge () {
    if ! echo $PATH | egrep -q "(^|:)$1($|:)" ; then
       if [ "$2" = "after" ] ; then
          [ -d "$1" ] && PATH=$PATH:$1
       else
          [ -d "$1" ] && PATH=$1:$PATH
       fi
    fi
}

### Set initial path; add HOME/bin if not root
#PATH=/usr/local/bin:/usr/bin:/bin
# PATH=/bin:/usr/bin:/usr/local/bin 
if test "$HOME" != "/" ; then
    pathmunge $HOME/bin after
fi
