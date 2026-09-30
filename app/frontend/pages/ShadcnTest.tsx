import { Head } from '@inertiajs/react'
import { Button } from '@/components/ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'

export default function ShadcnTest() {
  return (
    <main className="flex min-h-svh items-center justify-center bg-background p-6 text-foreground">
      <Head title="shadcn/ui test" />
      <Card className="w-full max-w-sm">
        <CardHeader>
          <CardTitle>shadcn/ui</CardTitle>
          <CardDescription>Button and Card render through Inertia.</CardDescription>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground">
            Tailwind, theme variables, and the @ alias are active.
          </p>
        </CardContent>
        <CardFooter>
          <Button type="button">Ready</Button>
        </CardFooter>
      </Card>
    </main>
  )
}
