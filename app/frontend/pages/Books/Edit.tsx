import { Head, Link, router, useForm } from '@inertiajs/react'
import { type FormEvent, useMemo } from 'react'
import { toast } from 'sonner'
import { AppLayout } from '@/components/layout/AppLayout'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from '@/components/ui/alert-dialog'
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { baseError } from '@/lib/errors'
import { type Book } from '@/types'

type EditBookProps = {
  book: Book
  genre_options: string[]
}

type BookForm = {
  book: {
    title: string
    author: string
    first_publish_year: string
    genre: string
    open_library_key: string
    cover_id: string
  }
}

export default function EditBook({ book, genre_options }: EditBookProps) {
  const { data, setData, patch, processing, errors } = useForm<BookForm>({
    book: {
      title: book.title,
      author: book.author,
      first_publish_year: book.first_publish_year ? String(book.first_publish_year) : '',
      genre: book.genre,
      open_library_key: book.open_library_key ?? '',
      cover_id: book.cover_id ? String(book.cover_id) : '',
    },
  })

  const knownGenres = useMemo(() => {
    return Array.from(new Set([...genre_options, data.book.genre].filter(Boolean)))
  }, [genre_options, data.book.genre])

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    patch(`/books/${book.id}`, {
      onError: () => toast.error('Revise os campos do livro.'),
    })
  }

  const removeBook = () => {
    router.delete(`/books/${book.id}`, {
      onError: () => toast.error('Nao foi possivel remover o livro.'),
    })
  }

  return (
    <AppLayout>
      <Head title={`Editar ${book.title}`} />
      <div className="grid gap-6 lg:grid-cols-[0.85fr_1.15fr]">
        <section className="space-y-4">
          <div className="space-y-2">
            <h1 className="text-3xl font-semibold tracking-tight">Editar livro</h1>
            <p className="text-muted-foreground">Atualize os dados do seu cadastro no catalogo.</p>
          </div>

          <Card>
            <CardHeader>
              <CardTitle>{book.title}</CardTitle>
              <CardDescription>{book.author}</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="aspect-[3/4] max-w-56 overflow-hidden rounded-lg border bg-muted">
                {book.cover_url ? (
                  <img className="h-full w-full object-cover" src={book.cover_url} alt={`Capa de ${book.title}`} />
                ) : (
                  <div className="flex h-full items-center justify-center px-4 text-center text-sm text-muted-foreground">
                    Sem capa
                  </div>
                )}
              </div>
              <div className="flex flex-wrap gap-2">
                <Badge variant="secondary">{book.genre}</Badge>
                {book.first_publish_year && <Badge variant="outline">{book.first_publish_year}</Badge>}
              </div>
            </CardContent>
          </Card>
        </section>

        <section>
          <Card>
            <CardHeader>
              <CardTitle>Dados do livro</CardTitle>
              <CardDescription>Somente voce pode editar ou remover este cadastro.</CardDescription>
            </CardHeader>
            <form className="flex flex-col gap-(--card-spacing)" onSubmit={submit}>
              <CardContent className="space-y-4">
                {!book.can_edit && (
                  <Alert variant="destructive">
                    <AlertTitle>Acesso restrito</AlertTitle>
                    <AlertDescription>Este livro nao esta disponivel para edicao.</AlertDescription>
                  </Alert>
                )}

                {baseError(errors, 'book') && (
                  <Alert variant="destructive">
                    <AlertTitle>Nao foi possivel salvar</AlertTitle>
                    <AlertDescription>{baseError(errors, 'book')}</AlertDescription>
                  </Alert>
                )}

                <fieldset disabled={!book.can_edit} className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="book_title">Titulo</Label>
                    <Input
                      id="book_title"
                      value={data.book.title}
                      onChange={(event) => setData('book', { ...data.book, title: event.currentTarget.value })}
                      required
                      aria-invalid={Boolean(errors['book.title'])}
                    />
                    {errors['book.title'] && <p className="text-sm text-destructive">{errors['book.title']}</p>}
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="book_author">Autor</Label>
                    <Input
                      id="book_author"
                      value={data.book.author}
                      onChange={(event) => setData('book', { ...data.book, author: event.currentTarget.value })}
                      required
                      aria-invalid={Boolean(errors['book.author'])}
                    />
                    {errors['book.author'] && <p className="text-sm text-destructive">{errors['book.author']}</p>}
                  </div>

                  <div className="grid gap-4 sm:grid-cols-2">
                    <div className="space-y-2">
                      <Label htmlFor="book_year">Ano</Label>
                      <Input
                        id="book_year"
                        value={data.book.first_publish_year}
                        onChange={(event) => setData('book', { ...data.book, first_publish_year: event.currentTarget.value })}
                        inputMode="numeric"
                        aria-invalid={Boolean(errors['book.first_publish_year'])}
                      />
                      {errors['book.first_publish_year'] && (
                        <p className="text-sm text-destructive">{errors['book.first_publish_year']}</p>
                      )}
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="book_genre">Genero</Label>
                      <Input
                        id="book_genre"
                        value={data.book.genre}
                        onChange={(event) => setData('book', { ...data.book, genre: event.currentTarget.value })}
                        list="known_genres"
                        required
                        aria-invalid={Boolean(errors['book.genre'])}
                      />
                      <datalist id="known_genres">
                        {knownGenres.map((genre) => <option key={genre} value={genre} />)}
                      </datalist>
                      {errors['book.genre'] && <p className="text-sm text-destructive">{errors['book.genre']}</p>}
                    </div>
                  </div>

                  <div className="grid gap-4 sm:grid-cols-2">
                    <div className="space-y-2">
                      <Label htmlFor="book_open_library_key">OpenLibrary key</Label>
                      <Input
                        id="book_open_library_key"
                        value={data.book.open_library_key}
                        onChange={(event) => setData('book', { ...data.book, open_library_key: event.currentTarget.value })}
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="book_cover_id">Cover ID</Label>
                      <Input
                        id="book_cover_id"
                        value={data.book.cover_id}
                        onChange={(event) => setData('book', { ...data.book, cover_id: event.currentTarget.value })}
                        inputMode="numeric"
                        aria-invalid={Boolean(errors['book.cover_id'])}
                      />
                      {errors['book.cover_id'] && <p className="text-sm text-destructive">{errors['book.cover_id']}</p>}
                    </div>
                  </div>
                </fieldset>
              </CardContent>
              <CardFooter className="flex flex-col-reverse items-stretch gap-2 sm:flex-row sm:justify-between">
                <div className="flex gap-2">
                  <Button asChild variant="outline">
                    <Link href="/books">Cancelar</Link>
                  </Button>
                  <Button type="submit" disabled={processing || !book.can_edit}>Salvar</Button>
                </div>

                <AlertDialog>
                  <AlertDialogTrigger asChild>
                    <Button type="button" variant="destructive" disabled={!book.can_edit}>Remover</Button>
                  </AlertDialogTrigger>
                  <AlertDialogContent>
                    <AlertDialogHeader>
                      <AlertDialogTitle>Remover livro?</AlertDialogTitle>
                      <AlertDialogDescription>
                        Esta acao remove o livro do seu catalogo e nao pode ser desfeita.
                      </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                      <AlertDialogCancel>Cancelar</AlertDialogCancel>
                      <AlertDialogAction variant="destructive" onClick={removeBook}>Remover</AlertDialogAction>
                    </AlertDialogFooter>
                  </AlertDialogContent>
                </AlertDialog>
              </CardFooter>
            </form>
          </Card>
        </section>
      </div>
    </AppLayout>
  )
}
