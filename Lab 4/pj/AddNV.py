import pyodbc
import hashlib
from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_OAEP
import base64
import json
import os
import sys
sys.stdout.reconfigure(encoding='utf-8')


# 🏆 SQL Server Connection
conn = pyodbc.connect("DRIVER={ODBC Driver 17 for SQL Server};SERVER=ADMIN\\SQLEXPRESS;DATABASE=QLSVNhom;Trusted_Connection=yes;")
cursor = conn.cursor()

# 🏆 Employee Data
manv = "NV07"
hoten = "NGUYEN VAN G"
email = "NVG@"
username = "NVG"

# File paths for storing keys
PRIVATE_KEY_FILE = "private.pem"
PUBLIC_KEY_FILE = "public.pem"

# ✅ **Generate or Load RSA Keys**
def generate_rsa_keys(password: str):
    """Generate RSA keys only if they don’t exist, otherwise load from file."""
    private_key = RSA.generate(2048)
    private_pem = private_key.export_key(passphrase=password, pkcs=8)
    public_pem = private_key.publickey().export_key()

    with open(PRIVATE_KEY_FILE, "wb") as f:
        f.write(private_pem)
    with open(PUBLIC_KEY_FILE, "wb") as f:
        f.write(public_pem)

    return private_pem, public_pem

# ✅ **Load Private Key From File**
def load_private_key():
    """Load the private key from file for decryption"""
    if os.path.exists(PRIVATE_KEY_FILE):
        with open(PRIVATE_KEY_FILE, "rb") as f:
            return f.read()
    return None

# ✅ **Load Public Key From File**
def get_current_public_key():
    """Load the public key from file"""
    if os.path.exists(PUBLIC_KEY_FILE):
        with open(PUBLIC_KEY_FILE, "rb") as f:
            return f.read()
    return None

# ✅ **Encrypt Salary Using Public Key**
def encrypt_salary(salary: str, public_key_pem: bytes):
    """Encrypt salary using RSA public key"""
    public_key = RSA.import_key(public_key_pem)
    cipher = PKCS1_OAEP.new(public_key)
    encrypted_salary = cipher.encrypt(salary.encode())
    return encrypted_salary  # Directly return bytes (No base64 encoding needed)

# 🔒 **Hash Password with SHA-1**
password = "asd"
hashed_password = hashlib.sha1(password.encode()).digest()
salary = "5000000"

# ✅ **Load or Generate RSA Keys**
private_key_pem, public_key_pem = generate_rsa_keys(password)


# ✅ **Encrypt Salary Using RSA**
encrypted_salary = encrypt_salary(salary, public_key_pem)
print(f"🔐 Mã hóa: {encrypted_salary}")

# ✅ **Public Key as String**
private_key = private_key_pem.decode()
print(f"🔑 Public Key: {private_key}")
public_key = public_key_pem.decode()
print(f"🔑 Public Key: {public_key}")

# 🔒 **Call Stored Procedure with Binary Data**
cursor.execute("EXEC SP_INS_PUBLIC_ENCRYPT_NHANVIEN ?, ?, ?, ?, ?, ?, ?", 
               (manv, hoten, email, encrypted_salary, username, hashed_password, public_key))

# ✅ **Commit and Close Connection**
conn.commit()
conn.close()
