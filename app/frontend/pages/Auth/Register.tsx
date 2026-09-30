import { Head, Link, useForm } from '@inertiajs/react'
import { type FormEvent } from 'react'

type RegisterProps = {
  email: string
  minimum_password_length?: number
}

type RegisterForm = {
  user: {
    email: string
    password: string
    password_confirmation: string
  }
}

export default function Register({ email, minimum_password_length }: RegisterProps) {
  const { data, setData, post, processing, errors } = useForm<RegisterForm>({
    user: {
      email,
      password: '',
      password_confirmation: '',
    },
  })

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    post('/users')
  }

  return (
    <main>
      <Head title="Cadastrar" />
      <h1>Cadastrar</h1>
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
          minLength={minimum_password_length}
          autoComplete="new-password"
        />
        {errors['user.password'] && <p>{errors['user.password']}</p>}

        <label htmlFor="user_password_confirmation">Confirmar senha</label>
        <input
          id="user_password_confirmation"
          name="user[password_confirmation]"
          type="password"
          value={data.user.password_confirmation}
          onChange={(event) => setData('user', { ...data.user, password_confirmation: event.currentTarget.value })}
          required
          minLength={minimum_password_length}
          autoComplete="new-password"
        />
        {errors['user.password_confirmation'] && <p>{errors['user.password_confirmation']}</p>}

        <button type="submit" disabled={processing}>Cadastrar</button>
      </form>
      <Link href="/users/sign_in">Já tenho conta</Link>
    </main>
  )
}
