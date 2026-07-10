<div align="center">
  
<img src="./assets/Re-Malwack.png" alt="Re-Malwack" width="512" height="512"/>
</div>

---
<div align="center">

[![Module Version](https://img.shields.io/badge/Module_Version-v8.2-d51200?style=for-the-badge)](https://github.com/ZG089/Re-Malwack/releases/tag/v8.2)
[![Download](https://img.shields.io/github/downloads/ZG089/Re-Malwack/total?style=for-the-badge&cacheSeconds=2&color=d51200)](https://github.com/ZG089/Re-Malwack/releases)
[![Telegram Support group](https://img.shields.io/badge/Re--Malwack_Community-252850?style=for-the-badge&color=d51200&logo=telegram&logoColor=white)](https://t.me/Re_Malwack)
[![XDA Support thread](https://img.shields.io/badge/XDA_Support_thread-252850?style=for-the-badge&color=d51200&logo=xdadevelopers&logoColor=white)](https://xdaforums.com/t/re-malwack-revival-of-malwack-module.4690049/)
[![Discord Server](https://img.shields.io/discord/1463971306054881302?style=for-the-badge&logo=discord&label=Re-Malwack%20Community&color=d51200&logoColor=d51200)](https://discord.gg/6fgQCJWY2F)
[![Personal acc on XDA](https://img.shields.io/badge/Contact_Developer_via-XDA-252850?style=for-the-badge&color=d51200&logo=xdadevelopers&logoColor=d51200)](https://xdaforums.com/m/ZG089.11432109/)
[![Donation](https://img.shields.io/badge/Support%20Development-black?style=for-the-badge&logo=buymeacoffee&logoColor=white&logoSize=auto&color=d51200&cacheSeconds=2&link=https%3A%2F%2Fbuymeacoffee.com%2Fzg089&link=https%3A%2F%2Fbuymeacoffee.com%2Fzg089)](https://buymeacoffee.com/zg089)
![Built with](https://img.shields.io/badge/Made_with-Love_❤-d51200?style=for-the-badge)
</div>

<b align="center"> If you are looking for a final solution to get rid of ads, malware, and trackers forever, then Re-Malwack is the best choice for you and your family.</b>

## Table of Contents
- [Table of Contents](#table-of-contents)
- [Features // What makes this module special?](#features--what-makes-this-module-special)
- [Requirements](#requirements)
- [How to use Re-Malwack](#how-to-use-re-malwack)
  - [Option 1 - Via WebUI](#option-1---via-webui)
  - [Option 2 - Terminal](#option-2---terminal)
  - [Option 3 - Local VPN (no root)](#option-3---local-vpn-no-root)
- [Download](#download)
- [How does it work? - Frequently Asked Questions (FAQ)](#how-does-it-work---frequently-asked-questions-faq)
- [Activity](#activity)
- [Credits List](#credits-list)
  - [1 - Contributors](#1---contributors)
  - [2 - Hosts Sources Providers](#2---hosts-sources-providers)
  - [3 - Foundational Supporters](#3---foundational-supporters)
  - [4 - Acknowledgment](#4---acknowledgment)
- [Donations](#donations)

## Features // What makes this module special?

- ⛔ It blocks ads, malware and trackers By default[*], you can also block porn sites, fake news sites, gambling sites and social sites, and even use safebrowsing! _(note: may break some youtube features, use with caution!)_
- ⚙ Allows you to modify and manage hosts file (whitelist & blacklist urls, reset hosts, auto update adblock), changes apply ***instantly*** without a device reboot
- 💡 A smart protection status indicator in module description
- 📦 Shipped with a curated list of adblock profiles [!]
- 💫 Supports [wildcarded whitelisting](https://github.com/ZG089/Re-Malwack/blob/c09063e46b42ecb36b6b288f6382a2fcb29d4a19/changelog.md?plain=1#L94)
- 🧰 An app-like WebUI, Built with Vite and Material design Expressive UI _(Thanks to [@KOWX712](https://github.com/KOWX712) for his Awesome work)_
- ⏸ Ability to pause/resume adblock without disabling the module
- ⛑ Can handle hosts mounts by itself
- ▶ Module action button purpose customization (Pause/Resume protection - Update hosts)
- 🔄 Can indicate/show blocked entries count by each enabled blocklist & enabled host source
- 🔎 Ability to query domain, and check whether it's blocked, or redirected
- 📝 Supports adding custom hosts rules
- ✨ Easy to use, Just set and forget!
- 💉 Supports [zn-hostsredirect](https://github.com/aviraxp/ZN-hostsredirect/)
- 🧲 Ability to import your adblock setup from AdAway and bindhosts (Check out [2nd section in FAQ](#how-does-it-work---frequently-asked-questions-faq) to know how to)
- 📝 A detailed logging system to debug module behavior and to detect bugs
- 🛠 Supports Magisk, APatch and KernelSU (and their variants)
- 👀 Also can protect [non-root devices](https://github.com/ZG089/Re-Malwack/tree/main?tab=readme-ov-file#3-local-vpn-no-root)
- 🔧 Regularly maintained & updated
- ❤ Made with love and care

> [!CAUTION]
> **[*] Re-Malwack comes with a pre-configured adblock system in which you can use freely without worrying about setting up everything from scratch. However, some ads such as in-app sponsored posts on Facebook or Spotify ads that show up for "non-premium" users are _NOT_ blocked because they are elements inside the app itself, So stay aware.**

> [!TIP]
> **[!] A profile is a group of hosts sources in one file, there are several built-in profiles that differ between adblocking levels, and it's automatically selected - during installation of the module - based on your device resources, which makes sure you will get a perfect adblocking experience yet not sacrificing all your device performance, you may also switch between profiles anytime and even customize everything per your likings!**

> [!TIP]
> **[@] [BETA] Supported stuff for import: Hosts sources, custom rules (bindhosts only), whitelist and blacklist (bindhosts and AdAway)**

> [!CAUTION]
> **Also avoid using other types of adblock files, _only adblock files in hosts format (Linux/Windows) are accepted_** 

## Requirements

> [!IMPORTANT]
> - **Stable internet connection.** _(You can also install the module without internet, then setup things later after reboot)_
> - and umm...just a working brain.

> [!CAUTION]
> - **Do not use this module with any other ad blocker module/app, such as AdAway and Magisk's built-in systemless hosts module.**
> - **In case module is active but ads are not blocked in browsers such as chrome/chromium-based browsers, Please enable superuser mode in KSU manager app for target browser app then try again*** 


## How to use Re-Malwack


### Option 1 - Via WebUI

- Re-Malwack WebUI can be accesed using [KSU](https://github.com/tiann/KernelSU), [5ec1cff's KSUWebUIStandalone](https://github.com/5ec1cff/KsuWebUIStandalone)/[KOW's Fork of KSUWebUIStandalone](https://github.com/KOWX712/KsuWebUIStandalone), [Apatch](https://github.com/bmax121/APatch) and [MMRL](https://github.com/DerGoogler/MMRL)

### Option 2 - Terminal

- Run `su` then run `rmlwk` in the terminal to show up the next help message which will clarify how to use it:

```sh
[i] Usage: rmlwk [--argument] OPTIONAL: [--quiet]
          --update-hosts, -u: Update the hosts file.
          --profile, -p <default|lite|balanced|aggressive|custom>: Switch adblock level profile.
          --auto-update, -a <enable|disable>: Toggle auto hosts update.
          --custom-source, -c <add|remove|edit> ...: Add/remove/edit custom hosts sources.
          --custom-rule, -cr <add|remove> <IP> <domain>: Add or remove custom hosts rules.
          --reset, -r: Reset hosts file to default.
          --query-domain, -q <domain>: Query if a domain is blocked, redirected, or not blocked.
          --adblock-switch, -as: Toggle protections on/off.
          --block-trackers, -bt <disable>, block trackers, use disable to unblock.
          --block-porn, -bp <disable>: Block pornographic sites, use disable to unblock.
          --block-gambling, -bg <disable>: Block gambling sites, use disable to unblock.
          --block-fakenews, -bf <disable>: Block fake news sites, use disable to unblock.
          --block-social, -bs <disable>: Block social media sites, use disable to unblock.
          --whitelist, -w <add|remove> <domain|pattern> <domain2> ...: Whitelist domain(s), only whitelist one domain at a time, otherwise use wildcard or use multiple domains in case of unwhitelisting.
          --blacklist, -b <add|remove> <domain1> <domain2> ...: Blacklist domain(s).
          --export-logs, -e: Export logs to a tarball in Download directory.
          --help, -h: Display help.
          
          Example command: su -c rmlwk --update-hosts

```

### Option 3 - Local VPN (no root)

- You can still protect your device without needing for root access, visit our [repo](https://github.com/Re-Malwack/hosts) for our ready-to-use hosts sources! These can be also used on apps such as [DNSnet](https://play.google.com/store/apps/details?id=dev.clombardo.dnsnet), or [AdAway](https://f-droid.org/packages/org.adaway/), or any other app of your choice.

> [!NOTE]
> Default hosts sources used for non-root hosts can be found [here](https://github.com/ZG089/Re-Malwack/blob/main/.github/workflows/update-hosts.yml#L24)
> You can also see default hosts sources used for the module itself [here](https://github.com/ZG089/Re-Malwack/blob/main/module/common/sources.txt)
## Download

> [!TIP]
> - You can download the module from:\
[![MMRL](https://mmrl.dev/assets/badge.svg)](https://mmrl.dev/repository/zguectZGR/Re-Malwack)
> - Or from [Github Releases](https://github.com/ZG089/Re-Malwack/releases/latest) section.


## How does it work? - Frequently Asked Questions (FAQ)

> [!TIP]
> **How does this module block ads?**
> - It uses your system's `hosts` file systemlessly to block ads and malware by denying access for your phone to connect to them completely.


> [!TIP]
> **How to import my adblock setup from Bindhosts/AdAway?**
> - **If you're coming from Bindhosts:** simply keep the module turned on, flash Re-Malwack and it will auto detect the module during install and ask you if you would like to import or no.
> - **If you're coming from AdAway:** Export an AdAway backup file and place it in your `Downloads` folder inside your internal storage, the module will auto detect the file on installation and ask you if you would like to import or no.


> [!TIP]
> **There's a problem when using the module**
> - Export logs via module WebUI, then create an [issue](https://github.com/ZG089/Re-Malwack/issues) explaining your problem and attach ss of the problem if there is any. You can also report your problem in our [telegram support group](https://t.me/Re_Malwack) as well.

> [!TIP]
> **AdBlock doesn't work on some apps (ex: Chrome), or doesn't work completely**
> - As was said above, Make sure you have disabled umount for the target app (if you use KernelSU), also make sure you disabled LiteMode (if you use APatch). If nothing works then create an [issue](https://github.com/ZG089/Re-Malwack/issues) about it or report the problem in our [telegram support group](https://t.me/Re_Malwack). If you've already done these, and no result then switch to a stronger adblock profile/add more robust host source from your own choice.

> [!TIP]
> **Can I contribute in something?**
> - You may suggest features via [Github Issues](https://github.com/ZG089/Re-Malwack/issues) or in our [Telegram support group](https://t.me/Re_Malwack), You may also create your own fork of this repo, apply your modifications and then do a pull request explaining the change, and its importance.

> [!NOTE]
> - If you want to reach out to [@person0z](https://github.com/Person0z), contact him using his email: root@person0z.me.

## Activity

![Alt](https://repobeats.axiom.co/api/embed/50cd7eb6e07d7ff3f816d826d9cd6d2bf0551c03.svg)

## Credits List

### 1 - Contributors

- [@KOWX712](https://github.com/KOWX712)
- [@ikuyo-kita07](https://github.com/ikuyo-kita07/)
- [@GalaxyA14user](https://github.com/GalaxyA14user)
- [@myst-25](https://github.com/myst-25) (Testing & feedback)
- [@dnascorpionofficial](https://github.com/dnascorpionofficial) (Testing & feedback)

### 2 - Hosts Sources Providers

- [@Hagezi](https://github.com/hagezi)
- [@badmojr](https://github.com/badmojr)
- [@StevenBlack](https://github.com/StevenBlack)
- [@r-a-y](https://github.com/r-a-y)
- [@Rem01Gaming](https://github.com/Rem01Gaming)
- [@blocklistproject](https://github.com/blocklistproject)

### 3 - Foundational Supporters

- [@person0z](https://github.com/Person0z) - Malwack Founder
- [@topjohnwu](https://github.com/topjohnwu) - Magisk Founder

### 4 - Acknowledgment

- [jqlang/jq](https://github.com/jqlang/jq) - Command-line JSON processor
- [iqiyi/xHook](https://github.com/iqiyi/xHook) - A PLT hook library for Android native ELF

## Donations
As an 11th-grade student who have to study almost all the time, and at the same time taking care of projects like this, your support would mean the world to me. If you find this module useful, please consider making a small donation using the button below, this will make a difference in my life 😁❤️

[![Donation](https://img.shields.io/badge/BUY_ME_A_COFFEE-black?&logo=buymeacoffee&logoColor=black&style=for-the-badge&logoSize=50&color=%23FFDD00&cacheSeconds=2&link=https%3A%2F%2Fbuymeacoffee.com%2Fzg089&link=https%3A%2F%2Fbuymeacoffee.com%2Fzg089)](https://buymeacoffee.com/zg089)
