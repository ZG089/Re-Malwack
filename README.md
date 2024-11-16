<div align="center">
  
<a href="https://ibb.co/MRfcZnF"><img src="https://i.ibb.co/MRfcZnF/20240828-173916-0000-modified.png" alt="20240828-173916-0000-modified" border="0"></a>
</div>
<h1 align="center">Re-Malwack</h1>
<h2 align="center">It's Malwack, but built different 🗿</h2>

![Hosts Update Status](https://img.shields.io/badge/Hosts_update_status-Daily-green)
![Module Version](https://img.shields.io/badge/Module_Version-v5.2.0-green)
[![Download](https://img.shields.io/github/downloads/ZG089/Re-Malwack/total?&cacheSeconds=2)](https://github.com/ZG089/Re-Malwack/releases)
![Hosts Update Time](https://img.shields.io/badge/Hosts_update_Time-≈19:30_UTC-green)
![Built with](https://img.shields.io/badge/Made_with-Love-red)
![GitHub repo size](https://img.shields.io/github/repo-size/ZG089/Re-Malwack)
[![Channel](https://img.shields.io/badge/Channel-ZGTechs-252850?color=blue&logo=telegram)](https://t.me/ZGTechs)
[![Personal acc on TG](https://img.shields.io/badge/Contact_Developer_via-Telegram-252850?color=blue&logo=telegram)](https://t.me/zgx_dev)
[![Personal acc on XDA](https://img.shields.io/badge/Contact_Developer_via-XDA-252850?color=orange&logo=xdadevelopers)](https://xdaforums.com/m/zg_dev.11432109/)
[![XDA Support thread](https://img.shields.io/badge/XDA_Support_thread-252850?color=gray&logo=xdadevelopers)](https://xdaforums.com/t/re-malwack-revival-of-malwack-module.4690049/)
[![Donation](https://img.shields.io/badge/Support%20Development-black?&logo=buymeacoffee&logoColor=black&logoSize=auto&color=%23FFDD00&cacheSeconds=2&link=https%3A%2F%2Fbuymeacoffee.com%2Fzg089&link=https%3A%2F%2Fbuymeacoffee.com%2Fzg089)](https://buymeacoffee.com/zg089)

## Features

- Same as [Malwack](https://github.com/Magisk-Modules-Alt-Repo/Malwack/#features) (P*rn block, whitelist, reset hosts, ad block, protection from malware.)
- 🚫 Has Blacklist Feature
- ⛔ Blocks P*rn sites, fake news sites, and gambling sites
- 🛠️ Hosts file is updated daily
- ✨ Supports Magisk (v20.0+), KernelSU and Apatch (Apatch is not tested)
- 🔧 Regularly maintained & updated
- ⚙️ Fixed Malwack's bugs 
- 🔜 More soon....

> [!IMPORTANT]
> ## Requirements
> - Requires [Termux](https://f-droid.org/en/packages/com.termux/) App.
> - Requires internet connection in order to download hosts file during installation, otherwise it will use the bundled hosts file.

## Download Module
> [!TIP]
> You can download the module from [Releases](https://github.com/ZG089/Re-Malwack/releases/latest) section.


## Get started
> [!NOTE]
> 1. Open Magisk, go to Modules section, click on the '+' icon, then select the Re-Malwack Module zip file to install.
> 2. Reboot your device to activate the Re-Malwack Module's protective features.
> 3. Enjoy, Your device is fully protected now :)

## Command Usage (How to use Re-Malwack on Terminal)

Type``su -c rmlwk`` on Termux to show up the help message which will output this:

```
"Usage: rmlwk [ --reset | --block-porn | --block-gambling | --block-fake |  --update-hosts | --blacklist <domain> | --whitelist <domain> | --help | -h ]"
"--update-hosts: Updates the hosts file"
"--reset: Restore the hosts file to its original state. (Disable ads blocking)"
"--block-porn: Block pornographic websites by adding entries to the hosts file."
"--block-gambling: Block gambling sites"
"--block-fake: Block Fake news sites"
"--whitelist <domain>: Remove the specified domain from the hosts file."
"--blacklist <domain>: Adds domain to the hosts file to be blocked"
"--help: Display this help message."
"-h: same as --help
```

> [!WARNING]
> Do not use this module with any other ad blocker module, such as AdAway and Magisk's built-in systemless hosts module. They may get angry if they met each other, and may cause a war that will benefit no one.

> [!NOTE]
> - For KernelSU users and for those who noticed that the hosts file isn't updated after running ``su -c rmlwk --update-hosts``, install [Overlayfs](https://github.com/HuskyDG/magic_overlayfs) module, configure it and it will work. (if you need help configuring it then contact with me via Telegram or XDA)


> [!TIP]
> ## Total Blocked
> - 907,120+ Malware, Ads, Spyware

## How does it work?
> [!TIP]
> **Where is the file?**
> - Your ``hosts`` file located in ``/system/etc``. It "acts" like your school blocking service that blocks you from going to websites. However, this (the ``Hosts`` file) is done locally on your phone's root system. 

> [!TIP]
> **How does the host's file block websites and what modifications were made?**
> - How does it block websites: The host file blocks websites and malware by denying access for your phone to connect to it at all. It will just return a blank page. ``0.0.0.0 www.the-website-that-is-blocked.com``.

> [!TIP]
> **Does it blocks in-app ads and in-game ads as well ?**
> - Of course it does ! All of this using the magic of magisk and the hosts file !


> [!NOTE]
> - For any inquiries or assistance, reach out to me at [XDA](https://xdaforums.com/m/zg_dev.11432109/) or [Telegram](https://t.me/zgx_dev)
> - If you want to reach out to [@person0z](https://github.com/Person0z), contact him using his email: root@person0z.me.

# Activity

![Alt](https://repobeats.axiom.co/api/embed/50cd7eb6e07d7ff3f816d826d9cd6d2bf0551c03.svg)
 
# Credits
- [@person0z](https://github.com/Person0z) - Malwack Magisk module creator
- [@topjohnwu](https://github.com/topjohnwu) - Magisk Founder
- [@Zackptg5](https://github.com/Zackptg5/MMT-Extended) - MMTE Template
- [@Ultimate.Hosts.Blacklist](https://github.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist) /system/etc/hosts file 
- [@StevenBlack](https://github.com/StevenBlack/hosts) Porn sites + fake news blocklist
- [@GalaxyA14user](https://github.com/GalaxyA14user) - Fixing bugs + contribution to the Re-Malwack project
- [@forsaken-heart24](https://github.com/forsaken-heart24) - Contribution to the Re-Malwack Project
- And Finally, YOU! For using my module :)

# Donations

As a 10th-grade student who have to study almost all the time, and at the same time taking care of projects like this, your support would mean the world to me. If you find this module useful, please consider making a small donation using the button below, this will make a difference in my life 😁❤️

[![Donation](https://img.shields.io/badge/BUY_ME_A_COFFEE-black?&logo=buymeacoffee&logoColor=black&style=for-the-badge&logoSize=50&color=%23FFDD00&cacheSeconds=2&link=https%3A%2F%2Fbuymeacoffee.com%2Fzg089&link=https%3A%2F%2Fbuymeacoffee.com%2Fzg089)](https://buymeacoffee.com/zg089)
