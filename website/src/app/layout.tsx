import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Eazy Store - ข้อมูลแอพพลิเคชัน",
  description: "นโยบาย ช่องทางการติดต่อ และการช่วยเหลือสำหรับแอพ Eazy Store",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="th">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Sarabun:wght@300;400;500;600;700;800&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="bg-slate-50 text-slate-800 antialiased">{children}</body>
    </html>
  );
}
