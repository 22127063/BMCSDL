import pyodbc
import tkinter as tk
from tkinter import messagebox
import hashlib
import base64
import json
import os
from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_OAEP
import sys
sys.stdout.reconfigure(encoding='utf-8')


# File paths for storing RSA keys
PRIVATE_KEY_FILE = "private.pem"
PUBLIC_KEY_FILE = "public.pem"

# Global variables for user session
current_manv = None
current_tendn = None
public_key_pem = None
private_key_pem = None  
password = None  # Stores user password for decryption

# Caching for performance
KEY_CACHE = {}

# ✅ **Database Connection**
def connect_db():
    return pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=ADMIN\\SQLEXPRESS;"
        "DATABASE=QLSVNhom;"
        "Trusted_Connection=yes;"
    )

# ✅ **Load or Generate RSA Keys**
def generate_rsa_keys(password: str):
    """Generate RSA keys only if they don’t exist, otherwise load from file."""
    if os.path.exists(PRIVATE_KEY_FILE) and os.path.exists(PUBLIC_KEY_FILE):
        with open(PRIVATE_KEY_FILE, "rb") as f:
            private_pem = f.read()
        with open(PUBLIC_KEY_FILE, "rb") as f:
            public_pem = f.read()
    else:
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
    if "private_key" in KEY_CACHE:
        return KEY_CACHE["private_key"]
    
    if os.path.exists(PRIVATE_KEY_FILE):
        with open(PRIVATE_KEY_FILE, "rb") as f:
            private_pem = f.read()
        KEY_CACHE["private_key"] = private_pem
        return private_pem
    return None

# ✅ **Load Public Key From File**
def get_current_public_key():
    if "public_key" in KEY_CACHE:
        return KEY_CACHE["public_key"]
    
    if os.path.exists(PUBLIC_KEY_FILE):
        with open(PUBLIC_KEY_FILE, "rb") as f:
            public_pem = f.read()
        KEY_CACHE["public_key"] = public_pem
        return public_pem
    return None

# ✅ **Encrypt Data with Public Key**
def rsa_encrypt(data: str, public_key_pem: bytes):
    public_key = RSA.import_key(public_key_pem)
    cipher = PKCS1_OAEP.new(public_key)
    encrypted_data = cipher.encrypt(data.encode())
    return encrypted_data

# ✅ **Decrypt Data with Private Key**
def rsa_decrypt(encrypted_data: bytes, private_key_pem: bytes, password: str):
    private_key = RSA.import_key(private_key_pem, passphrase=password)
    cipher = PKCS1_OAEP.new(private_key)
    decrypted_data = cipher.decrypt(encrypted_data).decode()
    return decrypted_data

# ✅ **Login Function**
def login():
    global current_manv, current_tendn, public_key_pem, private_key_pem, password
    tendn = entry_tendn.get()
    mk = entry_matkhau.get()
    mk_hashed = hashlib.sha1(mk.encode()).digest()

    conn = connect_db()
    cursor = conn.cursor()

    try:
        cursor.execute("EXEC SP_LOGIN_PUBLIC_ENCRYPT_NHANVIEN ?, ?", (tendn, mk_hashed))
        result = cursor.fetchone()
    except Exception as e:
        messagebox.showerror("Lỗi", f"Lỗi truy vấn: {e}")
        return
    finally:
        conn.close()

    if not result or result[0] == -1:
        messagebox.showerror("Lỗi", "Sai tài khoản hoặc mật khẩu!")
    else:
        current_manv = result[1]
        current_tendn = tendn
        messagebox.showinfo("Thành công", f"Đăng nhập thành công!\nTên: {result[2]}")
        
        private_key_pem = load_private_key()
        public_key_pem = get_current_public_key()
        password = mk  

        root_login.destroy()
        open_class_management()

# ✅ **Load Classes**
def load_classes():
    if not current_manv:
        messagebox.showerror("Lỗi", "Vui lòng đăng nhập trước!")
        return

    conn = connect_db()
    cursor = conn.cursor()
    
    try:
        cursor.execute("SELECT MALOP, TENLOP FROM LOP WHERE MANV = ?", (current_manv,))
        classes = cursor.fetchall()
        conn.close()

        listbox_classes.delete(0, tk.END)
        for lop in classes:
            listbox_classes.insert(tk.END, f"{lop[0]} - {lop[1]}")
    except Exception as e:
        messagebox.showerror("Lỗi", str(e))
        conn.close()

