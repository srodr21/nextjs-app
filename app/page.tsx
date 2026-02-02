export default function Home() {
  return (
    <main style={{ padding: '2rem', fontFamily: 'system-ui, sans-serif' }}>
      <h1>Hello from Next.js on ECS!!!!!</h1>
      <p>This app is running on AWS ECS Fargate.</p>
      <p>
        Health check: <a href="/api/health">/api/health</a>
      </p>
    </main>
  )
}
