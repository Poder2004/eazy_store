"""สร้างหน้าดาวน์โหลด + QR (GitHub Pages) -- ใช้: python build.py <โฟลเดอร์ปลายทาง>

QR ชี้ไปที่ลิงก์ "latest" ของ Release จึงเหมือนเดิมทุกเวอร์ชัน
"""
import datetime
import os
import pathlib
import sys

import qrcode
from qrcode.constants import ERROR_CORRECT_M

out = pathlib.Path(sys.argv[1])
out.mkdir(parents=True, exist_ok=True)

repo = os.environ.get("REPO", "Poder2004/eazy_store")
version = os.environ.get("VERSION", "dev")
apk_url = f"https://github.com/{repo}/releases/latest/download/eazy-store.apk"

qr = qrcode.QRCode(error_correction=ERROR_CORRECT_M, box_size=12, border=2)
qr.add_data(apk_url)
qr.make(fit=True)
qr.make_image(fill_color="#1f2a10", back_color="white").save(out / "qr.png")

# ใช้เวลาไทยแสดงวันที่อัปเดต
now = datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=7)))
html = (pathlib.Path(__file__).parent / "index.template.html").read_text(encoding="utf-8")
html = (
    html.replace("{{APK_URL}}", apk_url)
    .replace("{{VERSION}}", version)
    .replace("{{DATE}}", now.strftime("%d/%m/%Y"))
)
(out / "index.html").write_text(html, encoding="utf-8")
(out / ".nojekyll").write_text("", encoding="utf-8")
print("built:", sorted(p.name for p in out.iterdir()), "->", apk_url)