# ✅ **Manage Classes UI**
def open_class_management():
    global listbox_classes  # Khai báo biến toàn cục

    root_class = tk.Tk()
    root_class.title("Quản lý Lớp học")
    
    tk.Label(root_class, text="Mã lớp:").grid(row=0, column=0)
    entry_malop = tk.Entry(root_class)
    entry_malop.grid(row=0, column=1)

    tk.Label(root_class, text="Tên lớp:").grid(row=1, column=0)
    entry_tenlop = tk.Entry(root_class)
    entry_tenlop.grid(row=1, column=1)

    tk.Button(root_class, text="Thêm lớp", command=lambda: execute_sp("SP_INS_LOP", entry_malop.get(), entry_tenlop.get(), current_manv)).grid(row=2, column=0)
    tk.Button(root_class, text="Cập nhật lớp", command=lambda: execute_sp("SP_UPDATE_LOP", entry_malop.get(), entry_tenlop.get(), current_manv)).grid(row=2, column=1)
    tk.Button(root_class, text="Xóa lớp", command=lambda: execute_sp("SP_DEL_LOP", entry_malop.get(), current_manv)).grid(row=2, column=2)

    listbox_classes = tk.Listbox(root_class, width=50, height=10)
    listbox_classes.grid(row=3, column=0, columnspan=3, padx=5, pady=10)

    tk.Button(root_class, text="Tải danh sách lớp", command=load_classes).grid(row=4, column=0, columnspan=3, pady=10)

    # Thêm nút mở giao diện sinh viên
    tk.Button(root_class, text="Quản lý Sinh viên", command=open_student_management).grid(row=5, column=0, columnspan=3, pady=10)

    load_classes()  # Gọi để tự động tải danh sách lớp khi mở màn hình

    root_class.mainloop()

# Lấy danh sách sinh viên trong lớp do nhân viên quản lý
def load_students():
    if not current_manv:
        messagebox.showerror("Lỗi", "Vui lòng đăng nhập trước!")
        return

    conn = connect_db()
    cursor = conn.cursor()

    try:
        cursor.execute("EXEC SP_SEL_SINHVIEN_LOP ?", (current_manv,))
        students = cursor.fetchall()
        conn.close()

        listbox_students.delete(0, tk.END)  # Xóa danh sách cũ

        if not students:  # Nếu danh sách rỗng, hiển thị thông báo
            messagebox.showwarning("Thông báo", "Không có sinh viên nào trong lớp của bạn.")
            return

        for sv in students:
            listbox_students.insert(tk.END, f"{sv[0]} - {sv[1]} ({sv[4]})")

    except Exception as e:
        messagebox.showerror("Lỗi", f"Lỗi khi tải danh sách sinh viên: {str(e)}")
        conn.close()

# ✅ **Manage Students UI**
def open_student_management():
    global listbox_students  # Khai báo biến toàn cục

    root_student = tk.Tk()
    root_student.title("Quản lý Sinh viên")

    tk.Label(root_student, text="Mã SV:").grid(row=0, column=0)
    entry_masv = tk.Entry(root_student)
    entry_masv.grid(row=0, column=1)

    tk.Label(root_student, text="Họ Tên:").grid(row=1, column=0)
    entry_hoten = tk.Entry(root_student)
    entry_hoten.grid(row=1, column=1)

    tk.Label(root_student, text="Ngày Sinh:").grid(row=2, column=0)
    entry_ngaysinh = tk.Entry(root_student)
    entry_ngaysinh.grid(row=2, column=1)

    tk.Label(root_student, text="Địa Chỉ:").grid(row=3, column=0)
    entry_diachi = tk.Entry(root_student)
    entry_diachi.grid(row=3, column=1)

    tk.Label(root_student, text="Mã Lớp:").grid(row=4, column=0)
    entry_malop = tk.Entry(root_student)
    entry_malop.grid(row=4, column=1)
    
    tk.Button(root_student, text="Thêm sinh viên", command=lambda: execute_sp("SP_INS_SINHVIEN", entry_masv.get(), entry_hoten.get(), entry_ngaysinh.get(), entry_diachi.get(), entry_malop.get(), current_manv)).grid(row=5, column=0)
    tk.Button(root_student, text="Cập nhật sinh viên", command=lambda: execute_sp("SP_UPDATE_SINHVIEN", entry_masv.get(), entry_hoten.get(), entry_ngaysinh.get(), entry_diachi.get(), current_manv)).grid(row=5, column=1)
    tk.Button(root_student, text="Xóa sinh viên", command=lambda: execute_sp("SP_DELETE_SINHVIEN", entry_masv.get(), current_manv)).grid(row=5, column=2)

    listbox_students = tk.Listbox(root_student, width=50, height=10)
    listbox_students.grid(row=6, column=0, columnspan=3, padx=5, pady=10)

    tk.Button(root_student, text="Tải danh sách", command=load_students).grid(row=9, column=0, columnspan=3, pady=10)
    
    # Thêm nút mở giao diện nhập điểm
    tk.Button(root_student, text="Nhập điểm", command=open_score_management).grid(row=11, column=0, columnspan=3, pady=10)

    # Gọi load_students() khi mở giao diện
    load_students()

    root_student.mainloop()

