
import requests
import sys
import configparser

# Load configuration
config = configparser.ConfigParser()
config.read('config.ini')

# Replace with your bot token and chat ID from config
BOT_TOKEN = config['DEFAULT']['TOKEN']
CHAT_ID = config['DEFAULT']['CHAT_ID']

# Unique server name passed as an argument
SERVER_NAME = sys.argv[2] if len(sys.argv) > 2 else 'default_server'

def send_message(message):
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage"
    payload = {
        'chat_id': CHAT_ID,
        'text': f"{SERVER_NAME}: {message}"
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
