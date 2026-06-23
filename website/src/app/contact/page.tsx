import Navbar from "@/components/Navbar";

export const metadata = {
  title: "ติดต่อเรา - Eazy Store",
};

const channels = [
  {
    icon: "📧",
    title: "อีเมล",
    subtitle: "ตอบกลับภายใน 24 ชั่วโมง",
    value: "support@eazystore.app",
    href: "mailto:support@eazystore.app",
    color: "bg-indigo-50 border-indigo-100",
    badge: "indigo",
  },
  {
    icon: "💬",
    title: "LINE Official",
    subtitle: "พูดคุยทันที จ-ศ 9:00-18:00 น.",
    value: "@eazystore",
    href: "https://line.me/ti/p/@eazystore",
    color: "bg-green-50 border-green-100",
    badge: "green",
  },
  {
    icon: "📘",
    title: "Facebook Page",
    subtitle: "ติดตามข่าวสารและอัปเดตใหม่",
    value: "Eazy Store App",
    href: "https://facebook.com/eazystoreapp",
    color: "bg-blue-50 border-blue-100",
    badge: "blue",
  },
  {
    icon: "📞",
    title: "โทรศัพท์",
    subtitle: "จ-ศ 9:00-18:00 น.",
    value: "02-xxx-xxxx",
    href: "tel:02xxxxxxxx",
    color: "bg-emerald-50 border-emerald-100",
    badge: "emerald",
  },
];

export default function ContactPage() {
  return (
    <>
      <Navbar />
      <main className="page-container">
        <div className="text-center mb-10">
          <div className="w-16 h-16 bg-emerald-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <span className="text-3xl">💬</span>
          </div>
          <h1 className="text-3xl font-extrabold text-slate-800">ช่องทางการติดต่อ</h1>
          <p className="text-slate-500 mt-2 text-sm max-w-md mx-auto leading-relaxed">
            ทีมงานของเราพร้อมช่วยเหลือคุณ เลือกช่องทางที่สะดวกสำหรับคุณได้เลย
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {channels.map((ch) => (
            <a
              key={ch.title}
              href={ch.href}
              target="_blank"
              rel="noopener noreferrer"
              className={`section-card border ${ch.color} hover:shadow-md hover:-translate-y-1 transition-all duration-200 group flex items-start gap-4`}
            >
              <div className="w-12 h-12 bg-white rounded-xl flex items-center justify-center text-2xl shadow-sm flex-shrink-0">
                {ch.icon}
              </div>
              <div className="min-w-0">
                <h3 className="font-bold text-slate-800 group-hover:text-[#4F46E5] transition-colors">
                  {ch.title}
                </h3>
                <p className="text-xs text-slate-500 mt-0.5">{ch.subtitle}</p>
                <p className="text-sm font-semibold text-slate-700 mt-2 truncate">{ch.value}</p>
              </div>
            </a>
          ))}
        </div>

        {/* Business hours */}
        <div className="section-card mt-6">
          <h2 className="font-bold text-slate-800 mb-4">⏰ เวลาทำการ</h2>
          <div className="space-y-2 text-sm">
            {[
              { day: "จันทร์ - ศุกร์", time: "09:00 - 18:00 น." },
              { day: "เสาร์", time: "10:00 - 15:00 น." },
              { day: "อาทิตย์ และวันหยุดนักขัตฤกษ์", time: "ปิดทำการ" },
            ].map((r) => (
              <div key={r.day} className="flex justify-between items-center py-2 border-b border-gray-50 last:border-0">
                <span className="text-slate-600">{r.day}</span>
                <span className={`font-semibold ${r.time === "ปิดทำการ" ? "text-red-500" : "text-emerald-600"}`}>
                  {r.time}
                </span>
              </div>
            ))}
          </div>
        </div>
      </main>
      <footer className="border-t border-gray-100 py-8 text-center text-sm text-slate-400 mt-8">
        © {new Date().getFullYear()} Eazy Store. สงวนลิขสิทธิ์.
      </footer>
    </>
  );
}
