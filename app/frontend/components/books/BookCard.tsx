import { Link } from '@inertiajs/react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardFooter } from '@/components/ui/card'
import { type Book } from '@/types'

type BookCardProps = {
  book: Book
}

export function BookCard({ book }: BookCardProps) {
  return (
    <Card className="overflow-hidden">
      <div className="aspect-[3/4] bg-muted">
        {book.cover_url ? (
          <img className="h-full w-full object-cover" src={book.cover_url} alt={`Capa de ${book.title}`} loading="lazy" />
        ) : (
          <div className="flex h-full items-center justify-center px-4 text-center text-sm text-muted-foreground">
            Sem capa
          </div>
        )}
      </div>
      <CardContent className="space-y-3 p-4">
        <div className="space-y-1">
          <h2 className="line-clamp-2 text-base font-semibold leading-snug">{book.title}</h2>
          <p className="line-clamp-1 text-sm text-muted-foreground">{book.author}</p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <Badge variant="secondary">{book.genre}</Badge>
          {book.first_publish_year && <span className="text-sm text-muted-foreground">{book.first_publish_year}</span>}
        </div>
      </CardContent>
      {book.can_edit && (
        <CardFooter className="gap-2 p-4 pt-0">
          <Button asChild variant="outline" size="sm">
            <Link href={`/books/${book.id}/edit`}>Editar</Link>
          </Button>
        </CardFooter>
      )}
    </Card>
  )
}
