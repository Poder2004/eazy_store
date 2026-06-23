import Navbar from "@/components/Navbar";

export const metadata = {
  title: "นโยบายความเป็นส่วนตัว - Eazy Store",
};

const sections = [
  {
    title: "1. ข้อมูลที่เราเก็บรวบรวม",
    content: [
      "**ข้อมูลบัญชีผู้ใช้:** ชื่อ อีเมล เบอร์โทรศัพท์ ที่คุณกรอกตอนสมัครใช้งาน",
      "**ข้อมูลร้านค้า:** ชื่อร้าน ที่อยู่ โลโก้ร้านค้า และข้อมูลสาขา",
      "**ข้อมูลธุรกรรม:** รายการขาย รายการสินค้า และยอดขาย เพื่อการวิเคราะห์และรายงาน",
      "**ข้อมูลการใช้งาน:** Log การเข้าสู่ระบบ และการใช้งานฟีเจอร์ต่างๆ",
    ],
  },
  {
    title: "2. วิธีที่เราใช้ข้อมูล",
    content: [
      "ให้บริการและพัฒนาฟีเจอร์ของแอพพลิเคชัน",
      "วิเคราะห์และปรับปรุงประสิทธิภาพของระบบ",
      "ให้การสนับสนุนทางเทคนิคและตอบคำถาม",
    ],
  },
  {
    title: "3. การแบ่งปันข้อมูล",
    content: [
      "เราไม่ขายหรือแบ่งปันข้อมูลส่วนตัวของคุณให้บุคคลภายนอก",
      "เราอาจส่งต่อหรือเปิดเผยข้อมูลให้แก่ผู้ให้บริการภายนอกที่เกี่ยวข้องกับการดำเนินงานของเรา เช่น ผู้ให้บริการระบบจัดเก็บข้อมูล (Cloud Storage)",
      "เราอาจเปิดเผยข้อมูลส่วนบุคคล หากมีความจำเป็นเพื่อปฏิบัติตามกฎหมายหรือคำสั่งศาล",
    ],
  },
  {
    title: "4. ความปลอดภัยของข้อมูล",
    content: [
      "ข้อมูลส่วนบุคคลทั้งหมดจะได้รับการเข้ารหัสระหว่างการส่งผ่านเครือข่าย (Data in Transit) ด้วยโปรโตคอล HTTPS/TLS HTTPS/TLS",
      "ข้อมูลรหัสผ่านจะถูกจัดเก็บด้วยการแฮชข้อมูล (One-way Hashing Algorithm) ซึ่งไม่สามารถถอดรหัสกลับได้",
      "เรามีการทบทวน ประเมิน และปรับปรุงมาตรการรักษาความปลอดภัยทางเทคนิคอย่างต่อเนื่อง เพื่อให้สอดคล้องกับมาตรฐานสากล",
    ],
  },
  {
    title: "5. สิทธิ์ของคุณ",
    content: [
      "**ขอดูข้อมูล:** คุณมีสิทธิ์ขอดูข้อมูลที่เราเก็บ",
      "**แก้ไขข้อมูล:** สามารถแก้ไขข้อมูลส่วนตัวได้จากหน้าโปรไฟล์",
      "**ลบข้อมูล:** สามารถขอลบบัญชีและข้อมูลทั้งหมดได้โดยติดต่อทีมงาน",
    ],
  },
  {
    title: "6. การติดต่อ",
    content: [
      "หากมีคำถามเกี่ยวกับนโยบายนี้ ติดต่อเราได้ที่หน้า ติดต่อเรา",
    ],
  },
];

export default function PrivacyPage() {
  return (
    <>
      <Navbar />
      <main className="page-container">
        {/* Header */}
        <div className="text-center mb-10">
          <div className="w-16 h-16 bg-indigo-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <span className="text-3xl">🔒</span>
          </div>
          <h1 className="text-3xl font-extrabold text-slate-800">นโยบายความเป็นส่วนตัว</h1>
          <p className="text-slate-500 mt-2">อัปเดตล่าสุด: มกราคม 2568</p>
        </div>

        <div className="section-card mb-6 bg-indigo-50 border-indigo-100">
          <p className="text-indigo-700 text-sm leading-relaxed">
            Eazy Store ให้ความสำคัญกับความเป็นส่วนตัวของคุณ
            เอกสารนี้อธิบายถึงข้อมูลที่เราเก็บรวบรวม วิธีการใช้งาน
            และสิทธิ์ที่คุณมีเกี่ยวกับข้อมูลของคุณ
          </p>
        </div>

        <div className="space-y-4">
          {sections.map((section) => (
            <div key={section.title} className="section-card">
              <h2 className="text-lg font-bold text-slate-800 mb-4">{section.title}</h2>
              <ul className="space-y-2">
                {section.content.map((item, i) => (
                  <li key={i} className="flex gap-3 text-slate-600 text-sm leading-relaxed">
                    <span className="text-indigo-400 mt-1 flex-shrink-0">•</span>
                    <span dangerouslySetInnerHTML={{ __html: item.replace(/\*\*(.*?)\*\*/g, "<strong>$1</strong>") }} />
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </main>
      <footer className="border-t border-gray-100 py-8 text-center text-sm text-slate-400 mt-8">
        © {new Date().getFullYear()} Eazy Store. สงวนลิขสิทธิ์.
      </footer>
    </>
  );
}
