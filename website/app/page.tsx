import Link from "next/link"
import { Button } from "@/components/ui/button"
import { SiteHeader } from "@/components/site-header"

export default function Home() {
  return (
    <div className="flex flex-col min-h-screen">
      <SiteHeader />
      <main className="flex-1">
        <section className="container flex flex-col items-center justify-center gap-4 py-24 md:py-32">
          <h1 className="text-center text-3xl font-bold leading-tight tracking-tighter md:text-6xl lg:text-7xl text-red-600">
            Re-Malwack
          </h1>
          <p className="max-w-[700px] text-center text-lg text-muted-foreground">
            A powerful module that blocks ads, protects your device from malware and trackers, and blocks inappropriate
            sites
          </p>
          <div className="flex flex-col gap-4 sm:flex-row">
            <Button className="bg-red-600 hover:bg-red-700 text-white" size="lg" asChild>
              <Link href="/download">Download Now</Link>
            </Button>
            <Button variant="outline" size="lg" asChild>
              <Link href="/guide">Guides</Link>
            </Button>
          </div>
        </section>
        <section className="container py-12 md:py-24 lg:py-32">
          <div className="mx-auto grid max-w-5xl items-center gap-6 py-12 lg:grid-cols-2 lg:gap-12">
            <div className="flex flex-col justify-center space-y-4">
              <div className="inline-block rounded-lg bg-muted px-3 py-1 text-sm">Features</div>
              <h2 className="text-3xl font-bold tracking-tighter md:text-4xl text-red-600">Protect your device</h2>
              <p className="max-w-[600px] text-muted-foreground md:text-xl/relaxed lg:text-base/relaxed xl:text-xl/relaxed">
                Re-Malwack provides powerful tools to protect your device from ads, malware, and inappropriate content.
              </p>
            </div>
            <div className="rounded-xl border bg-card p-6 shadow-sm">
              <ul className="grid gap-6">
                <li className="flex items-center gap-4">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10">
                    <div className="h-5 w-5 text-primary">✓</div>
                  </div>
                  <div>
                    <h3 className="font-medium">Ad Blocking</h3>
                    <p className="text-sm text-muted-foreground">Block annoying ads across apps and websites</p>
                  </div>
                </li>
                <li className="flex items-center gap-4">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10">
                    <div className="h-5 w-5 text-primary">✓</div>
                  </div>
                  <div>
                    <h3 className="font-medium">Malware & Tracker Protection</h3>
                    <p className="text-sm text-muted-foreground">
                      Shield your device from malicious software and trackers
                    </p>
                  </div>
                </li>
                <li className="flex items-center gap-4">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10">
                    <div className="h-5 w-5 text-primary">✓</div>
                  </div>
                  <div>
                    <h3 className="font-medium">Content Filtering</h3>
                    <p className="text-sm text-muted-foreground">
                      Block adult content, gambling, fake news, and other inappropriate sites
                    </p>
                  </div>
                </li>
              </ul>
            </div>
          </div>
        </section>
      </main>
      <footer className="border-t py-6 md:py-0">
        <div className="container flex flex-col items-center justify-between gap-4 md:h-16 md:flex-row">
          <p className="text-sm text-muted-foreground">
            Released under the GPL V3 Copyright © {new Date().getFullYear()}-present  @ZG089
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

