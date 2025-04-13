import base64
from Crypto.PublicKey import RSA
from Crypto.Hash import SHA256
from Crypto.Cipher import PKCS1_OAEP
import json

with open("./dencryptkey", "r") as f:
  decryptkey = f.read()

testdata = {"data":"[{\"ip\": \"10.0.0.1\", \"hosts\": [\"host.yami\", \"home.yami\"]}]","signature":"PZbxijB/CRo9ZVhyZdqny4wOwamJwS8jfvJ5gsY4ZEAZ5+kTK8F03JtU5+hGsv1STswjFyva0BRJiMGqA/zEyVa9bajnm6d0Cs6rtnPwxI5Ney1xTKGNDM0rKdMT5Ik0lxP2T2oXZVNAdK+s9GlSrVJ3M8IcgOo+J0B8PMbCgReRTek3xgRlFgvxNF5jV/Rh4wNr9q8oAgnKzfEm4xZJ1cL7GhpAo8npVAJYEbodOBDLIMid3V8UYXwGq2QwztZ+MRdjXDlVoBkS0+rY3XmIoUftW0pohVE4Nt4FYjRiR9akIiWizbkeULXJz+2iuqGg/3TiYqW5wzKoRyTloRNx1PpnVZrDk6ri6e6iTS32jX0kQNAGAtiRVqPSaxqK3lkey5rLtfNCHpl/OpwNeiAzUoZDcSDpTNYK9IXdyjrCL1/yIizLX+is2shS23g4sdbgMJUU7kR7elyNsP3+YfPh+In5W4qRyxJwGlMEGrTo+Q1Af2nFh78WFTtEj1CMtA0b"}

def decrypt(decryptkey, encrypted_data):
  key = RSA.import_key(decryptkey)
  cipher = PKCS1_OAEP.new(key)
  decrypted_data = cipher.decrypt(encrypted_data)
  return decrypted_data


hosts = testdata["data"]

data = hosts.encode()
hash_object = SHA256.new(data=data)

print(hash_object.digest())

signature_decode = base64.b64decode(testdata["signature"])
print(decrypt(decryptkey, signature_decode))
