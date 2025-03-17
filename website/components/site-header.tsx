import Link from "next/link"
import { Button } from "@/components/ui/button"
import { Github, Download, Coffee } from "lucide-react"
import { ThemeToggle } from "@/components/theme-toggle"

export function SiteHeader() {
  return (
    <header className="border-b border-border/40 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 sticky top-0 z-50">
      <div className="container flex h-14 max-w-screen-2xl items-center">
        <div className="mr-4 flex">
          <Link href="/" className="mr-6 flex items-center space-x-2">
            <span className="font-bold">Re-Malwack</span>
          </Link>
        </div>
        <div className="flex flex-1 items-center justify-between space-x-2 md:justify-end">
          <nav className="flex items-center space-x-6">
            <Link href="/guide" className="text-sm font-medium transition-colors hover:text-primary">
              Guide
            </Link>
            <Button variant="ghost" className="h-8 w-full justify-start px-2 font-normal" asChild>
              <Link
                href="https://buymeacoffee.com/zg089"
                target="_blank"
                rel="noreferrer"
                className="flex items-center"
              >
                <Coffee className="mr-2 h-4 w-4" />
                Buy Me A Coffee
              </Link>
            </Button>
            <Button variant="outline" className="h-8" asChild>
              <Link href="/download" className="flex items-center">
                <Download className="mr-2 h-4 w-4" />
                Download
              </Link>
            </Button>
          </nav>
          <div className="flex items-center space-x-1">
            <ThemeToggle />
            <Link href="https://github.com/ZG089/Re-Malwack" target="_blank" rel="noreferrer">
              <div className="inline-flex h-9 w-9 items-center justify-center whitespace-nowrap rounded-md text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50">
                <Github className="h-5 w-5" />
                <span className="sr-only">GitHub</span>
              </div>
            </Link>
          </div>
        </div>
      </div>
    </header>
  )
}

