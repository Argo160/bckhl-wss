import requests
import sys

BOT_TOKEN = 'Your Token'
CHAT_ID = 'Your Chat ID'

def send_message(message):
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage"
    payload = {
        'chat_id': CHAT_ID,
        'text': message
    }
    response = requests.post(url, data=payload)
    return response.json()

if __name__ == "__main__":
    # Get the message from command line argument
    if len(sys.argv) > 1:
        message = sys.argv[1]
        send_message(message)
    else:
        print("No message provided.")
