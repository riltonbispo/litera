import { Head, Link } from '@inertiajs/react'
import { useCallback, useState } from 'react'
import { AppLayout } from '@/components/layout/AppLayout'
import { BookCard } from '@/components/books/BookCard'
import { BookFilters } from '@/components/books/BookFilters'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Pagination as PaginationRoot,
  PaginationContent,
  PaginationItem,
  PaginationLink,
  PaginationNext,
  PaginationPrevious,
} from '@/components/ui/pagination'
import { Skeleton } from '@/components/ui/skeleton'
import { type Book, type BookFilters as BookFiltersType, type Pagination } from '@/types'

type FilterOptions = {
  genres: string[]
  years: number[]
}

type BooksIndexProps = {
  books: Book[]
  filters: BookFiltersType
  filter_options: FilterOptions
  meta: Pagination
}

export default function BooksIndex({ books, filters, filter_options, meta }: BooksIndexProps) {
  const [loading, setLoading] = useState(false)
  const handleLoadingChange = useCallback((value: boolean) => setLoading(value), [])

  return (
    <AppLayout>
      <Head title="Livros" />
      <div className="space-y-8">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div className="space-y-2">
            <h1 className="text-3xl font-semibold tracking-tight">Catalogo coletivo</h1>
            <p className="max-w-2xl text-muted-foreground">
              Leituras compartilhadas pela comunidade, sempre com os cadastros mais recentes primeiro.
            </p>
          </div>
          <Button asChild>
            <Link href="/books/new">Cadastrar livro</Link>
          </Button>
        </div>

        <BookFilters filters={filters} options={filter_options} onLoadingChange={handleLoadingChange} />

        {loading ? (
          <BookGridSkeleton />
        ) : books.length > 0 ? (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {books.map((book) => <BookCard key={book.id} book={book} />)}
          </div>
        ) : (
          <Card>
            <CardHeader>
              <CardTitle>Nenhum livro encontrado</CardTitle>
              <CardDescription>Ajuste os filtros ou cadastre o primeiro livro para esta busca.</CardDescription>
            </CardHeader>
            <CardContent>
              <Button asChild>
                <Link href="/books/new">Cadastrar livro</Link>
              </Button>
            </CardContent>
          </Card>
        )}

        {meta.total_pages > 1 && <BooksPagination meta={meta} filters={filters} />}
      </div>
    </AppLayout>
  )
}

function BookGridSkeleton() {
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4" aria-label="Carregando livros">
      {Array.from({ length: 8 }, (_, index) => (
        <Card key={index} className="overflow-hidden">
          <Skeleton className="aspect-[3/4] w-full" />
          <CardContent className="space-y-3 p-4">
            <Skeleton className="h-5 w-4/5" />
            <Skeleton className="h-4 w-3/5" />
            <Skeleton className="h-5 w-24" />
          </CardContent>
        </Card>
      ))}
    </div>
  )
}

function BooksPagination({ meta, filters }: { meta: Pagination; filters: BookFiltersType }) {
  const pages = Array.from({ length: meta.total_pages }, (_, index) => index + 1)

  return (
    <PaginationRoot>
      <PaginationContent>
        {meta.prev_page && (
          <PaginationItem>
            <PaginationPrevious href={pageHref(meta.prev_page, filters)} text="Anterior" />
          </PaginationItem>
        )}
        {pages.map((page) => (
          <PaginationItem key={page}>
            <PaginationLink href={pageHref(page, filters)} isActive={page === meta.current_page}>
              {page}
            </PaginationLink>
          </PaginationItem>
        ))}
        {meta.next_page && (
          <PaginationItem>
            <PaginationNext href={pageHref(meta.next_page, filters)} text="Proxima" />
          </PaginationItem>
        )}
      </PaginationContent>
    </PaginationRoot>
  )
}

function pageHref(page: number, filters: BookFiltersType) {
  const params = new URLSearchParams()
  params.set('page', String(page))
  if (filters.author) params.set('author', filters.author)
  if (filters.genre) params.set('genre', filters.genre)
  if (filters.first_publish_year) params.set('first_publish_year', filters.first_publish_year)
  return `/books?${params.toString()}`
}
