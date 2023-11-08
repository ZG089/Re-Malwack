# Malwack Magisk Module - Your Ultimate Defense Against Digital Pests

Say goodbye to the headaches of malware, spyware, and intrusive ads on your rooted device with the **Malwack Magisk Module**! This powerful module is your virtual shield, keeping your digital space clean and secure.

## Features

- 🛡️ **Fortress-like Protection**: Malwack acts as your device's personal fortress within the Magisk framework, denying entry to all forms of cyber threats that try to sneak their way in.
- 🚫 **Adios, Annoying Ads**: Tired of pesky ads ruining your online experience? Malwack clears the clutter and lets you enjoy ad-free usage.
- 🕵️ **Spyware No More**: Keep prying eyes at bay! Malwack ensures your private information stays private, even in the rooted environment.
- ⚙️ **Effortless Performance**: Enjoy seamless device performance with Malwack's lightweight and efficient design tailored for Magisk.
- 🌐 **Universal Compatibility**: Whether you're on your rooted phone or tablet, Malwack guards them all within the Magisk ecosystem.

## Command Usage
[Termux](https://f-droid.org/en/packages/com.termux/) or any sort of terminal emulator is required to use, you can also use ADB if you know how to.

```
"Usage: malwack [--restore[-original | -default] | --blockporn | --whitelist <domain> | --help]"
"--restore-default: Restore the hosts file to the modules default state & updates it."
"--restore-original: Restore the hosts file to its original state. (No blocking)"
"--blockporn: Block pornographic websites by adding entries to the hosts file."
"--whitelist <domain>: Remove the specified domain from the hosts file."
"--help: Display this help message."
```

## Total Blocked
- 850,000+ Malware, Ads, Spyware

## How does it work?

**Where is the file?**
- Your ``hosts`` file located in ``/system/etc``. It "acts" like your school blocking service that blocks you from going to websites. However, this (the ``Hosts`` file) is done locally on your phone's root system. 

**How does the host's file block websites and what modifications were made?**
- How does it block websites: The host file blocks websites and malware by denying access for your phone to connect to it at all. It will just return a blank page. ``0.0.0.0 www.the-website-that-is-blocked.com``.
- Modifications that were made to the host file. The hosts file was used from [Hosts file provider](https://github.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/tree/master/hosts) There were 4 files, I've merged all of them together to make one giant file that will block all spyware, malware, ads. This has over 500,000+ websites blocked that are harmful and annoying (ads). 

## Get Started

Protect your rooted digital realm today with Malwack Magisk Module! Follow these simple steps:

1. **Download & Install**: Open Magisk Manager, go to Modules section, click on the '+' icon, then select the Malwack Module zip file to install.
2. **Reboot**: Reboot your device to activate the Malwack Module's protective features.
3. **Enjoy**: Experience a cleaner, safer digital experience on your rooted device with Malwack.

For any inquiries or assistance, reach out to me at root@person0z.me.

# The awesome people who made this work
- [@topjohnwu](https://github.com/topjohnwu) - Magisk Creator
- [@Zackptg5](https://github.com/Zackptg5/MMT-Extended) - Magisk Template Creator
- [@Ultimate.Hosts.Blacklist](https://github.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist) /system/etc/hosts file 
- [@StevenBlack](https://github.com/StevenBlack/hosts) /system/etc/hosts file
- [@Lightswitch05](https://github.com/Lightswitch05/hosts) /system/etc/hosts file

---
© 2023 Malwack Technologies. All rights reserved.
