  #!/bin/bash

## Automatic discovery of ssh keys.
export HOME=$APACHE_HOME
if [ -f  ~/.ssh/id_rsa ]; then
  eval "$(ssh-agent -s)" > /dev/null 2>&1
  gosu www-data ssh-add ~/.ssh/id_rsa > /dev/null 2>&1
fi
if [ -f  ~/.ssh/hosts ]; then
  if [ ! -f ~/.ssh/known_hosts ]; then
    gosu www-data ssh-keyscan -H `cat ~/.ssh/hosts` >> ~/.ssh/known_hosts 2>&1
  fi
fi

# Based on: http://chapeau.freevariable.com/2014/08/docker-uid.html
export ORIGPASSWD=$(cat /etc/passwd | grep www-data)
export ORIG_UID=$(echo $ORIGPASSWD | cut -f3 -d:)
export ORIG_GID=$(echo $ORIGPASSWD | cut -f4 -d:)
export DEV_UID=${LOCAL_UID:=$ORIG_UID}
export DEV_GID=${LOCAL_GID:=$ORIG_GID}
groupdel dialout
sed -i -e "s/:$ORIG_UID:$ORIG_GID:/:$DEV_UID:$DEV_GID:/" /etc/passwd
sed -i -e "s/www-data:x:$ORIG_GID:/www-data:x:$DEV_GID:/" /etc/group

# Bindfs home.
if [ -n "$LOCAL_UID" ] && [ -n "$LOCAL_GID" ]; then
  #bindfs -u www-data -g www-data -p 0000,u=rwX:go=rD --create-for-user=${LOCAL_UID} --create-for-group=${LOCAL_GID} "/data/var/www" "/data/var/www"
  bindfs -u www-data -g www-data -p 0000,u=rwX --create-for-user=${LOCAL_UID} --create-for-group=${LOCAL_GID} "$HOME" "$HOME"
fi

# Set the umask to 002 so that the group has write access.
umask 002

# Mimic libcontainer changing user to www-data using gosu.
exec gosu www-data "${@}"
