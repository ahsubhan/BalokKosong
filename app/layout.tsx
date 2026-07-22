import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "BalokKosong",
  description: "Game puzzle mobile untuk membebaskan semua balok.",
  themeColor: "#f4efdf"
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="id">
      <body>{children}</body>
    </html>
  );
}
