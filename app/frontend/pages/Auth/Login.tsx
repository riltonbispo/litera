import { Head, Link, useForm } from '@inertiajs/react'
import { type FormEvent } from 'react'
import { AppLayout } from '@/components/layout/AppLayout'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Checkbox } from '@/components/ui/checkbox'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

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
    <AppLayout>
      <Head title="Entrar" />
      <div className="mx-auto max-w-md">
        <Card>
          <CardHeader>
            <CardTitle>Entrar</CardTitle>
            <CardDescription>Acesse sua conta para cadastrar e gerenciar seus livros.</CardDescription>
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
                  autoComplete="current-password"
                  aria-invalid={Boolean(errors['user.password'])}
                />
                {errors['user.password'] && <p className="text-sm text-destructive">{errors['user.password']}</p>}
              </div>

              <div className="flex items-center gap-2">
                <Checkbox
                  id="user_remember_me"
                  checked={data.user.remember_me}
                  onCheckedChange={(checked) => setData('user', { ...data.user, remember_me: checked === true })}
                />
                <Label htmlFor="user_remember_me">Lembrar-me</Label>
              </div>

              <Button className="w-full" type="submit" disabled={processing}>Entrar</Button>
            </form>

            <Button asChild variant="link" className="mt-4 px-0">
              <Link href="/users/sign_up">Criar conta</Link>
            </Button>
          </CardContent>
        </Card>
      </div>
    </AppLayout>
  )
}
