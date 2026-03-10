#!/usr/bin/env python3
"""
One-time script: authorize Gmail access and save credentials with refresh token.

Prerequisites:
  pip install google-auth-oauthlib

Usage:
  1. Download your OAuth client_secret.json from Google Cloud Console
  2. Place it in the same directory as this script
  3. Run: python3 get_gmail_token.py
  4. Browser opens — authorize dbot to access Gmail
  5. Credentials saved to ~/.config/dbot/google_credentials.json
"""
from google_auth_oauthlib.flow import InstalledAppFlow
import json
import os

SCOPES = [
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/gmail.compose",
]

flow = InstalledAppFlow.from_client_secrets_file("client_secret.json", SCOPES)
creds = flow.run_local_server(port=0)

output = {
    "client_id": creds.client_id,
    "client_secret": creds.client_secret,
    "refresh_token": creds.refresh_token,
    "type": "authorized_user",
}

os.makedirs(os.path.expanduser("~/.config/dbot"), exist_ok=True)
path = os.path.expanduser("~/.config/dbot/google_credentials.json")
with open(path, "w") as f:
    json.dump(output, f, indent=2)

print(f"Saved credentials to {path}")
print("Set GOOGLE_CREDENTIALS_PATH={} in your .env".format(path))
