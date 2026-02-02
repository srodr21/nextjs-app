export const metadata = {
  title: 'Next.js on ECS',
  description: 'Simple Next.js app deployed on AWS ECS',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
