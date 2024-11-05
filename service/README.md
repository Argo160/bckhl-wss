pkill -f "bash usage.sh" && nohup bash usage.sh &

screen -S session_name -X stuff $'\003' && screen -S session_name -X stuff 'bash usage.sh\n'
