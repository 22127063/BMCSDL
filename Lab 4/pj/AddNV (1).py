import pyodbc
import hashlib
import json
import os
import base64
import sys
from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_OAEP

sys.stdout.reconfigure(encoding="utf-8")

# 🏆 SQL Server Connection
conn = pyodbc.connect("DRIVER={ODBC Driver 17 for SQL Server};SERVER=ADMIN\SQLEXPRESS;DATABASE=QLSVNhom;Trusted_Connection=yes;")
cursor = conn.cursor()

# 🏆 Employee Data
manv = "NV14"
hoten = "NGUYEN VAN AD"
email = "NVAD@"
username = "NVAD"

# 🔹 File lưu trữ nhiều khóa
KEYS_FILE = "rsa_keys.json"
KEY_CACHE = {}

# ✅ **Load All Keys from JSON**
def load_keys():
    """Load all keys from the JSON file into cache."""
    if os.path.exists(KEYS_FILE):
        try:
            with open(KEYS_FILE, "r") as f:
                KEY_CACHE.update(json.load(f))
        except json.JSONDecodeError:
            print("🔴 Error: Corrupted key file, resetting...")
            with open(KEYS_FILE, "w") as f:
                json.dump({}, f)  # Reset file
    else:
        with open(KEYS_FILE, "w") as f:
            json.dump({}, f)  # Create empty JSON file

def save_keys():
    """Save the current cache to the JSON file."""
    with open(KEYS_FILE, "w") as f:
        json.dump(KEY_CACHE, f, indent=4)

# ✅ **Generate or Load RSA Keys**
def generate_rsa_keys(username: str, password: str):
    """Generate RSA keys for a specific user if they don’t exist, otherwise load from cache."""
    load_keys()  # Load keys into cache

    if username in KEY_CACHE:
        print(f"🟢 RSA keys for {username} loaded from file.")
        private_pem = base64.b64decode(KEY_CACHE[username]["private_key"])
        public_pem = base64.b64decode(KEY_CACHE[username]["public_key"])
        return private_pem, public_pem

    # Generate new RSA keys
    private_key = RSA.generate(2048)
    private_pem = private_key.export_key(passphrase=password, pkcs=8)
    public_pem = private_key.publickey().export_key()

    # Encode keys to Base64 for JSON storage
    KEY_CACHE[username] = {
        "private_key": base64.b64encode(private_pem).decode(),
        "public_key": base64.b64encode(public_pem).decode()
    }

    save_keys()
    print(f"🟢 RSA keys for {username} generated and saved.")
    return private_pem, public_pem

# ✅ **Load Private Key**
def load_private_key(username: str):
    """Load the private key for a specific user."""
    load_keys()
    if username in KEY_CACHE:
        return base64.b64decode(KEY_CACHE[username]["private_key"])
    return None

# ✅ **Load Public Key**
def get_current_public_key(username: str):
    """Load the public key for a specific user."""
    load_keys()
    if username in KEY_CACHE:
        return base64.b64decode(KEY_CACHE[username]["public_key"])
    return None

# ✅ **Encrypt Salary Using Public Key**
def encrypt_salary(salary: str, public_key_pem: bytes):
    """Encrypt salary using RSA public key"""
    public_key = RSA.import_key(public_key_pem)
    cipher = PKCS1_OAEP.new(public_key)
    encrypted_salary = cipher.encrypt(salary.encode())
    return encrypted_salary  # Trả về dữ liệu nhị phân

# 🔒 **Hash Password with SHA-1**
password = "asd"
hashed_password = hashlib.sha1(password.encode()).digest()
salary = "5000000"

# ✅ **Load or Generate RSA Keys**
private_key_pem, public_key_pem = generate_rsa_keys(username, password)

# ✅ **Encrypt Salary Using RSA**
encrypted_salary = encrypt_salary(salary, public_key_pem)
print(f"🔐 Mã hóa lương: {encrypted_salary}")

# ✅ **Hiển thị khóa**
print(f"🔑 Private Key:\n{private_key_pem.decode()}")
print(f"🔑 Public Key:\n{public_key_pem.decode()}")

# 🔒 **Gọi Stored Procedure với dữ liệu đã mã hóa**
cursor.execute("EXEC SP_INS_PUBLIC_ENCRYPT_NHANVIEN ?, ?, ?, ?, ?, ?, ?", 
               (manv, hoten, email, encrypted_salary, username, hashed_password, public_key_pem.decode()))

# ✅ **Commit và Đóng kết nối**
conn.commit()
conn.close()
