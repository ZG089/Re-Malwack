import Link from "next/link"
import { Button } from "@/components/ui/button"
import { SiteHeader } from "@/components/site-header"
import { EyeOff, Download, BugOff, ShieldMinus, Shield } from "lucide-react"
import { ReactNode } from "react"

export default function Home() {
  return (
    <div className="flex flex-col min-h-screen">
      <SiteHeader />
      <main className="flex-1">
        <section className="container flex flex-col items-center justify-center gap-4 py-24 md:py-32">
          <h1 className="text-center text-3xl font-bold leading-tight tracking-tighter md:text-6xl lg:text-7xl text-red-600">
            Re-Malwack
          </h1>
          <div className="flex flex-wrap justify-center gap-3 max-w-[700px]">
            <FeatureBubble icon={<ShieldMinus className="h-4 w-4" />} text="Ad Blocker" />
            <FeatureBubble icon={<Shield className="h-4 w-4" />} text="Tracker Blocker" />
            <FeatureBubble icon={<BugOff className="h-4 w-4" />} text="Malware Protection" />
            <FeatureBubble icon={<EyeOff className="h-4 w-4" />} text="Content Filter" />
          </div>
          <p className="max-w-[700px] text-center text-lg text-muted-foreground">
            A powerful protection suite for rooted Android devices
          </p>
          <div className="flex flex-col gap-4 sm:flex-row">
            <Button className="bg-red-600 hover:bg-red-700 text-white" size="lg" asChild>
              <Link href="/download">
                <Download />
                Download Now
              </Link>
            </Button>
            <Button variant="outline" size="lg" asChild>
              <Link href="/guide">Usage Guide</Link>
            </Button>
          </div>
        </section>
        <section className="container py-12 md:py-24 lg:py-32">
          <div className="mx-auto grid max-w-5xl items-center gap-6 py-12 lg:grid-cols-2 lg:gap-12">
            <div className="flex flex-col justify-center space-y-4">
              <h2 className="text-3xl font-bold tracking-tighter md:text-4xl text-red-600">Protect your device</h2>
              <p className="max-w-[600px] text-muted-foreground md:text-xl/relaxed lg:text-base/relaxed xl:text-xl/relaxed">
                Re-Malwack provides powerful tools to protect your device from ads, malware, and inappropriate content.
              </p>
            </div>
            <div className="rounded-xl border bg-card p-6 shadow-sm">
              <ul className="grid gap-6">
                <li className="flex items-center gap-4">
                  <IcoCircle>
                    <ShieldMinus className="h-5 w-5 text-primary" />
                  </IcoCircle>
                  <div>
                    <h3 className="font-medium">Ad & Tracker Blocking</h3>
                    <p className="text-sm text-muted-foreground">Block annoying ads and trackers across apps and websites</p>
                  </div>
                </li>
                <li className="flex items-center gap-4">
                  <IcoCircle>
                    <BugOff className="h-5 w-5 text-primary" />
                  </IcoCircle>
                  <div>
                    <h3 className="font-medium">Malware Protection</h3>
                    <p className="text-sm text-muted-foreground">
                      Shield your device from malicious software
                    </p>
                  </div>
                </li>
                <li className="flex items-center gap-4">
                  <IcoCircle>
                    <EyeOff className="h-5 w-5 text-primary" />
                  </IcoCircle>
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
          <p className="flex text-sm text-muted-foreground gap-4">
            <span>Released under the GPL v3.0</span>
            <span>© {new Date().getFullYear()} by <Link href="https://github.com/ZG089" target="_blank" rel="noreferrer" className="text-sm text-muted-foreground hover:text-foreground">ZG089</Link></span>
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

function IcoCircle({ children }: { children: ReactNode }) {
  return (
    <div className="flex-shrink-0 flex h-10 w-10 items-center justify-center rounded-full bg-primary/10">
      {children}
    </div>
  )
}

function FeatureBubble({ icon, text }: { icon: ReactNode; text: string }) {
  return (
    <div className="flex items-center gap-2 px-3 py-2 bg-red-600/10 border border-red-600/20 rounded-full">
      <div className="text-red-600">
        {icon}
      </div>
      <span className="text-sm font-medium text-red-600">{text}</span>
    </div>
  )
}
