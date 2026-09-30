import { Head, Link, useForm } from '@inertiajs/react'
import { type FormEvent } from 'react'

type LoginProps = {
  email: string
}

type LoginForm = {
  user: {
    email: string
    password: string
    remember_me: boolean
  }
}

export default function Login({ email }: LoginProps) {
  const { data, setData, post, processing, errors } = useForm<LoginForm>({
    user: {
      email,
      password: '',
      remember_me: false,
    },
  })

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    post('/users/sign_in')
  }

  return (
    <main>
      <Head title="Entrar" />
      <h1>Entrar</h1>
      <form onSubmit={submit}>
        <label htmlFor="user_email">Email</label>
        <input
          id="user_email"
          name="user[email]"
          type="email"
          value={data.user.email}
          onChange={(event) => setData('user', { ...data.user, email: event.currentTarget.value })}
          required
          autoComplete="email"
        />
        {errors['user.email'] && <p>{errors['user.email']}</p>}

        <label htmlFor="user_password">Senha</label>
        <input
          id="user_password"
          name="user[password]"
          type="password"
          value={data.user.password}
          onChange={(event) => setData('user', { ...data.user, password: event.currentTarget.value })}
          required
          autoComplete="current-password"
        />
        {errors['user.password'] && <p>{errors['user.password']}</p>}

        <label htmlFor="user_remember_me">
          <input
            id="user_remember_me"
            name="user[remember_me]"
            type="checkbox"
            checked={data.user.remember_me}
            onChange={(event) => setData('user', { ...data.user, remember_me: event.currentTarget.checked })}
          />
          Lembrar-me
        </label>

        <button type="submit" disabled={processing}>Entrar</button>
      </form>
      <Link href="/users/sign_up">Criar conta</Link>
    </main>
  )
}
