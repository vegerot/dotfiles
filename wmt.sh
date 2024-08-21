function is-walmart-mac() {
  [[ -f "/Users/Shared/Start Here - Mac At Walmart.pdf" ]]
}

function vpn() {
	echo "toggling vpn..."
	local vpn_status=$(vpn-status)
	if [[ $vpn_status == "Disconnected" ]]; then
		echo "connecting vpn..."
		vpn-up
	else
		echo "disconnecting vpn..."
		vpn-down
	fi
}
function vpn-up() {
  # STEPS TO MAKE THIS WORK
  # 1. Install [2fa](https://github.com/rsc/2fa)
  #   a. Make a [new TOTP](https://linotp.wal-mart.com/selfservice/login) token
  # 2. Set up your VPN account in the Mac Keychain, inserting your user id and password
  #  a. `security add-generic-password -s 'wmt-sso' -a $USER -w`
  #  b. credit: @a0c01gr
  # 3. run this function!
  # 4. profit???


  #local VPN_HOST=sslvpngwgec.wal-mart.com/Walmart_Associate_MAC_Yubi # blocks Spotify
  #local VPN_HOST=http://sslvpngwwec.wal-mart.com/Walmart_Associate_Yubi # blocks Spotify
  #local VPN_HOST=http://sslvpngw.wal-mart.com/Walmart_Associate_Yubi # seamlessly switches on Zoom calls; blocks Spotify; makes Slack go offline when switching
  local VPN_HOST=sslvpngwwec.wal-mart.com/Walmart_Associate_Yubi # blocks Spotify, i like this one
  if is-walmart-mac; then
	  local VPN_USER=$USER
  else
	  local VPN_USER=${VPN_USER:-m0c0j7y}
  fi

  echo "Starting the vpn ..."
  if [[ ! -x "$(command -v 2fa)" ]] ; then
	  printf "requires [2fa](https://github.com/rsc/2fa)\n"
	  return 1
  fi
  local mfa_code="$(2fa walmart)"
  if [[ -x "$(command -v security)" ]]; then
	  local vpn_password=$(security find-generic-password -w -s 'wmt-sso' -a $VPN_USER || cat ~/.vpn_password)
  else
	  local vpn_password=$(cat ~/.vpn_password)
  fi

  local should_use_anyconnect=false
  if [[ -x "$(command -v /opt/cisco/*/bin/vpn)" && -z $VPN_DONT_USE_ANYCONNECT ]]; then
	  should_use_anyconnect=true
  fi

  if [[ $should_use_anyconnect == true ]]; then
	  printf "\n${vpn_password}\n${mfa_code}\ny" | /opt/cisco/*/bin/vpn -s connect $VPN_HOST $@
  else
	  # for some reason this is the only one I've found that works with openconnect
	  local VPN_HOST=sslvpngwgec.wal-mart.com/Walmart_Associate_MAC_Yubi
	  echo "${vpn_password}\n${mfa_code}\n" | sudo openconnect --passwd-on-stdin --background -u $VPN_USER $VPN_HOST $@
  fi
  echo "Connected" > /tmp/vpn-status
}

function vpn-down() {
	local is_openconnect_running=$(pgrep openconnect)
	if [[ -n $is_openconnect_running ]]; then
		sudo /bin/kill -2 `pgrep openconnect`
	else
		/opt/cisco/*/bin/vpn disconnect
	fi
	echo "Disconnected" > /tmp/vpn-status
}

function vpn-status() {
	if [[ -f /tmp/vpn-status ]]; then
		# bugs:
		# - if you restart your computer with the VPN running, it will incorrectly be reported as connected
		# - if your VPN connection times out, it will incorrectly be reported as connected
		cat /tmp/vpn-status
		return 0
	fi

	local openconnect_running=$(pgrep openconnect)
	if [[ -n $openconnect_running ]]; then
		echo "Connected"
		return 0
	fi
	local anyconnect=$(echo /opt/cisco/*/bin/vpn);
	if [[ ! -x $anyconnect ]]; then
		echo "N/A"
		return 1
	fi

	$anyconnect state\
		| sed -r 's/^.*state: (Connected|Disconnected)$/\1/g'\
		| grep -q -E --color=never 'Connected'
	if [[ $? == 0 ]]; then
		echo "Connected"
	else
		echo "Disconnected"
	fi
}


function wmt_sudome() {
  set -x
  sudo jamf policy -id 854
  set +x
}

function wmt_fixmynetwork() {
	set -x
	# Fix My Network
	sudo jamf policy -id 906
	if [[ $1 == "eagle" ]]; then
		# Fix My Eagle Configuration
		sudo jamf policy -id 809
	fi
	set +x
}
