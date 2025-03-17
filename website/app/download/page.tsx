import Link from "next/link"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Download, MessageCircle, Send } from "lucide-react"
import { SiteHeader } from "@/components/site-header"

export default function DownloadPage() {
  return (
    <div className="flex flex-col min-h-screen">
      <SiteHeader />
      <div className="container py-12 md:py-24 lg:py-32">
        <div className="mx-auto flex max-w-[980px] flex-col items-center gap-4 text-center">
          <h1 className="text-3xl font-bold leading-tight tracking-tighter md:text-5xl lg:text-6xl text-red-600">
            Download Re-Malwack
          </h1>
          <p className="max-w-[700px] text-lg text-muted-foreground">
            Choose the version that best suits your device and needs
          </p>
        </div>
        <div className="mx-auto grid max-w-5xl gap-6 py-12 lg:grid-cols-2">
          <Card>
            <CardHeader>
              <CardTitle className="text-red-600">Stable Release</CardTitle>
              <CardDescription>Recommended for most users</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">
                The latest stable version with comprehensive ad blocking, malware protection, and content filtering.
              </p>
            </CardContent>
            <CardFooter>
              <Button className="w-full bg-red-600 hover:bg-red-700 text-white" asChild>
                <Link href="https://github.com/ZG089/Re-Malwack/releases/latest">
                  <Download className="mr-2 h-4 w-4" />
                  Download Stable
                </Link>
              </Button>
            </CardFooter>
          </Card>
          <Card>
            <CardHeader>
              <CardTitle className="text-red-600">Development Build</CardTitle>
              <CardDescription>For advanced users</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">
                The latest development build with cutting-edge features. May contain bugs.
              </p>
            </CardContent>
            <CardFooter>
              <Button variant="outline" className="w-full" asChild>
                <Link href="https://t.me/Re_Malwack/1314" target="_blank" rel="noreferrer">
                  <Send className="mr-2 h-4 w-4" />
                  View on Telegram
                </Link>
              </Button>
            </CardFooter>
          </Card>
        </div>
        <div className="mx-auto max-w-[700px] text-center">
          <h2 className="mb-4 text-2xl font-bold text-red-600">Installation Instructions</h2>
          <div className="rounded-lg bg-muted p-6 text-left">
            <ol className="list-decimal pl-5 space-y-2">
              <li>Download the module zip file</li>
              <li>Open Magisk Manager</li>
              <li>Go to Modules section</li>
              <li>Click on Install from storage</li>
              <li>Select the downloaded zip file</li>
              <li>Reboot your device after installation completes</li>
            </ol>
          </div>
        </div>

        <div className="mx-auto max-w-[700px] text-center mt-12">
          <h2 className="mb-4 text-2xl font-bold text-red-600">Support</h2>
          <p className="mb-6 text-muted-foreground">
            Need help with Re-Malwack? Join our official Telegram support group for assistance, updates, and
            discussions.
          </p>
          <Button className="bg-[#0088cc] hover:bg-[#0077b5] text-white" size="lg" asChild>
            <Link href="https://t.me/Re_Malwack" target="_blank" rel="noreferrer">
              <MessageCircle className="mr-2 h-5 w-5" />
              Join Telegram Support Group
            </Link>
          </Button>
        </div>
      </div>
      <footer className="border-t py-6 md:py-0 mt-auto">
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

