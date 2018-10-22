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

##### STOP CONFIG ####################################################
PATH=/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin
PWCMD='< /dev/urandom tr -dc A-Za-z0-9 | head -c 20;echo'
DATE=$(date '+%Y%m%d%H%M%S')

# Function to print the help screen.
print_help() {
  echo "Joins the node to an IPA domain."
  echo ""
  echo "Usage:  $1 --domain <IPA domain>"
  echo "        $1 [-u|--user <User name to use for enrollment>]"
  echo "        $1 [-p|--passwd <User password to use for enrollment>]"
  echo "        $1 [-s|--server <Server to use for enrollment>]"
  echo "        $1 [-h|--help]"
  echo "        $1 [-v|--version]"
  echo "   ex.  $1"
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
    -d|--domain)
      shift
      _DOMAIN_UPPER=$(echo $1 | tr '[:lower:]' '[:upper:]')
      _DOMAIN_LOWER=$(echo $1 | tr '[:upper:]' '[:lower:]')
      ;;
    -u|--user)
      shift
      _USER="--principal $1"
      ;;
    -p|--password)
      shift
      _PASSWD="--password=$1"
      ;;
    -s|--server)
      shift
      _SERVER="--server $1"
      ;;
    -h|--help)
      print_help "$(basename "$0")"
      ;;
    -v|--version)
      echo "Intall and configure SSSD to use the IPA provider."
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
if [ "$OS" != RedHatEnterpriseServer ] && [ "$OS" != CentOS ]; then
#if [ "$OS" != RedHatEnterpriseServer ] && [ "$OS" != CentOS ] && [ "$OS" != Debian ] && [ "$OS" != Ubuntu ]; then
  echo "ERROR: Unsupported OS."
  exit 3
fi

# Check to see if we have the required parameters.
if [ -z "$_DOMAIN_LOWER" ]; then print_help "$(basename "$0")"; fi

# Lets not bother continuing unless we have the privs to do something.
check_root

# main
echo "Installing SSSD for Active Directory..."
if { [ "$OS" == RedHatEnterpriseServer ] || [ "$OS" == CentOS ]; } && [ "$OSREL" == 7 ]; then
  # EL7
  OPTS="$_USER $_OU7 $_ID"
  echo "** Installing software."
  yum -y -e1 -d1 install ipa-client
  #ipa-client-install --enable-dns-updates --ssh-trust-dns -p admin_principal -w admin_password -U --all-ip-addresses --ssh-trust-dns --enable-dns-updates --server=IPA_MASTER_FQDN --realm=REALM --domain=DOMAIN --app-ip-addresses --ssh-trust-dns
 --enable-dns-updates
  #ipa-client-install -p admin -w cloudera -U --server=ipademo-1.vpc.cloudera.com --realm=ALEXCIOBANU.RO --domain=alexciobanu.ro --all-ip-addresses
  ipa-client-install --unattended $_USER $_PASSWD --domain $_DOMAIN_LOWER --all-ip-addresses --mkhomedir
  if [ $? -ne 0 ]; then
    ipa-client-install --unattended $_USER $_PASSWD --domain $_DOMAIN_LOWER --all-ip-addresses --mkhomedir $_SERVER
  fi
elif [ "$OS" == Debian ] || [ "$OS" == Ubuntu ]; then
  :
fi

exit
--domain optional
--server optional
--realm  optional
--ssh-trust-dns
--ntp-server= optional
 --force-ntpd
--unattended
--permit
--enable-dns-updates