def view_score(masv, mahp):
    conn = connect_db()
    cursor = conn.cursor()
    cursor.execute("EXEC SP_SEL_PUBLIC_ENCRYPT_BANGDIEM ?, ?, ?", (masv, mahp, current_manv))
    result = cursor.fetchone()
    conn.close()



    if result:
        masv, mahp, encrypted_score = result
        print(f"🔍 Encrypted Score (from SQL, Length: {len(encrypted_score)}): {encrypted_score}")

        # 🏆 **Decrypt Score Using RSA**
        try:
            decrypted_score = rsa_decrypt(encrypted_score, private_key_pem, password)
            print(f"✅ Điểm được giải mã: {decrypted_score}")
            messagebox.showinfo("Điểm Thi", f"Điểm của sinh viên {result[0]} (Môn {result[1]}): {decrypted_score}")
        except Exception as e:
            print(f"❌ Decryption Failed: {e}")
            messagebox.showerror("Lỗi", "Lỗi khi giải mã điểm!")

    else:
        messagebox.showerror("Lỗi", "Không tìm thấy điểm!")




# ✅ **Manage Scores UI**
def open_score_management():
    root_score = tk.Tk()
    root_score.title("Nhập điểm sinh viên")

    tk.Label(root_score, text="Mã SV:").grid(row=0, column=0)
    entry_masv = tk.Entry(root_score)
    entry_masv.grid(row=0, column=1)

    tk.Label(root_score, text="Mã HP:").grid(row=1, column=0)
    entry_mahp = tk.Entry(root_score)
    entry_mahp.grid(row=1, column=1)

    tk.Label(root_score, text="Điểm:").grid(row=2, column=0)
    entry_diemthi = tk.Entry(root_score)
    entry_diemthi.grid(row=2, column=1)

    def insert_score():
        diemthi_plaintext = entry_diemthi.get().strip()  # Loại bỏ khoảng trắng

        # 🛑 Nếu ô điểm trống, hiển thị thông báo và không mã hóa
        if not diemthi_plaintext:
            messagebox.showerror("Lỗi", "Vui lòng nhập điểm!")
            return  

        print(f"📝 Original Score: {diemthi_plaintext}")

        diemthi_encrypted = rsa_encrypt(diemthi_plaintext, public_key_pem)
        print(f"🔒 Encrypted Score (Length: {len(diemthi_encrypted)}): {diemthi_encrypted}")

        execute_sp("SP_INS_PUBLIC_ENCRYPT_BANGDIEM", entry_masv.get(), entry_mahp.get(), diemthi_encrypted)

    tk.Button(root_score, text="Nhập điểm", command=insert_score).grid(row=3, column=0)
    tk.Button(root_score, text="Xem điểm", command=lambda: view_score(entry_masv.get(), entry_mahp.get())).grid(row=3, column=1)

    root_score.mainloop()


# Thực thi stored procedure (Dùng cho INSERT, UPDATE, DELETE)
def execute_sp(sp_name, *args):
    conn = None
    try:
        conn = connect_db()
        cursor = conn.cursor()

        # Thực thi stored procedure
        cursor.execute(f"EXEC {sp_name} " + ", ".join(["?"] * len(args)), args)
        result = cursor.fetchone()  # Lấy kết quả từ stored procedure
        conn.commit()

        # Kiểm tra kết quả trả về
        if result and result[0] == -1:
            messagebox.showwarning("Cảnh báo", f"{sp_name} thất bại: Dữ liệu không tồn tại hoặc bạn không có quyền!")
        elif result and result[0] == -2:
            messagebox.showwarning("Cảnh báo", f"{sp_name} thất bại: Dữ liệu đã tồn tại!")
        else:
            messagebox.showinfo("Thành công", f"Thực hiện {sp_name} thành công!")

    except Exception as e:
        messagebox.showerror("Lỗi", f"Lỗi khi thực thi {sp_name}: {str(e)}")
    finally:
        if conn:
            conn.close()

# Giao diện đăng nhập
root_login = tk.Tk()
root_login.title("Đăng nhập nhân viên")

tk.Label(root_login, text="Tên đăng nhập:").grid(row=0, column=0)
entry_tendn = tk.Entry(root_login)
entry_tendn.grid(row=0, column=1)

tk.Label(root_login, text="Mật khẩu:").grid(row=1, column=0)
entry_matkhau = tk.Entry(root_login, show="*")
entry_matkhau.grid(row=1, column=1)

tk.Button(root_login, text="Đăng nhập", command=login).grid(row=2, column=0, columnspan=2)

root_login.mainloop()