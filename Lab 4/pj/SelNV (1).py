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
username = "CCC"
password = "asd"

# 🔹 File lưu trữ nhiều khóa
KEYS_FILE = "rsa_keys.json"
KEY_CACHE = {}

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

def load_private_key(username: str):
    """Load the private key for a specific user."""
    load_keys()
    if username in KEY_CACHE:
        return base64.b64decode(KEY_CACHE[username]["private_key"])
    print("❌ Không tìm thấy khóa riêng của người dùng!")
    return None

def decrypt_salary(encrypted_salary: bytes, private_key_pem: bytes, password: str):
    """Decrypt salary using RSA private key."""
    try:
        private_key = RSA.import_key(private_key_pem, passphrase=password)
        cipher = PKCS1_OAEP.new(private_key)
        decrypted_salary = cipher.decrypt(encrypted_salary).decode()
        return decrypted_salary
    except ValueError:
        return "❌ Lỗi giải mã! Sai mật khẩu hoặc khóa không khớp."
    except Exception as e:
        return f"❌ Lỗi khác: {e}"

# ✅ **Băm mật khẩu SHA-1**
hashed_password = hashlib.sha1(password.encode()).digest()

# 🔍 **Gọi Stored Procedure lấy dữ liệu**
try:
    cursor.execute("EXEC SP_SEL_PUBLIC_ENCRYPT_NHANVIEN ?, ?", (username, hashed_password))
    rows = cursor.fetchall()
except Exception as e:
    print(f"❌ Lỗi truy vấn CSDL: {e}")
    conn.close()
    exit()

# 📌 **Kiểm tra kết quả**
if not rows or rows[0][0] == -1:
    print("❌ Sai tên đăng nhập hoặc mật khẩu!")
    conn.close()
    exit()

# ✅ **Load Private Key**
private_key_pem = load_private_key(username)
if not private_key_pem:
    conn.close()
    exit()

# 🏆 **Xử lý dữ liệu nhân viên**
for row in rows:
    manv, hoten, email, encrypted_salary = row

    # 🔍 **Kiểm tra kiểu dữ liệu**
    if isinstance(encrypted_salary, memoryview):
        encrypted_salary = encrypted_salary.tobytes()  # Chuyển đổi memoryview -> bytes

    # 🏆 **Giải mã lương**
    decrypted_salary = decrypt_salary(encrypted_salary, private_key_pem, password)
    print(f"✅ Mã NV: {manv}, Họ Tên: {hoten}, Email: {email}, Lương: {decrypted_salary}")

# ✅ **Đóng kết nối**
conn.close()