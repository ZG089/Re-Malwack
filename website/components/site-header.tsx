import Link from "next/link"
import { Button } from "@/components/ui/button"
import { Download, Coffee, Book } from "lucide-react"
import { RiGithubLine } from "react-icons/ri"
import { ThemeToggle } from "@/components/theme-toggle"

export function SiteHeader() {
  return (
    <header className="border-b border-border/40 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 sticky top-0 z-50">
      <div className="container flex h-14 max-w-screen-2xl items-center justify-between">
        <div className="mr-4 flex">
          <Link href="/" className="mr-6 flex items-center space-x-2">
            <span className="font-bold">Re-Malwack</span>
          </Link>
        </div>
        <div className="flex flex-row items-center justify-end space-x-2 md:justify-end">
          <nav className="flex items-center space-x-2">
            <Button variant="ghost" className="h-8 w-full justify-start px-2 font-normal" asChild>
              <Link href="/guide" className="text-sm font-medium transition-colors hover:text-primary">
                <Book />
                Guide
              </Link>
            </Button>
            <Button variant="ghost" className="h-8 w-full justify-start px-2 font-normal" asChild>
              <Link
                href="https://buymeacoffee.com/zg089"
                target="_blank"
                rel="noreferrer"
                className="flex items-center"
              >
                <Coffee /> {/* sizing should be delegated to shadcn */}
                Buy Me A Coffee
              </Link>
            </Button>
            <Button variant="outline" className="h-8" asChild>
              <Link href="/download" className="flex items-center">
                <Download />
                Download
              </Link>
            </Button>
          </nav>
          <div className="flex items-center space-x-1">
            <ThemeToggle />
            <Link href="https://github.com/ZG089/Re-Malwack" target="_blank" rel="noreferrer">
              <Button variant="ghost" className="w-8 h-8">
                <RiGithubLine size={16} />
                <span className="sr-only">GitHub</span>
              </Button>
            </Link>
          </div>
        </div>
      </div>
    </header>
  )
}

