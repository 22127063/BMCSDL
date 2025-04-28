import pyodbc
import hashlib
import base64
import json
import os
from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_OAEP
import sys
sys.stdout.reconfigure(encoding='utf-8')

# 🏆 SQL Server Connection
conn = pyodbc.connect("DRIVER={ODBC Driver 17 for SQL Server};SERVER=ADMIN\\SQLEXPRESS;DATABASE=QLSVNhom;Trusted_Connection=yes;")
cursor = conn.cursor()

# 🏆 Login Credentials
username = "NVG"
password = "asd"

# File paths for storing keys
PRIVATE_KEY_FILE = "private.pem"
PUBLIC_KEY_FILE = "public.pem"

# ✅ **Load Private Key From File**
def load_private_key():
    """Load the private key from file for decryption"""
    if os.path.exists(PRIVATE_KEY_FILE):
        with open(PRIVATE_KEY_FILE, "rb") as f:
            return f.read()
    return None

# ✅ **Decrypt Salary Using Private Key**
def decrypt_salary(encrypted_salary: bytes, private_key_pem: bytes, password: str):
    """Decrypt salary using RSA private key"""
    private_key = RSA.import_key(private_key_pem, passphrase=password)
    cipher = PKCS1_OAEP.new(private_key)
    decrypted_salary = cipher.decrypt(encrypted_salary).decode()
    return decrypted_salary

# ✅ **Hash Password with SHA-1**
hashed_password = hashlib.sha1(password.encode()).digest()

# 🔍 **Call Stored Procedure to Fetch Encrypted Data**
cursor.execute("EXEC SP_SEL_PUBLIC_ENCRYPT_NHANVIEN ?, ?", (username, hashed_password))
rows = cursor.fetchall()

# 📌 **Check Query Results**
if not rows or rows[0][0] == -1:
    print("❌ Sai tên đăng nhập hoặc mật khẩu!")
else:
    # ✅ **Load Private Key for Decryption**
    private_key_pem = load_private_key()
    if not private_key_pem:
        print("❌ Không tìm thấy private key! Vui lòng kiểm tra lại.")
        conn.close()
        exit()

    # 🏆 **Process Employee Data**
    for row in rows:
        manv, hoten, email, encrypted_salary = row
        
        # 🏆 **Decrypt Salary**
        try:
            decrypted_salary = decrypt_salary(encrypted_salary, private_key_pem, password)
            print(f"✅ Mã NV: {manv}, Họ Tên: {hoten}, Email: {email}, Lương: {decrypted_salary}")
        except Exception as e:
            print(f"❌ Lỗi giải mã lương: {e}")

# ✅ **Close Connection**
conn.close()
