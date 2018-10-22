#!/bin/bash
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright Clairvoyant 2018
#
if [ -n "$DEBUG" ]; then set -x; fi
#
##### START CONFIG ###################################################

_KRBSERVER=$(hostname -f)

##### STOP CONFIG ####################################################
PATH=/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin
DATE=$(date '+%Y%m%d%H%M%S')

# Function to print the help screen.
print_help() {
  echo "Usage:  $1 --realm <realm> --cm_principal <princ>"
  echo ""
  echo "        -r|--realm                   <Kerberos realm>"
  echo "        -c|--cm_principal            <CM principal>"
  echo "        [-h|--help]"
  echo "        [-v|--version]"
  echo ""
  echo "   ex.  $1 --realm HADOOP.COM --cm_principal cloudera-scm"
  exit 1
}

# Function to check for root priviledges.
check_root() {
  if [[ $(/usr/bin/id | awk -F= '{print $2}' | awk -F"(" '{print $1}' 2>/dev/null) -ne 0 ]]; then
    echo "You must have root priviledges to run this program."
    exit 2
  fi
}

# Function to discover basic OS details.
discover_os() {
  if command -v lsb_release >/dev/null; then
    # CentOS, Ubuntu
    # shellcheck disable=SC2034
    OS=$(lsb_release -is)
    # 7.2.1511, 14.04
    # shellcheck disable=SC2034
    OSVER=$(lsb_release -rs)
    # 7, 14
    # shellcheck disable=SC2034
    OSREL=$(echo "$OSVER" | awk -F. '{print $1}')
    # trusty, wheezy, Final
    # shellcheck disable=SC2034
    OSNAME=$(lsb_release -cs)
  else
    if [ -f /etc/redhat-release ]; then
      if [ -f /etc/centos-release ]; then
        # shellcheck disable=SC2034
        OS=CentOS
      else
        # shellcheck disable=SC2034
        OS=RedHatEnterpriseServer
      fi
      # shellcheck disable=SC2034
      OSVER=$(rpm -qf /etc/redhat-release --qf='%{VERSION}.%{RELEASE}\n')
      # shellcheck disable=SC2034
      OSREL=$(rpm -qf /etc/redhat-release --qf='%{VERSION}\n' | awk -F. '{print $1}')
    fi
  fi
}

## If the variable DEBUG is set, then turn on tracing.
## http://www.research.att.com/lists/ast-users/2003/05/msg00009.html
#if [ $DEBUG ]; then
#  # This will turn on the ksh xtrace option for mainline code
#  set -x
#
#  # This will turn on the ksh xtrace option for all functions
#  typeset +f |
#  while read F junk
#  do
#    typeset -ft $F
#  done
#  unset F junk
#fi

# Process arguments.
while [[ $1 = -* ]]; do
  case $1 in
    -r|--realm)
      shift
      _REALM_UPPER=$(echo "$1" | tr '[:lower:]' '[:upper:]')
      _REALM_LOWER=$(echo "$1" | tr '[:upper:]' '[:lower:]')
      ;;
    -c|--cm_principal)
      shift
      _CM_PRINCIPAL=$1
      ;;
    -h|--help)
      print_help "$(basename "$0")"
      ;;
    -v|--version)
      echo "Install FreeIPA."
      exit 0
      ;;
    *)
      print_help "$(basename "$0")"
      ;;
  esac
  shift
done

echo "********************************************************************************"
echo "*** $(basename "$0")"
echo "********************************************************************************"
# Check to see if we are on a supported OS.
# Currently only EL.
discover_os
#if [ "$OS" != RedHatEnterpriseServer ] && [ "$OS" != CentOS ] && [ "$OS" != Debian ] && [ "$OS" != Ubuntu ]; then
if [ "$OS" != RedHatEnterpriseServer ] && [ "$OS" != CentOS ]; then
  echo "ERROR: Unsupported OS."
  exit 3
fi

# Check to see if we have the required parameters.
if [ -z "$_REALM_UPPER" ] || [ -z "$_CM_PRINCIPAL" ]; then print_help "$(basename "$0")"; fi

# Lets not bother continuing unless we have the privs to do something.
check_root

