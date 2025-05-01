import Link from "next/link"
import { Button } from "@/components/ui/button"
import { SiteHeader } from "@/components/site-header"

export default function NotFound() {
  return (
    <div className="flex flex-col min-h-screen">
      <SiteHeader />
      <div className="container flex flex-col items-center justify-center flex-1 py-12 text-center">
        <h1 className="text-8xl font-bold tracking-tighter mb-4 text-red-600">404</h1>
        <h2 className="text-2xl font-semibold mb-8 text-red-600">PAGE NOT FOUND</h2>
        <div className="max-w-md mb-8">
          <p className="text-muted-foreground">
            But if you don't change your direction, and if you keep looking, you may end up where you are heading.
          </p>
        </div>
        <Button asChild>
          <Link href="/">Take me home</Link>
        </Button>
      </div>
      <footer className="border-t py-6 md:py-0">
        <div className="container flex flex-col items-center justify-between gap-4 md:h-16 md:flex-row">
          <p className="text-sm text-muted-foreground">
            Released under the Apache License 2.0. Copyright © {new Date().getFullYear()}-present ZG089
          </p>
          <div className="flex items-center gap-4">
            <Link
              href="https://github.com/ZG089/Re-Malwack"
              target="_blank"
              rel="noreferrer"
              className="text-sm text-muted-foreground hover:text-foreground"
            >
              GitHub
            </Link>
          </div>
        </div>
      </footer>
    </div>
  )
}

