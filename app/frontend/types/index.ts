export type CurrentUser = {
  id: number
  email: string
  initials: string
}

export type PageProps = {
  auth: {
    user: CurrentUser | null
  }
  flash: {
    notice: string | null
    alert: string | null
  }
}

export type Book = {
  id: number
  title: string
  author: string
  genre: string
  first_publish_year: number | null
  open_library_key: string | null
  cover_id: number | null
  cover_url: string | null
  owner_id: number
  can_edit: boolean
  created_at: string
}

export type Pagination = {
  current_page: number
  per_page: number
  total_pages: number
  total_count: number
  next_page: number | null
  prev_page: number | null
}

export type BookFilters = {
  author: string | null
  genre: string | null
  first_publish_year: string | null
}

export type OpenLibraryResult = {
  key: string | null
  title: string | null
  author: string | null
  year: number | null
  subjects: string[]
  cover_url: string | null
}

export type OpenLibraryStatus = {
  code: string
  message: string | null
}