# main
echo "Installing FreeIPA server..."
if [ "$OS" == RedHatEnterpriseServer ] || [ "$OS" == CentOS ]; then
  yum -y -e1 -d1 install ipa-server ipa-server-dns

  _APASS=$(apg -a 1 -M NCL -m 20 -x 20 -n 1)
  if [ -z "$_APASS" ]; then
    _APASS=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c 20;echo)
  fi
  _DPASS=$(apg -a 1 -M NCL -m 20 -x 20 -n 1)
  if [ -z "$_DPASS" ]; then
    _DPASS=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c 20;echo)
  fi

  #ipa-server-install --setup-dns --hostname=hostname -r realm_name -n domain_name ] && [ ipa_admin_password -p directory_manager_password --forwarder=forwarder --forwarder=forwarder --reverse-zone=reverse_zone --forward-policy=first
  ipa-server-install --unattended --realm=${_REALM_UPPER} --domain=${_REALM_LOWER} --admin-password=${_APASS} --ds-password=${_DPASS} --mkhomedir --ssh-trust-dns

--hostname=$(hostname)
--ip-address=

  #ipa-dns-install
#--setup-dns
#--forwarder=
#--no-forwarders
#--auto-forwarders
#--auto-reverse

  #yum -y -e1 -d1 install ipa-server ipa-server-dns
  #ipa-replica-install --setup-dns -r realm_name -n domain_name -P admin -w admin_password --hostname=IPA_REPLICA_HOSTNAME --ipaddress=REPLICA_IP_ADDRESS --server=IPA_MASTER_SERVER --forwarder=forwarder --forwarder=forwarder --reverse-zone=reverse_zone --forward-policy=first --no-host-dns

  echo "****************************************"
  echo "****************************************"
  echo "****************************************"
  echo "*** SAVE THIS PASSWORD"
  echo "Directory Manager user : ${_DPASS}"
  echo "****************************************"
  echo "****************************************"
  echo "****************************************"

  echo "****************************************"
  echo "****************************************"
  echo "****************************************"
  echo "*** SAVE THIS PASSWORD"
  echo "IPA admin user : ${_APASS}"
  echo "****************************************"
  echo "****************************************"
  echo "****************************************"

  echo "$_APASS" | kinit admin

  echo "** Generating $_CM_PRINCIPAL principal for Cloudera Manager ..."
  _CM_PRINCIPAL_PASSWORD=$(apg -a 1 -M NCL -m 20 -x 20 -n 1 2>/dev/null)
  if [ -z "$_CM_PRINCIPAL_PASSWORD" ]; then
    _CM_PRINCIPAL_PASSWORD=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c 20;echo)
  fi
  echo "****************************************"
  echo "****************************************"
  echo "****************************************"
  echo "*** SAVE THIS PASSWORD"
  echo "${_CM_PRINCIPAL}@${_REALM_UPPER} : ${_CM_PRINCIPAL_PASSWORD}"
  echo "****************************************"
  echo "****************************************"
  echo "****************************************"
  ipa --no-prompt user-add $_CM_PRINCIPAL --first="Cloudera" --last="Manager" --cn="Cloudera Manager" --password $_CM_PRINCIPAL_PASSWORD
  ipa --no-prompt group-add-member admins --users=$_CM_PRINCIPAL
  ipa --no-prompt group-add-member "trust admins" --users=$_CM_PRINCIPAL
  #mkdir -p /etc/cloudera-scm-server
  #ipa-getkeytab -p ${_CM_PRINCIPAL}@${_REALM_UPPER} -k /etc/cloudera-scm-server/scm.keytab -r
  ##ipa-getkeytab -p ${_CM_PRINCIPAL}@${_REALM_UPPER} -k /etc/cloudera-scm-server/scm.keytab --password $_CM_PRINCIPAL_PASSWORD
  #chown cloudera-scm:cloudera-scm /etc/cloudera-scm-server/scm.keytab
  #chmod 600 /etc/cloudera-scm-server/scm.keytab

elif [ "$OS" == Debian ] || [ "$OS" == Ubuntu ]; then
  :
fi

