import Link from "next/link"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Download, MessageCircle, Send } from "lucide-react"
import { SiteHeader } from "@/components/site-header"
import Footer from "@/components/footer"

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
        <div className="mx-auto grid max-w-5xl gap-6 py-12 grid-cols-1 lg:grid-cols-2">
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
          <Card className="lg:col-span-2">
            <CardHeader>
              <CardTitle className="flex flex-row justify-between">
                <span className="text-red-600">Installation Guide</span>
                <Button className="h-8 hidden sm:block">
                  <Link href="https://t.me/Re_Malwack" target="_blank" rel="noreferrer" className="flex items-center gap-2">
                    <Send />
                    Get Support
                  </Link>
                </Button>
              </CardTitle>
              <CardDescription>Let&apos;s get you started!</CardDescription>
            </CardHeader>
            <CardContent>
              <ol className="list-decimal pl-5 space-y-2">
                <li>Download your desired module ZIP</li>
                <li>Open your root manager (Magisk, KernelSU, etc.)</li>
                <li>Go to Modules section</li>
                <li>Click on Install from storage</li>
                <li>Select the downloaded ZIP</li>
                <li>Reboot your device after installation completes</li>
              </ol>
            </CardContent>
          </Card>
        </div>

        <div className="mx-auto max-w-[700px] text-center mt-12">
          <h2 className="mb-4 text-2xl font-bold text-red-600">Support</h2>
          <p className="mb-6 text-muted-foreground">
            Need help with Re-Malwack? Join our official Telegram support group for assistance, updates, and
            discussions.
          </p>
          <Button className="bg-[#0088cc] hover:bg-[#0077b5] text-white" size="lg" asChild>
            <Link href="https://t.me/Re_Malwack" target="_blank" rel="noreferrer">
              <MessageCircle className="mr-2" />
              Join Telegram Support Group
            </Link>
          </Button>
        </div>
      </div>
      <Footer />
    </div>
  )
}

