import Link from "next/link";

export default function Footer() {
  return (
    <footer className="border-t py-6 md:py-0">
      <div className="container flex flex-col items-center justify-between gap-4 md:h-16 md:flex-row">
        <div className="flex text-sm text-muted-foreground gap-6">
          <p>Released under the GPL v3.0</p>
          <p>© {new Date().getFullYear()} by <Link href="https://github.com/ZG089" target="_blank" rel="noreferrer" className="text-sm text-muted-foreground hover:text-foreground">ZG089</Link></p>
        </div>
        <div className="items-center gap-4 hidden sm:flex">
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
  )
}