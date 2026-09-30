import { router } from '@inertiajs/react'
import { useEffect, useMemo, useRef, useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { type BookFilters as BookFiltersType } from '@/types'

type FilterOptions = {
  genres: string[]
  years: number[]
}

type BookFiltersProps = {
  filters: BookFiltersType
  options: FilterOptions
  onLoadingChange: (loading: boolean) => void
}

const ALL = 'all'

export function BookFilters({ filters, options, onLoadingChange }: BookFiltersProps) {
  const firstRender = useRef(true)
  const [author, setAuthor] = useState(filters.author ?? '')
  const [genre, setGenre] = useState(filters.genre ?? ALL)
  const [year, setYear] = useState(filters.first_publish_year ?? ALL)

  const params = useMemo(() => {
    return {
      author: author.trim() || undefined,
      genre: genre === ALL ? undefined : genre,
      first_publish_year: year === ALL ? undefined : year,
    }
  }, [author, genre, year])

  useEffect(() => {
    setAuthor(filters.author ?? '')
    setGenre(filters.genre ?? ALL)
    setYear(filters.first_publish_year ?? ALL)
  }, [filters.author, filters.genre, filters.first_publish_year])

  useEffect(() => {
    if (firstRender.current) {
      firstRender.current = false
      return
    }

    const timeout = window.setTimeout(() => {
      onLoadingChange(true)
      router.get('/books', params, {
        preserveState: true,
        preserveScroll: true,
        replace: true,
        onFinish: () => onLoadingChange(false),
      })
    }, 400)

    return () => window.clearTimeout(timeout)
  }, [params, onLoadingChange])

  const clearFilters = () => {
    setAuthor('')
    setGenre(ALL)
    setYear(ALL)
  }

  return (
    <section className="grid gap-4 rounded-lg border bg-card p-4 md:grid-cols-[1fr_220px_180px_auto]" aria-label="Filtros de livros">
      <div className="space-y-2">
        <Label htmlFor="filter_author">Autor</Label>
        <Input
          id="filter_author"
          value={author}
          onChange={(event) => setAuthor(event.currentTarget.value)}
          placeholder="Buscar por autor"
        />
      </div>

      <div className="space-y-2">
        <Label htmlFor="filter_genre">Genero</Label>
        <Select value={genre} onValueChange={setGenre}>
          <SelectTrigger id="filter_genre" className="w-full">
            <SelectValue placeholder="Todos" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value={ALL}>Todos</SelectItem>
            {options.genres.map((option) => (
              <SelectItem key={option} value={option}>{option}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="space-y-2">
        <Label htmlFor="filter_year">Ano</Label>
        <Select value={year} onValueChange={setYear}>
          <SelectTrigger id="filter_year" className="w-full">
            <SelectValue placeholder="Todos" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value={ALL}>Todos</SelectItem>
            {options.years.map((option) => (
              <SelectItem key={option} value={String(option)}>{option}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="flex items-end">
        <Button className="w-full" type="button" variant="outline" onClick={clearFilters}>Limpar</Button>
      </div>
    </section>
  )
}
