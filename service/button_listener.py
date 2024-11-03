import requests
import json
import subprocess
import time

# Replace with your bot token and chat ID
TOKEN = 'Your Token'
CHAT_ID = 'Your Chat ID'
BASE_URL = f'https://api.telegram.org/bot{TOKEN}/'

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
                print(f"Reconnect button clicked for service: {service_name}")

                # Execute the reconnect script
                subprocess.call(['bash', 'reconnect_script.sh'])

                # Send confirmation message
                requests.post(BASE_URL + 'sendMessage', data={
                    'chat_id': CHAT_ID,
                    'text': f"{service_name} reconnected successfully!"
                })

if __name__ == '__main__':
    offset = None
    while True:
        updates = get_updates(offset)
        if updates and 'result' in updates and updates['result']:
            handle_updates(updates)
            offset = updates['result'][-1]['update_id'] + 1
        time.sleep(1)

