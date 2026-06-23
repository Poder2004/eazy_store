import Link from "next/link";
import Navbar from "@/components/Navbar";

const cards = [
  {
    href: "/privacy",
    icon: "🔒",
    title: "นโยบายความเป็นส่วนตัว",
    desc: "ข้อมูลที่เราเก็บรวบรวม วิธีการใช้งาน และสิทธิ์ของคุณ",
    color: "bg-indigo-50 text-indigo-600",
    border: "border-indigo-100",
  },
  {
    href: "/terms",
    icon: "📋",
    title: "เงื่อนไขการใช้งาน",
    desc: "ข้อกำหนดและเงื่อนไขการใช้แอพพลิเคชัน Eazy Store",
    color: "bg-purple-50 text-purple-600",
    border: "border-purple-100",
  },
  {
    href: "/contact",
    icon: "💬",
    title: "ช่องทางการติดต่อ",
    desc: "ติดต่อทีมงานผ่านช่องทางต่างๆ ที่คุณสะดวก",
    color: "bg-emerald-50 text-emerald-600",
    border: "border-emerald-100",
  },
  {
    href: "/support",
    icon: "🎧",
    title: "ศูนย์ช่วยเหลือ",
    desc: "คำถามที่พบบ่อย และแนวทางแก้ไขปัญหาการใช้งาน",
    color: "bg-sky-50 text-sky-600",
    border: "border-sky-100",
  },
];

export default function Home() {
  return (
    <>
      <Navbar />
      <main>
        {/* Hero */}
        <section className="bg-gradient-to-br from-[#4F46E5] to-[#6366F1] text-white py-20 px-4">
          <div className="max-w-3xl mx-auto text-center">
            <div className="w-20 h-20 bg-white/20 rounded-2xl flex items-center justify-center mx-auto mb-6">
              <span className="text-4xl">🏪</span>
            </div>
            <h1 className="text-4xl font-extrabold mb-4">Eazy Store</h1>
            <p className="text-indigo-100 text-lg max-w-xl mx-auto leading-relaxed">
              แอพพลิเคชันจัดการร้านค้า ออกบิล และติดตามยอดขายอย่างง่ายดาย
            </p>
          </div>
        </section>

        {/* Cards */}
        <section className="max-w-5xl mx-auto px-4 py-16">
          <h2 className="text-center text-2xl font-bold text-slate-700 mb-10">
            ข้อมูลสำหรับผู้ใช้งาน
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
            {cards.map((card) => (
              <Link
                key={card.href}
                href={card.href}
                className={`section-card border ${card.border} flex items-start gap-4 hover:shadow-md hover:-translate-y-1 transition-all duration-200 group`}
              >
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center text-2xl flex-shrink-0 ${card.color}`}>
                  {card.icon}
                </div>
                <div>
                  <h3 className="font-bold text-slate-800 text-lg group-hover:text-[#4F46E5] transition-colors">
                    {card.title}
                  </h3>
                  <p className="text-slate-500 text-sm mt-1 leading-relaxed">{card.desc}</p>
                </div>
              </Link>
            ))}
          </div>
        </section>
      </main>

      <footer className="border-t border-gray-100 py-8 text-center text-sm text-slate-400">
        © {new Date().getFullYear()} Eazy Store. สงวนลิขสิทธิ์.
      </footer>
    </>
  );
}
