import { Link, router, usePage } from '@inertiajs/react'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { Toaster } from '@/components/ui/sonner'
import { type PageProps } from '@/types'

type AppLayoutProps = {
  children: React.ReactNode
}

export function AppLayout({ children }: AppLayoutProps) {
  const { auth } = usePage<PageProps>().props

  const signOut = () => {
    router.delete('/users/sign_out')
  }

  return (
    <div className="min-h-svh bg-background text-foreground">
      <header className="border-b bg-background/95">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4 sm:px-6 lg:px-8">
          <Button asChild variant="ghost" className="px-0 text-lg font-semibold">
            <Link href="/books">Litera</Link>
          </Button>

          <nav className="flex items-center gap-2" aria-label="Conta">
            {auth.user ? (
              <>
                <Button asChild>
                  <Link href="/books/new">Cadastrar livro</Link>
                </Button>
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" className="gap-2 px-2" aria-label="Abrir menu da conta">
                      <Avatar className="size-8">
                        <AvatarFallback>{auth.user.initials}</AvatarFallback>
                      </Avatar>
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end" className="w-56">
                    <DropdownMenuLabel className="truncate">{auth.user.email}</DropdownMenuLabel>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem onSelect={signOut}>Sair</DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </>
            ) : (
              <>
                <Button asChild variant="ghost">
                  <Link href="/users/sign_in">Login</Link>
                </Button>
                <Button asChild>
                  <Link href="/users/sign_up">Criar conta</Link>
                </Button>
              </>
            )}
          </nav>
        </div>
      </header>

      <main className="mx-auto max-w-6xl px-4 py-8 sm:px-6 lg:px-8">{children}</main>
      <Toaster richColors />
    </div>
  )
}
