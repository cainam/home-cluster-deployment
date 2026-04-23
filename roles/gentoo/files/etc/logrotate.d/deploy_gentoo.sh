/var/log/deploy_gentoo.sh.log /var/log/emerge.log{
  missingok
  daily
  dateext
  dateformate -%d-%m-%Y
  rotate 3
  compress
  copytruncate
}
