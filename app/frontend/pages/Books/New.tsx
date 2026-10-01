import { Head, Link, useForm } from '@inertiajs/react'
import { type FormEvent, useEffect, useMemo, useState } from 'react'
import { toast } from 'sonner'
import { AppLayout } from '@/components/layout/AppLayout'
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Skeleton } from '@/components/ui/skeleton'
import { type OpenLibraryResult, type OpenLibraryStatus } from '@/types'

type NewBookProps = {
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

type SearchPayload = {
  results: OpenLibraryResult[]
  status: OpenLibraryStatus
}

export default function NewBook({ genre_options }: NewBookProps) {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState<OpenLibraryResult[]>([])
  const [selected, setSelected] = useState<OpenLibraryResult | null>(null)
  const [status, setStatus] = useState<OpenLibraryStatus | null>(null)
  const [searching, setSearching] = useState(false)

  const { data, setData, post, processing, errors } = useForm<BookForm>({
    book: {
      title: '',
      author: '',
      first_publish_year: '',
      genre: '',
      open_library_key: '',
      cover_id: '',
    },
  })

  useEffect(() => {
    if (query.trim().length < 2) {
      setResults([])
      setStatus(null)
      setSearching(false)
      return
    }

    const controller = new AbortController()
    const timeout = window.setTimeout(() => {
      setSearching(true)
      void fetch(`/book_search.json?title=${encodeURIComponent(query.trim())}&limit=5`, {
        signal: controller.signal,
        headers: { Accept: 'application/json' },
      })
        .then((response) => response.json() as Promise<SearchPayload>)
        .then((payload) => {
          setResults(payload.results)
          setStatus(payload.status.code === 'ok' ? null : payload.status)
        })
        .catch((error: unknown) => {
          if (error instanceof DOMException && error.name === 'AbortError') return
          setResults([])
          setStatus({ code: 'client_error', message: 'Nao foi possivel buscar agora. Voce pode cadastrar manualmente.' })
        })
        .finally(() => setSearching(false))
    }, 400)

    return () => {
      window.clearTimeout(timeout)
      controller.abort()
    }
  }, [query])

  const previewCoverUrl = selected?.cover_url ?? null

  const knownGenres = useMemo(() => {
    return Array.from(new Set([...genre_options, data.book.genre].filter(Boolean)))
  }, [genre_options, data.book.genre])

  const selectResult = (result: OpenLibraryResult) => {
    setSelected(result)
    setData('book', {
      title: result.title ?? '',
      author: result.author ?? '',
      first_publish_year: result.year ? String(result.year) : '',
      genre: result.subjects[0] ?? '',
      open_library_key: result.key ?? '',
      cover_id: result.cover_id ? String(result.cover_id) : '',
    })
  }

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    post('/books', {
      onError: () => toast.error('Revise os campos do livro.'),
    })
  }

  return (
    <AppLayout>
      <Head title="Cadastrar livro" />
      <div className="grid gap-6 lg:grid-cols-[1.1fr_0.9fr]">
        <section className="space-y-6">
          <div className="space-y-2">
            <h1 className="text-3xl font-semibold tracking-tight">Cadastrar livro</h1>
            <p className="text-muted-foreground">Busque na OpenLibrary, selecione uma sugestao ou preencha manualmente.</p>
          </div>

          <Card>
            <CardHeader>
              <CardTitle>Busca</CardTitle>
              <CardDescription>Digite pelo menos duas letras do titulo.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="book_search_title">Titulo</Label>
                <Input
                  id="book_search_title"
                  value={query}
                  onChange={(event) => setQuery(event.currentTarget.value)}
                  placeholder="Ex.: Dom Casmurro"
                  autoComplete="off"
                />
              </div>

              {status && (
                <Alert>
                  <AlertTitle>{status.code === 'empty_results' ? 'Nenhum resultado' : 'Busca indisponivel'}</AlertTitle>
                  <AlertDescription>{status.message}</AlertDescription>
                </Alert>
              )}

              {searching ? <SearchSkeleton /> : <SearchResults results={results} selected={selected} onSelect={selectResult} />}
            </CardContent>
          </Card>
        </section>

        <section>
          <Card>
            <CardHeader>
              <CardTitle>Confirmar cadastro</CardTitle>
              <CardDescription>Revise os dados antes de salvar no catalogo.</CardDescription>
            </CardHeader>
            <form className="flex flex-col gap-(--card-spacing)" onSubmit={submit}>
              <CardContent className="space-y-4">
                {previewCoverUrl && (
                  <img className="mb-4 aspect-[3/4] w-32 rounded-lg border object-cover" src={previewCoverUrl} alt="Previa da capa" />
                )}

                {errors['book.base'] && (
                  <Alert variant="destructive">
                    <AlertTitle>Nao foi possivel cadastrar</AlertTitle>
                    <AlertDescription>{errors['book.base']}</AlertDescription>
                  </Alert>
                )}

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
              </CardContent>
              <CardFooter className="flex justify-between gap-2">
                <Button asChild variant="outline">
                  <Link href="/books">Cancelar</Link>
                </Button>
                <Button type="submit" disabled={processing}>Confirmar</Button>
              </CardFooter>
            </form>
          </Card>
        </section>
      </div>
    </AppLayout>
  )
}

function SearchResults({
  results,
  selected,
  onSelect,
}: {
  results: OpenLibraryResult[]
  selected: OpenLibraryResult | null
  onSelect: (result: OpenLibraryResult) => void
}) {
  if (results.length === 0) return null

  return (
    <div className="grid gap-3" aria-label="Resultados da OpenLibrary">
      {results.map((result) => {
        const active = selected?.key === result.key && selected?.title === result.title
        return (
          <button key={`${result.key}-${result.title}`} type="button" className="text-left" onClick={() => onSelect(result)}>
            <Card className={active ? 'border-primary ring-2 ring-primary' : 'transition-colors hover:border-primary/60'}>
              <CardContent className="flex gap-4 p-4">
                {result.cover_url ? (
                  <img className="h-24 w-16 rounded-md border object-cover" src={result.cover_url} alt={`Capa de ${result.title ?? 'livro'}`} />
                ) : (
                  <div className="flex h-24 w-16 shrink-0 items-center justify-center rounded-md bg-muted text-xs text-muted-foreground">
                    Sem capa
                  </div>
                )}
                <div className="min-w-0 space-y-2">
                  <div>
                    <h2 className="line-clamp-2 font-medium">{result.title ?? 'Titulo desconhecido'}</h2>
                    <p className="text-sm text-muted-foreground">{result.author ?? 'Autor desconhecido'}</p>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    {result.year && <Badge variant="secondary">{result.year}</Badge>}
                    {result.subjects.slice(0, 2).map((subject) => <Badge key={subject} variant="outline">{subject}</Badge>)}
                  </div>
                </div>
              </CardContent>
            </Card>
          </button>
        )
      })}
    </div>
  )
}

function SearchSkeleton() {
  return (
    <div className="grid gap-3" aria-label="Buscando livros">
      {Array.from({ length: 3 }, (_, index) => (
        <Card key={index}>
          <CardContent className="flex gap-4 p-4">
            <Skeleton className="h-24 w-16 rounded-md" />
            <div className="flex-1 space-y-3">
              <Skeleton className="h-5 w-3/4" />
              <Skeleton className="h-4 w-1/2" />
              <Skeleton className="h-5 w-24" />
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  )
}
