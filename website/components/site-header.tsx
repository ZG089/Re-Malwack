import Link from "next/link"
import { Button } from "@/components/ui/button"
import { Coffee, Book, Download } from "lucide-react"
import { RiGithubLine } from "react-icons/ri"
import { ThemeToggle } from "@/components/theme-toggle"

export function SiteHeader() {
  return (
    <header className="border-b border-border/40 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 sticky top-0 z-50">
      <div className="container flex h-14 max-w-screen-2xl items-center justify-between px-4">
        <div className="flex">
          <Link href="/" className="flex items-center space-x-2">
            <span className="font-bold text-sm sm:text-base">Re-Malwack</span>
          </Link>
        </div>
        <nav className="flex items-center space-x-2">
          <Button variant="ghost" className="h-8 px-3" asChild>
            <Link href="/guide" className="text-sm font-medium transition-colors hover:text-primary">
              <Book className="h-4 w-4" />
              <span className="hidden sm:inline-block">Guide</span>
            </Link>
          </Button>
          <Button variant="ghost" className="h-8 px-3" asChild>
            <Link
              href="https://buymeacoffee.com/zg089"
              target="_blank"
              rel="noreferrer"
              className="flex items-center"
            >
              <Coffee className="h-4 w-4" />
              <span className="hidden sm:inline-block">Buy Me A Coffee</span>
            </Link>
          </Button>
          <ThemeToggle />
          <Button variant="ghost" className="h-8 w-8 p-0" asChild>
            <Link href="https://github.com/ZG089/Re-Malwack" target="_blank" rel="noreferrer">
              <RiGithubLine className="h-4 w-4" />
              <span className="sr-only">GitHub</span>
            </Link>
          </Button>
          <Button className="h-8 px-2 sm:px-3" asChild>
            <Link href="/guide" className="text-sm font-medium">
              <Download />
              <span className="hidden sm:inline-block">Download</span>
            </Link>
          </Button>
        </nav>
      </div>
    </header>
  )
}

