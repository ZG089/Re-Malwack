## v6.0
- 🐛 Fixed bug where installer detects disabled conflicted module.  
- 🐛 Fixed bug where whitelist, blacklist, and newly downloaded hosts don't apply due to a broken mount.  
- ⚡ Rewritten full script code for better performance and speed.  
- 🛠️ Added module update/install detection.  
- ⚡ Implemented parallel downloads for a quicker installation/update process.  
- 🔗 Integrated main script with module installer script.  
- 🔄 Added auto-update hosts option.  
- 🔒 Added Social block.  
- 📝 You can now edit, add, or remove host source URLs. 
- ✅ Added online whitelist.  
- 📜 Added logging system.  
- 📤 Added option to export logs via WebUI.  
- 🕵️‍♂️ Hide script detection, now mounted to root manager binaries dir for better hiding.  
- 👀 You can now view whitelisted and blacklisted entries via script or WebUI.  
- ⚠️ Added warning (in WebUI) when resetting hosts, to prevent accidental wipe.  
- 🔄 Added check for WebUI JS API status for MMRL App.  
- 🖥️ Added WebUI JS API request prompt.  
- ✅ Added "confirmation" argument to reset hosts command, preventing accidental wipe.  
- ⌨️ Added shorter prefixes for commands.  
- 🎨 Various UI improvements in WebUI.  
- 📡 Added possibility to use Re-Malwack hosts using local VPN (no root).  
- 🔘 Blocklists are now toggleable via WebUI and script.  
- 📥 Blocklists now update when updating hosts (only effective for the user’s enabled blocklists).  
- 🚫 Removed hBlock hosts source for faster hosts processing. However, you can still add it manually via script or WebUI.  
- 🛑 Implemented social whitelist exception when Social block is enabled.  
- ⚡ Made installer wizard quicker and quieter.  
- 🎖️ Updated credits.  

## v5.3.0
- ⛔ Enhanced ads, malware and trackers blocking experience.
- ✨ The module got a new webUI which you can open using [KSUWebUI](https://github.com/5ec1cff/KsuWebUIStandalone) or using [MMRL](https://github.com/DerGoogler/MMRL).
- 🛠 Fixed bug in conflicts checker code where it didn't show the conflicted module name(s) properly. (Thanks for @GalaxyA14User and @forsaken-heart24)
- 👌 Enhanced installation script
- 🔁 You can now see protection status in module description in your root manager (As well as in webUI)
- 🛡 Added service.sh to update protection status periodically
- 👍 The script can now be used in other terminals, not only termux
- 🎯 Updated Telegram username in module.prop
- 🚀 Several bug fixes and code optimizations and enhancements
## v5.2.4
- 🛠 Fixed syntax error in "rmlwk"
- 🛠 Fixed Several other bugs, removed unwanted/extra codes
- 🎯 Using Pro Plus Compressed hosts file from Hagezi's instead of pro
- 🎯 Using hBlock hosts file along with the hosts file sources from previous version
## v5.2.3
- 😶 Again, working on ad block enhancements
- 🎯 Improving p*rn blocking
- 🛠 Fix Action.sh not working
## v5.2.2
- 🎯 Fix update bug where conflicts checker thinks the module conflicts itself (Thanks for @GalaxyA14User)
- ✨ enhanced conflicts checker
- 🔁 Using curl instead of wget in action.sh
- 😄 Last but not the least: Enhanced ad blocking experience, and hosts file is now smaller, it mustn't affect device perfomance.
## v5.2.1-hotfix
- 🎯 Fix extraction error
## v5.2.1
- 🎯 Fix Conflicts counter
## v5.2.0
- 🆕 Added "-h" argument, does the same job as "--help"
- 🆕 Added ability to block Gambling & Fake news sites into the built-in tool. 
- 🆕 The module will now download updated hosts file during installation.
- 🆕 Added Action button, clicking on it updates the hosts file.
- ⛔ Added conflicts checker during installation (thanks to @forsaken-heart24!)
- 🔁 Changed the built-in tool name to "rmlwk" instead of "re-malwack".
- 🤩 Added some touches to the built-in tool :)
- 🚀 Code optimization and performance enhancement. (Special thanks for @forsaken-heart24!)
---
## v5.1.0
- ✨ First update for Re-Malwack.
- 🆕 Added support for KernelSU (Requires overlayfs module if updating hosts doesn't work)
- 🔧 Updated main hosts file download link.
- 🛠️ Fixed an issue where the updated hosts file cannot replace the current hosts file or even change its perms, all of that by applying a new mechanism for hosts update.
- 🚫 Added "Blacklist" Feature.
- 🛠️ Fixed "Whitelist" feature.
- 🔄 Renamed "--restore-default" argument to "--update-hosts" 
- 🔄 Renamed "--restore-original" argument to "--reset"
- ⚙️ Changed descriptions of some arguments.
- 🗑️ Removed built-in sed binary, curl binary and mv binary, The module now requires Termux app in order to work properly. Dependency on termux may be changed in the future updates.
- ↩️ Added Ability to reset hosts file after uninstallation.
- ⚙️ Optimized code and fixed other bugs.
---
## v5.0.0
- Initial Revival of Malwack (existence of Re-Malwack)
---
## v4.2.1
- Fixed the help command adding the ``whitelist`` command on it.
## v4.2
- Updated Hosts file and added a new hosts link
---
## v4.1
- Update Hosts File
- Fixed changelog
---
## v4.0
- Updated Hosts file
- Updated readme.md
- Added Sed and MV commands with rw perms
- Added a new command that allows users to whitelist domains.
---
## v3.0
- Added curl command as some users do not have it installed on their phones
- Fixed the malwack command to get hosts file and to block porn as curl was not working for some users.
- Updated Hosts file
---
## v2.6
- Update Hosts file
---
## v2.5
- Update Hosts file
---
## v2.4
- Update Hosts File
---
## v2.3
- Update Hosts fle
---
## v2.2
- Update Hosts File
---
## v2.1
- update hosts file
---
## v2.0 - Major Update
- Added terminal commands
- use ``malwack --help`` for all available commands
- Updated README.md
- Updated hosts life
---
## v1.4
- Updated hosts file
- added custom header to hosts file 
---
## v1.3
- Added a new hosts list provider [hosts](https://github.com/StevenBlack/hosts)
- Updated hosts file with current
---
## v1.2
- Updated hosts file
- Added more info to ``README.md``
