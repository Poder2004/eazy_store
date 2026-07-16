import Link from "next/link";
import Navbar from "@/components/Navbar";

export const metadata = {
  title: "ศูนย์ช่วยเหลือ - Eazy Store",
};

const faqs = [
  {
    category: "การเริ่มต้นใช้งาน",
    icon: "🚀",
    color: "bg-indigo-50 text-indigo-600",
    items: [
      {
        q: "วิธีสมัครใช้งาน Eazy Store?",
        a: "ดาวน์โหลดแอพจาก App Store หรือ Play Store แล้วกดสมัครสมาชิก กรอกชื่อ อีเมล และรหัสผ่าน จากนั้นยืนยันอีเมล แล้วเข้าสู่ระบบได้เลย",
      },
      {
        q: "ฉันสามารถใช้งานกี่ร้านในบัญชีเดียว?",
        a: "1 บัญชีสามารถจัดการได้หลายร้านค้า สามารถสลับร้านได้จากหน้าโปรไฟล์",
      },
      
    ],
  },
  {
    category: "การขายและออกบิล",
    icon: "🧾",
    color: "bg-emerald-50 text-emerald-600",
    items: [
      {
        q: "วิธีออกบิลขาย?",
        a: "ไปที่หน้าขายสินค้า เลือกสินค้า ใส่จำนวน แล้วทำการกดยืนยันการทำรายการ บิลจะถูกสร้างเพื่อบันทึกประวัติทันที",
      },
      {
        q: "สามารถพิมพ์ใบเสร็จได้ไหม?",
        a: "แอป Eazy Store เน้นการจัดการและบันทึกประวัติการขายแบบดิจิทัลเพื่อความสะดวกรวดเร็ว จึงไม่มีระบบพิมพ์ใบเสร็จ แต่สามารถตรวจสอบรายการขายย้อนหลังทั้งหมดได้จากแท็บ 'บัญชี'",
      },
      {
        q: "สามารถตรวจสอบรายการขายย้อนหลังได้ที่ไหน?",
        a: "สามารถเข้าไปดูรายละเอียดประวัติการขาย บิล รายการสินค้า ยอดขาย ต้นทุน และกำไรได้ที่แท็บ 'บัญชี' ในแอปพลิเคชัน",
      },
    ],
  },
  {
    category: "สินค้าและคลังสินค้า",
    icon: "📦",
    color: "bg-sky-50 text-sky-600",
    items: [
      {
        q: "วิธีเพิ่มสินค้าใหม่?",
        a: "ไปที่เมนูสินค้า กดปุ่ม + กรอกชื่อ ราคา และสต็อก แล้วกดบันทึก สินค้าจะแสดงในหน้าขายทันที",
      },
      {
        q: "สแกนบาร์โค้ดสินค้าได้ไหม?",
        a: "ได้ แอพรองรับการสแกนบาร์โค้ดทั้งในหน้าขายและหน้าจัดการสินค้า",
      },
    ],
  },
  {
    category: "บัญชีและความปลอดภัย",
    icon: "🔐",
    color: "bg-purple-50 text-purple-600",
    items: [
      {
        q: "ลืมรหัสผ่านทำอย่างไร?",
        a: "ในหน้าเข้าสู่ระบบ กด 'ลืมรหัสผ่าน' กรอกอีเมลที่ลงทะเบียนไว้ ระบบจะส่ง link รีเซ็ตรหัสผ่านไปให้",
      },
      {
        q: "เปลี่ยนอีเมลบัญชีได้ไหม?",
        a: "สามารถเปลี่ยนได้ทางหมวดแก้ไขข้อมูลส่วนตัว"
      },
    ],
  },
];

export default function SupportPage() {
  return (
    <>
      <Navbar />
      <main className="page-container">
        <div className="text-center mb-10">
          <div className="w-16 h-16 bg-sky-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <span className="text-3xl">🎧</span>
          </div>
          <h1 className="text-3xl font-extrabold text-slate-800">ศูนย์ช่วยเหลือ</h1>
          <p className="text-slate-500 mt-2 text-sm max-w-md mx-auto leading-relaxed">
            คำถามที่พบบ่อยและแนวทางแก้ไขปัญหาการใช้งาน
          </p>
        </div>

        <div className="space-y-6">
          {faqs.map((group) => (
            <div key={group.category}>
              <div className="flex items-center gap-3 mb-3">
                <div className={`w-9 h-9 rounded-xl flex items-center justify-center text-lg ${group.color}`}>
                  {group.icon}
                </div>
                <h2 className="font-bold text-slate-700">{group.category}</h2>
              </div>
              <div className="space-y-3">
                {group.items.map((item) => (
                  <details
                    key={item.q}
                    className="section-card group cursor-pointer"
                  >
                    <summary className="font-semibold text-slate-700 text-sm flex items-center justify-between list-none select-none">
                      {item.q}
                      <span className="text-slate-400 text-lg group-open:rotate-45 transition-transform duration-200 flex-shrink-0 ml-2">
                        +
                      </span>
                    </summary>  
                    <p className="text-slate-500 text-sm mt-3 leading-relaxed border-t border-gray-100 pt-3">
                      {item.a}
                    </p>
                  </details>
                ))}
              </div>
            </div>
          ))}
        </div>

        {/* Still need help */}
        <div className="section-card mt-8 bg-gradient-to-r from-[#4F46E5]/5 to-[#6366F1]/5 border-indigo-100 text-center">
          <h3 className="font-bold text-slate-800 text-lg mb-2">ยังมีคำถามอื่นอีกไหม?</h3>
          <p className="text-slate-500 text-sm mb-4">ทีมงานพร้อมช่วยเหลือคุณผ่านช่องทางการติดต่อต่างๆ</p>
          <Link
            href="/contact"
            className="inline-block bg-[#4F46E5] text-white px-6 py-3 rounded-xl font-semibold text-sm hover:bg-[#4338CA] transition-colors"
          >
            ติดต่อทีมงาน
          </Link>
        </div>
      </main>
      <footer className="border-t border-gray-100 py-8 text-center text-sm text-slate-400 mt-8">
        © {new Date().getFullYear()} Eazy Store. สงวนลิขสิทธิ์.
      </footer>
    </>
  );
}
