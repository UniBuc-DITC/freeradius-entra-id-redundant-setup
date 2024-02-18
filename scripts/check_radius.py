#!/usr/bin/env python3

"""This script tries to authenticate an user against a Network Policy Server
joined to an Active Directory domain, using the RADIUS protocol.

It also supports the authentication flow with a verification code challenge,
used when the Azure Multifactor Authentication (MFA) extension is enabled.
"""

from getpass import getpass
from pathlib import Path

from pyrad.client import Client
from pyrad.dictionary import Dictionary
import pyrad.packet

script_directory = Path(__file__).parent
dictionary_path = script_directory / "dictionary.txt"

client = Client(
    server="nps1.radius.unibuc.ro",
    secret=b"secret",
    dict=Dictionary(str(dictionary_path)),
)

user_name = "test@x8dw7.onmicrosoft.com"

print(f"Logging in as '{user_name}'")

# Create an authentication request
auth_packet = client.CreateAuthPacket(
    code=pyrad.packet.AccessRequest,
    User_Name=user_name,
    NAS_Identifier="postgresql",
)

auth_packet["User-Password"] = auth_packet.PwCrypt(getpass())

# send request
reply = client.SendPacket(auth_packet)

print("Attributes returned by server:")
for key in reply.keys():
    print(f"{key}: {reply[key]}")

# Get ID of authentication request
state = reply["State"][0]

if reply.code == pyrad.packet.AccessChallenge:
    challenge_response = input("Enter verification code:\n").strip()

    auth_packet["User-Password"] = auth_packet.PwCrypt(challenge_response)
    auth_packet["State"] = state

    # Respond to challenge
    reply = client.SendPacket(auth_packet)

if reply.code == pyrad.packet.AccessAccept:
    print("Access granted!")
else:
    print("Access rejected")
