# 1) jaky pouzivame shell
echo "My shell is:"
echo $SHELL

# 2) aktualni uzivatel
echo "My current user is:"
whoami

# 3) verze linuxu
echo "My linux distribution is:"
if [ -f /etc/os-release ]; then
  cat /etc/os-release
else
  echo "/etc/os-release not found (this is probably macOS, not Linux)"
fi

# 4) environment variables
echo "My environment variables are:"
printenv
