export const metadata = {
  title: 'NEXORA TMS NEXT',
  description: 'NEXORA TMS NEXT implementation baseline',
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="pt-BR">
      <body>{children}</body>
    </html>
  );
}
