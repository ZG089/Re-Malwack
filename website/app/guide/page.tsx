import Link from "next/link"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { SiteHeader } from "@/components/site-header"
import Footer from "@/components/footer"

export default function GuidePage() {
  return (
    <div className="flex flex-col min-h-screen">
      <SiteHeader />
      <div className="container py-12 md:py-24 lg:py-32">
        <div className="mx-auto flex max-w-[980px] flex-col items-center gap-4 text-center">
          <h1 className="text-3xl font-bold leading-tight tracking-tighter md:text-5xl lg:text-6xl text-red-600">
            Re-Malwack Guide
          </h1>
          <p className="max-w-[700px] text-lg text-muted-foreground">
            Everything you need to know about using Re-Malwack
          </p>
        </div>

        <div className="mx-auto max-w-3xl py-12">
          <Tabs defaultValue="installation" className="w-full">
            <TabsList className="grid w-full grid-cols-3">
              <TabsTrigger value="installation">Installation</TabsTrigger>
              <TabsTrigger value="usage">Usage</TabsTrigger>
              <TabsTrigger value="faq">FAQ</TabsTrigger>
            </TabsList>
            <TabsContent value="installation" className="mt-6">
              <Card>
                <CardHeader>
                  <CardTitle className="text-red-600">Installation Guide</CardTitle>
                  <CardDescription>Follow these steps to install Re-Malwack</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <h3 className="text-lg font-medium text-red-600">Requirements</h3>
                  <ul className="list-disc pl-5 space-y-2">
                    <li>Android device (Android 6.1+)</li>
                    <li>Magisk installed (v20.0+ recommended)</li>
                    <li>Internet connection (for downloading hosts files)</li>
                  </ul>

                  <h3 className="text-lg font-medium text-red-600">Installation Steps</h3>
                  <ol className="list-decimal pl-5 space-y-2">
                    <li>
                      Download the module from the{" "}
                      <Link href="/download" className="text-primary hover:underline">
                        download page
                      </Link>
                    </li>
                    <li>Open Magisk Manager</li>
                    <li>Go to Modules section</li>
                    <li>Click on Install from storage</li>
                    <li>Select the downloaded zip file</li>
                    <li>Reboot your device after installation completes</li>
                  </ol>

                  <div className="rounded-lg bg-muted p-4 text-sm">
                    <p className="font-medium">Note:</p>
                    <p>
                      If you encounter any issues during installation, please check the FAQ section or report the issue
                      on our GitHub repository.
                    </p>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>
            <TabsContent value="usage" className="mt-6">
              <Card>
                <CardHeader>
                  <CardTitle className="text-red-600">Usage Guide</CardTitle>
                  <CardDescription>Learn how to use Re-Malwack effectively</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <h3 className="text-lg font-medium text-red-600">How to Use Re-Malwack</h3>
                  <p className="mb-4">
                    Re-Malwack works automatically after installation. No additional configuration is required for basic
                    functionality.
                  </p>

                  <h3 className="text-lg font-medium text-red-600">Customization Options</h3>
                  <div className="space-y-2">
                    <p>
                      <strong>To customize your ad-block experience:</strong>
                    </p>
                    <ol className="list-decimal pl-5 space-y-2">
                      <li>
                        Open Re-Malwack's WebUI or use the module script via Termux
                      </li>
                      <li>
                        There you can control ad-block protection as you like.
                      </li>
                    </ol>
                  </div>

                  <div className="rounded-lg bg-muted p-4 text-sm">
                    <p className="font-medium">Tip:</p>
                    <p>
                      For best results, keep your hosts file updated to ensure you have the latest protection
                      against new threats.
                    </p>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>
            <TabsContent value="faq" className="mt-6">
              <Card>
                <CardHeader>
                  <CardTitle className="text-red-600">Frequently Asked Questions</CardTitle>
                  <CardDescription>Common questions and answers about Re-Malwack</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="space-y-2">
                    <h3 className="font-medium text-red-600">How does Re-Malwack work?</h3>
                    <p className="text-sm text-muted-foreground">
                      Re-Malwack works by modifying your device's hosts file to block connections to known ad servers,
                      malware domains, and inappropriate content sites. When an app or website tries to connect to these
                      blocked domains, the connection is blocked (0.0.0.0), effectively
                      preventing the content from loading (Returns a blank page).
                    </p>
                  </div>
                  <div className="space-y-2">
                    <h3 className="font-medium text-red-600">Will Re-Malwack slow down my device?</h3>
                    <p className="text-sm text-muted-foreground">
                      No, Re-Malwack is designed to be lightweight and efficient. In fact, by blocking ads and trackers,
                      it may actually improve your device's performance and battery life by reducing unnecessary network
                      requests.
                    </p>
                  </div>
                  <div className="space-y-2">
                    <h3 className="font-medium text-red-600">Does Re-Malwack require root access?</h3>
                    <p className="text-sm text-muted-foreground">
                      Yes, Re-Malwack requires root access to modify the system hosts file. Still you can use Re-Malwack
                      protection without root by adding the url <code className="bg-muted px-1 py-0.5 rounded">https://raw.githubusercontent.com/ZG089/Re-Malwack/refs/heads/hosts-update/hosts</code>
                      into AdAway or your favourite DNS/local VPN app.
                    </p>
                  </div>
                  <div className="space-y-2">
                    <h3 className="font-medium text-red-600">What content does Re-Malwack block?</h3>
                    <p className="text-sm text-muted-foreground">
                      Re-Malwack blocks ads, malware, trackers, adult content, gambling sites, fake news sites, and
                      other potentially harmful or inappropriate content.
                    </p>
                  </div>
                  <div className="space-y-2">
                    <h3 className="font-medium text-red-600">A legitimate site is being blocked. What should I do?</h3>
                    <p className="text-sm text-muted-foreground">
                      If a legitimate site is being blocked, you can add it to the whitelist. Reboot your device if changes aren't applied.
                    </p>
                  </div>
                  <div className="space-y-2">
                    <h3 className="font-medium text-red-600">How often are the blocklists updated?</h3>
                    <p className="text-sm text-muted-foreground">
                      The blocklists are updated whenever you update hosts, so don't worry about them being outdated :)
                    </p>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </div>

        <div className="mx-auto max-w-[700px] text-center">
          <p className="text-muted-foreground">Need more help? Join our community or open an issue on GitHub.</p>
          <div className="mt-4 flex justify-center gap-4">
            <Button variant="outline" asChild>
              <Link href="https://github.com/ZG089/Re-Malwack/issues">Report an Issue on GitHub</Link>
            </Button>
          </div>
          <div className="mt-4 flex justify-center gap-4">
            <Button variant="outline" asChild>
              <Link href="https://t.me/Re_Malwack">Report an Issue on Telegram Official Support group</Link>
            </Button>
          </div>
        </div>
      </div>
      <Footer />
    </div>
  )
}
