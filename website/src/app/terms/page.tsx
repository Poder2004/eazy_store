import Navbar from "@/components/Navbar";

export const metadata = {
  title: "เงื่อนไขการใช้งาน - Eazy Store",
};

const sections = [
  {
    title: "1. การยอมรับเงื่อนไข",
    content:
      "การดาวน์โหลดหรือใช้งานแอพพลิเคชัน Eazy Store ถือว่าคุณยอมรับเงื่อนไขการใช้งานฉบับนี้ทั้งหมด หากไม่เห็นด้วยกับเงื่อนไขใดๆ กรุณาหยุดใช้งานแอพ",
  },
  {
    title: "2. บัญชีผู้ใช้งาน",
    content:
      "คุณต้องรับผิดชอบในการรักษาความปลอดภัยของบัญชี รวมถึงรหัสผ่านของคุณ กรุณาแจ้งทีมงานทันทีหากสงสัยว่าบัญชีถูกเข้าถึงโดยไม่ได้รับอนุญาต",
  },
  {
    title: "3. การใช้งานที่ได้รับอนุญาต",
    content:
      "แอพนี้อนุญาตให้ใช้งานเพื่อจัดการธุรกิจร้านค้าของคุณเท่านั้น ห้ามใช้งานเพื่อวัตถุประสงค์ที่ผิดกฎหมาย หรือส่งต่อข้อมูลที่เป็นเท็จ หรือกระทำการใดๆ ที่อาจก่อให้เกิดความเสียหายต่อผู้อื่น",
  },
  {
    title: "4. ทรัพย์สินทางปัญญา",
    content:
      "เนื้อหา โลโก้ ซอฟต์แวร์ และระบบทั้งหมดในแอพเป็นทรัพย์สินของ Eazy Store ห้ามทำซ้ำ ดัดแปลง หรือเผยแพร่โดยไม่ได้รับอนุญาตเป็นลายลักษณ์อักษร",
  },
  {
    title: "5. ข้อมูลร้านค้าและธุรกรรม",
    content:
      "คุณเป็นเจ้าของข้อมูลร้านค้าและธุรกรรมของคุณทั้งหมด เราเพียงแต่ให้บริการระบบจัดการข้อมูล เราแนะนำให้ Backup ข้อมูลสำคัญอย่างสม่ำเสมอ",
  },
  {
    title: "6. ข้อจำกัดความรับผิด",
    content:
      "เราไม่รับผิดชอบต่อความเสียหายทางอ้อมที่เกิดจากการใช้งานหรือไม่สามารถใช้งานแอพได้ เราพยายามอย่างยิ่งที่จะรักษาระบบให้ทำงานได้ตลอดเวลา",
  },
  {
    title: "7. การเปลี่ยนแปลงเงื่อนไข",
    content:
      "เราอาจอัปเดตเงื่อนไขนี้เป็นครั้งคราว การแจ้งเตือนจะถูกส่งผ่านแอพหรืออีเมล การใช้งานต่อเนื่องหลังจากนั้นถือว่าคุณยอมรับเงื่อนไขใหม่",
  },
  {
    title: "8. กฎหมายที่ใช้บังคับ",
    content:
      "เงื่อนไขนี้อยู่ภายใต้กฎหมายไทย ข้อพิพาทใดๆ จะได้รับการแก้ไขภายใต้เขตอำนาจศาลไทย",
  },
];

export default function TermsPage() {
  return (
    <>
      <Navbar />
      <main className="page-container">
        <div className="text-center mb-10">
          <div className="w-16 h-16 bg-purple-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <span className="text-3xl">📋</span>
          </div>
          <h1 className="text-3xl font-extrabold text-slate-800">เงื่อนไขการใช้งาน</h1>
          <p className="text-slate-500 mt-2">อัปเดตล่าสุด: มกราคม 2568</p>
        </div>

        <div className="section-card mb-6 bg-purple-50 border-purple-100">
          <p className="text-purple-700 text-sm leading-relaxed">
            กรุณาอ่านเงื่อนไขการใช้งานนี้อย่างละเอียดก่อนใช้แอพพลิเคชัน Eazy Store
            เพื่อความเข้าใจในสิทธิ์และความรับผิดชอบของคุณในฐานะผู้ใช้งาน
          </p>
        </div>

        <div className="space-y-4">
          {sections.map((section) => (
            <div key={section.title} className="section-card">
              <h2 className="text-lg font-bold text-slate-800 mb-3">{section.title}</h2>
              <p className="text-slate-600 text-sm leading-relaxed">{section.content}</p>
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
