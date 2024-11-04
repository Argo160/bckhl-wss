import requests
import json
import subprocess
import time
import sys
import configparser

# Load configuration
config = configparser.ConfigParser()
config.read('config.ini')

# Replace with your bot token and chat ID from config
TOKEN = config['DEFAULT']['TOKEN']
CHAT_ID = config['DEFAULT']['CHAT_ID']
BASE_URL = f'https://api.telegram.org/bot{TOKEN}/'

# Unique server name passed as an argument
SERVER_NAME = sys.argv[1] if len(sys.argv) > 1 else 'default_server'

def get_updates(offset=None):
    params = {'timeout': 100, 'offset': offset}
    try:
        response = requests.get(BASE_URL + 'getUpdates', params=params)
        if response.status_code == 200:
            return response.json()
        else:
            print(f"Failed to get updates. Status Code: {response.status_code}")
            return None
    except Exception as e:
        print(f"Error getting updates: {e}")
        return None

def handle_updates(updates):
    for update in updates.get('result', []):
        if 'callback_query' in update:
            callback_data = update['callback_query']['data']
            service_name = callback_data.split('_', 1)[1]  # Extract service name
            if callback_data.startswith('reconnect_'):
                print(f"Reconnect button clicked for service: {service_name} on {SERVER_NAME}")

                # Execute the reconnect script
                subprocess.call(['bash', 'reconnect_script.sh'])

                # Send confirmation message
                requests.post(BASE_URL + 'sendMessage', data={
                    'chat_id': CHAT_ID,
                    'text': f"{service_name} reconnected successfully on {SERVER_NAME}!"
                })

if __name__ == '__main__':
    offset = None
    while True:
        updates = get_updates(offset)
        if updates and 'result' in updates and updates['result']:
            handle_updates(updates)
            offset = updates['result'][-1]['update_id'] + 1
        time.sleep(1)
