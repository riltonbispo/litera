import { Head, Link } from '@inertiajs/react'

export default function Home() {
  return (
    <main>
      <Head title="Litera" />
      <h1>Litera</h1>
      <nav>
        <Link href="/users/sign_in">Entrar</Link>
        <Link href="/users/sign_up">Cadastrar</Link>
      </nav>
    </main>
  )
}
