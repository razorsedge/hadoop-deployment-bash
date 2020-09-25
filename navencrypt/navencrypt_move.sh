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
# Copyright Clairvoyant 2017
#
# $Id$
#
# EXIT CODE:
#     0 = success
#     1 = print_help function (or incorrect commandline)
#     2 = ERROR: Must be root.
#
if [ -n "$DEBUG" ]; then set -x; fi
#
##### START CONFIG ###################################################

##### STOP CONFIG ####################################################
PATH=/usr/bin:/usr/sbin:/bin:/sbin

# Function to print the help screen.
print_help() {
  printf 'Usage:  %s --navpass <password> --mountpoint <mountpoint> --emountpoint <emountpoint> --category <category>\n' "$1"
  printf '\n'
  printf '         -n|--navpass          First password used to encrypt the local Navigator Encrypt configuration.\n'
  printf '         -2|--navpass2         Second password used to encrypt the local Navigator Encrypt configuration.  This parameter is not needed for the single-passphrase key type.\n'
  printf '         -m|--mountpoint       Mountpoint of the source filesystem.\n'
  printf '         -e|--emountpoint      Mountpoint of the encrypted filesystem.\n'
  printf '         -c|--category         Category to be used for the encryption zone.\n'
  printf '        [-h|--help]\n'
  printf '        [-v|--version]\n'
  printf '\n'
  printf '   ex.  %s --navpass "mypasssword" --mountpoint /data/0 --emountpoint /navencrypt/0 --category data\n' "$1"
  exit 1
}

# Function to check for root privileges.
check_root() {
  if [[ $(/usr/bin/id | awk -F= '{print $2}' | awk -F"(" '{print $1}' 2>/dev/null) -ne 0 ]]; then
    printf 'You must have root privileges to run this program.\n'
    exit 2
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
    -n|--navpass)
      shift
      NAVPASS=$1
      ;;
    -2|--navpass2)
      shift
      NAVPASS2=$1
      ;;
    -m|--mountpoint)
      shift
      MOUNTPOINT=$1
      ;;
    -e|--emountpoint)
      shift
      EMOUNTPOINT=$1
      ;;
    -c|--category)
      shift
      CATEGORY=$1
      ;;
    -h|--help)
      print_help "$(basename "$0")"
      ;;
    -v|--version)
      printf '\tMove data onto Navigator Encrypt encrypted storage.\n'
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
# Check to see if we have no parameters.
if [[ -z "$NAVPASS" ]]; then print_help "$(basename "$0")"; fi
if [[ -z "$MOUNTPOINT" ]]; then print_help "$(basename "$0")"; fi
if [[ -z "$EMOUNTPOINT" ]]; then print_help "$(basename "$0")"; fi
if [[ -z "$CATEGORY" ]]; then print_help "$(basename "$0")"; fi

# Lets not bother continuing unless we have the privs to do something.
check_root

# main
set -u
umask 022

if [ -f /etc/navencrypt/keytrustee/clientname ]; then
  if [ -d "$MOUNTPOINT" ]; then
    if [ -d "$EMOUNTPOINT" ]; then
      echo "Moving data from ${MOUNTPOINT} to ${EMOUNTPOINT} for encryption..."
      printf -v NAVPASS_ANSWERS '%s\n%s' "$NAVPASS" "$NAVPASS2"
      echo "$NAVPASS_ANSWERS" |
      navencrypt-move encrypt "@${CATEGORY}" "$MOUNTPOINT" "$EMOUNTPOINT"
    else
      printf '** ERROR: Destination mountpoint %s is not a directory. Exiting...\n' "$EMOUNTPOINT"
      exit 5
    fi
  else
    printf '** ERROR: Source mountpoint %s is not a directory. Exiting...\n' "$MOUNTPOINT"
    exit 4
  fi
else
  printf '** WARNING: This host is not yet registered.  Skipping...\n'
  exit 3
fi

