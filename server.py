from typing import Union
from Crypto.PublicKey import RSA
from Crypto.Hash import SHA256
from Crypto.Cipher import PKCS1_OAEP
import json
from fastapi import FastAPI, File, UploadFile, HTTPException
import base64

app = FastAPI()

hosts = [
  {
    "ip": "10.0.0.1",
    "hosts": ["host.yami", "home.yami"]
  }
]

with open("./encryptkey", "r") as f:
  encryptkey_data = f.read()

async def encrypt_data(data, public_key):
  key = RSA.import_key(public_key)
  cipher = PKCS1_OAEP.new(key)
  encrypted_data = cipher.encrypt(data)
  return encrypted_data

def signature(encrypt_key, data):
  hash_object = SHA256.new(data=data)
  key = RSA.import_key(encrypt_key)
  cipher = PKCS1_OAEP.new(key)
  signatured_data = cipher.encrypt(hash_object.digest())
  return signatured_data

@app.get("/hosts")
async def get_hosts():
  string_hosts = json.dumps(hosts)
  signatured_data = signature(encryptkey_data, string_hosts.encode())
  signature_b64 = base64.b64encode(signatured_data).decode("utf-8")
  return {"data": string_hosts, "signature": signature_b64}
