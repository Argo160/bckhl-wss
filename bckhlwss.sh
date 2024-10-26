if [[ $EUID -ne 0 ]]; then
    clear
    echo "You should run this script with root!"
    echo "Use sudo -i to change user to root"
    exit 1
fi
iran-service() {
    clear
    read -p "service Name (2Letters country preffered) :" service
    read -p "Tunnel Port : " Port
    read -p "Token : " Token
cat <<EOL > /root/config$service.toml    
[server]
bind_addr = "0.0.0.0:$Port"
transport = "wss"
token = "$Token" 
channel_size = 2048
keepalive_period = 75 
nodelay = true 
tls_cert = "/root/server.crt"      
tls_key = "/root/server.key"
sniffer = false
sniffer_log = "/root/backhaul.json"
log_level = "info"
ports = [
EOL
    read -p "How Many Inbounds You gonna use in tunnel? : " Count
    ports=()

    # Loop to collect port numbers
    for ((i = 1; i <= Count; i++)); do
        read -p "Enter port number for inbound $i: " port
        ports+=("$port")
    done

    # Append each port number, with a comma after each except the last
    for ((i = 0; i < ${#ports[@]}; i++)); do
        if (( i == ${#ports[@]} - 1 )); then
            echo "\"${ports[i]}\"" >> /root/config$service.toml
        else
            echo "\"${ports[i]}\"," >> /root/config$service.toml
        fi
    done

    # Close the array in config.toml
    echo "]" >> /root/config$service.toml

    # Confirm the output
    echo -e "\e[32mConfiguration has been written to /root/config$service.toml.\e[0m"  # Green color for UP
    sleep 0.5
    clear
    echo
    echo -e "\033[33mCreating Backhaul Service\033[0m" #yellow Color
    echo
    sleep 0.5
cat <<EOL > /etc/systemd/system/backhaul$service.service
[Unit]
Description=Backhaul Reverse Tunnel Service
After=network.target

[Service]
Type=simple
ExecStart=/root/backhaul -c /root/config$service.toml
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOL

    systemctl daemon-reload
    systemctl enable backhaul$service.service
    systemctl start backhaul$service.service
}
##########
## IRAN ##
##########
Iran-core() {
    clear
    echo
    echo -e "\033[33mInstalling curl...\033[0m" #yellow Color
    echo
    sleep 0.5
    apt install curl -y
    if command -v curl > /dev/null; then
        echo
        echo -e "\e[32mcurl Installed.\e[0m"  # Green color for UP
        echo
        sleep 0.5
    else
        echo
        echo -e "\033[31mcurl is not installed.\033[0m"  # Print in red
        echo
        sleep 0.5
    fi
    echo
    echo -e "\033[33mInstalling socat...\033[0m" #yellow Color
    echo
    sleep 0.5
    apt install socat -y
    if command -v socat > /dev/null; then
        echo
        echo -e "\e[32msocat Installed.\e[0m"  # Green color for UP
        echo
        sleep 0.5
    else
        echo
        echo -e "\033[31msocat is not installed.\033[0m"  # Print in red
        echo
        sleep 0.5
    fi

    echo
    echo -e "\033[33mInstalling acme.sh...\033[0m" #yellow Color
    echo
    sleep 0.5
    curl https://get.acme.sh | sh
    if command -v acme.sh > /dev/null; then
        echo
        echo -e "\e[32macme.sh Installed.\e[0m"  # Green color for UP
        echo
        sleep 0.5
    else
        echo
        echo -e "\033[31macme.sh is not installed.\033[0m"  # Print in red
        echo
        sleep 0.5
    fi
    clear
    read -p "Enter your domain for certificate :" domain
    read -p "Enter your email for certificate :" email
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    ~/.acme.sh/acme.sh --register-account -m $email
    ~/.acme.sh/acme.sh --issue -d $domain --standalone
    ~/.acme.sh/acme.sh --installcert -d $domain --fullchain-file /root/server.crt --key-file /root/server.key
    if [ -f "/root/server.crt" ] && [ -f "/root/server.key" ]; then
        echo -e "\e[32mcertificate was issued and installed successfully.\e[0m"  # Green color for UP
    else
        echo -e "\033[31mcertificate could not be issued! .\033[0m"  # Print in red
    fi
    clear
    echo
    echo -e "\033[33mdownloading and extracting backhaul core.\033[0m" #yellow Color
    echo
    sleep 0.5
    cd
    wget https://github.com/Musixal/Backhaul/releases/download/v0.6.2/backhaul_linux_amd64.tar.gz
    tar -xzf backhaul_linux_amd64.tar.gz
    if [ -f "/root/backhaul" ] && [ -x "/root/backhaul" ]; then
        echo
        echo -e "\e[32mbackhaul core downloaded and extracted.\e[0m"  # Green color for UP
        echo
        sleep 0.5
    else
        echo
        echo -e "\033[31mcould not download or extract the backhaul core!.\033[0m"  # Print in red
        echo
        sleep 0.5
    fi
}


Kharej() {
    clear
    echo
    echo -e "\033[33mdownloading and extracting backhaul core.\033[0m" #yellow Color
    echo
    sleep 0.5
    cd
    wget https://github.com/Musixal/Backhaul/releases/download/v0.6.2/backhaul_linux_amd64.tar.gz
    tar -xzf backhaul_linux_amd64.tar.gz
    if [ -f "/root/backhaul" ] && [ -x "/root/backhaul" ]; then
        echo
        echo -e "\e[32mbackhaul core downloaded and extracted.\e[0m"  # Green color for UP
        echo
        sleep 0.5
    else
        echo
        echo -e "\033[31mcould not download or extract the backhaul core!.\033[0m"  # Print in red
        echo
        sleep 0.5
    fi
    clear
    read -p "Iran Domain : " domain
    read -p "Tunnel Port : " Port
    read -p "Token : " Token
cat <<EOL > /root/config.toml
[client]
remote_addr = "$domain:$Port"
edge_ip = "" 
transport = "wss"
token = "$Token" 
connection_pool = 8
aggressive_pool = true
keepalive_period = 75
dial_timeout = 10
retry_interval = 3  
nodelay = true 
sniffer = false 
sniffer_log = "/root/backhaul.json"
log_level = "info"
EOL
    echo -e "\e[32mConfiguration has been written to /root/config.toml.\e[0m"  # Green color for UP
    sleep 0.5
    clear
    echo
    echo -e "\033[33mCreating Backhaul Service\033[0m" #yellow Color
    echo
    sleep 0.5
cat <<EOL > /etc/systemd/system/backhaul.service
[Unit]
Description=Backhaul Reverse Tunnel Service
After=network.target

[Service]
Type=simple
ExecStart=/root/backhaul -c /root/config.toml
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOL

    systemctl daemon-reload
    systemctl enable backhaul.service
    systemctl start backhaul.service
}


while true; do
clear
    echo "Stunnel Setup"
    echo "Menu:"
    echo "1  - Iran Core"
    echo "2  - Add Iran Service"
    echo "3  - Kharej"
    echo "4  - Exit"
    read -p "Enter your choice: " choice
    case $choice in
        1) Iran-core;;
        2) iran-service;;
        3) Kharej;;
        4) echo "Exiting..."; exit;;
        *) echo "Invalid choice. Please enter a valid option.";;
    esac
done
