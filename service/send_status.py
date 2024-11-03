import requests
import json
import sys

# Replace with your bot token and chat ID
TOKEN = 'Your Token'
CHAT_ID = 'Your chat ID'
BASE_URL = f'https://api.telegram.org/bot{TOKEN}/'

def send_message(service_name):
    message_text = f"{service_name}: Please click the button below to reconnect."
    button_text = "Reconnect"
    callback_data = f"reconnect_{service_name}"

    keyboard = {
        "inline_keyboard": [[{"text": button_text, "callback_data": callback_data}]]
    }

    try:
        response = requests.post(BASE_URL + 'sendMessage', data={
            'chat_id': CHAT_ID,
            'text': message_text,
            'reply_markup': json.dumps(keyboard),
        })

        if response.status_code == 200:
            message_id = response.json().get('result', {}).get('message_id')
            print(f"Button message sent for {service_name} with ID: {message_id}")
            return message_id
        else:
            print(f"Failed to send message for {service_name}. Status Code: {response.status_code}, Response: {response.text}")
            return None
    except Exception as e:
        print(f"Error sending message for {service_name}: {e}")
        return None

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Error: Missing service name argument.")
        sys.exit(1)

    service_name = sys.argv[1]
    send_message(service_name)
