import type { FormDataErrors } from '@inertiajs/core'

type ErrorBag = Record<string, string | undefined>

/**
 * Record-level errors are sent by the server under a "<scope>.base" key, for example
 * "book.base" when the uniqueness validation rejects a duplicate. Inertia's FormDataErrors is a
 * mapped type built from the form's own fields, so it does not describe that key and reading it
 * needs a widened view of the bag.
 */
export function baseError<T>(errors: FormDataErrors<T>, scope: string): string | undefined {
  return (errors as ErrorBag)[`${scope}.base`]
}
