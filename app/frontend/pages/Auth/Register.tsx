import { Head, Link, useForm } from '@inertiajs/react'
import { type FormEvent } from 'react'
import { AppLayout } from '@/components/layout/AppLayout'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

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
    <AppLayout>
      <Head title="Cadastrar" />
      <div className="mx-auto max-w-md">
        <Card>
          <CardHeader>
            <CardTitle>Criar conta</CardTitle>
            <CardDescription>Entre para contribuir com o catalogo coletivo.</CardDescription>
          </CardHeader>
          <CardContent>
            <form className="space-y-5" onSubmit={submit}>
              <div className="space-y-2">
                <Label htmlFor="user_email">Email</Label>
                <Input
                  id="user_email"
                  name="user[email]"
                  type="email"
                  value={data.user.email}
                  onChange={(event) => setData('user', { ...data.user, email: event.currentTarget.value })}
                  required
                  autoComplete="email"
                  aria-invalid={Boolean(errors['user.email'])}
                />
                {errors['user.email'] && <p className="text-sm text-destructive">{errors['user.email']}</p>}
              </div>

              <div className="space-y-2">
                <Label htmlFor="user_password">Senha</Label>
                <Input
                  id="user_password"
                  name="user[password]"
                  type="password"
                  value={data.user.password}
                  onChange={(event) => setData('user', { ...data.user, password: event.currentTarget.value })}
                  required
                  minLength={minimum_password_length}
                  autoComplete="new-password"
                  aria-invalid={Boolean(errors['user.password'])}
                />
                {errors['user.password'] && <p className="text-sm text-destructive">{errors['user.password']}</p>}
              </div>

              <div className="space-y-2">
                <Label htmlFor="user_password_confirmation">Confirmar senha</Label>
                <Input
                  id="user_password_confirmation"
                  name="user[password_confirmation]"
                  type="password"
                  value={data.user.password_confirmation}
                  onChange={(event) => setData('user', { ...data.user, password_confirmation: event.currentTarget.value })}
                  required
                  minLength={minimum_password_length}
                  autoComplete="new-password"
                  aria-invalid={Boolean(errors['user.password_confirmation'])}
                />
                {errors['user.password_confirmation'] && (
                  <p className="text-sm text-destructive">{errors['user.password_confirmation']}</p>
                )}
              </div>

              <Button className="w-full" type="submit" disabled={processing}>Cadastrar</Button>
            </form>

            <Button asChild variant="link" className="mt-4 px-0">
              <Link href="/users/sign_in">Ja tenho conta</Link>
            </Button>
          </CardContent>
        </Card>
      </div>
    </AppLayout>
  )
}
