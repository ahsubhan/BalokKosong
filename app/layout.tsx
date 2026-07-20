import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Dorong — Puzzle Balok",
  description: "Game puzzle mobile: dorong setiap balok hanya searah panjangnya dan bebaskan balok jingga.",
  themeColor: "#f4efdf"
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="id">
      <body>{children}</body>
    </html>
  );
}
