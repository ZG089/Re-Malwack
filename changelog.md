## v8.1

_(This release contains lots of bug fixes that existed in v8. Sorry for the inconveinces.)_

### Bug Fixes

**Core**
- Fixed profile status not being refreshed
- Fixed possible visual WebUI issue caused by backend script error
- Fixed domain URL redirect in link redirect feature in WebUI
- Fixed protection idle status logic detection
- Fixed profile parsing into config

### Features

**Scripts**
- **Better profile switching logic**: Added consideration to prevent re-switching profile to custom when modifying host sources while custom profile is already selected

**UX**
- Added ⚙️ icon before "Profile" in module status message for better visual indication

### General Changes

**Code Quality & Maintenance**
- Better profile handling in config file (preventing duplicated entries)
- Improved module action script cleanup
- Improved version badge display in module banner

**Workflow & CI/CD**
- Added KernelSU module repository sync workflow (Still WIP for now)
- Small adjustment to release workflow for version naming in Telegram projects channel

## v8.0

### Bug Fixes

**Scripts**
- Fixed missing auto-update handler that was accidentally removed
- Fixed cache hosts file name pattern issues
- Fixed trackers brand-specific hosts not being applied
- Fixed multiple logical bugs related to hosts update process
- Fixed whitelist handling and entries not being returned properly
- Fixed social whitelist being applied when it shouldn't be
- Fixed failed/errored commands not showing up in error messages
- Fixed syntax errors in multiple module files
- Fixed runtime errors trap logic
- Fixed "unexpected `0`" error during host refresh

**WebUI & Core**
- Fixed module_service crash issue
- Fixed whitelist/blacklist not showing proper error handling in WebUI

### Features

**Scripts**
- **Domain status query function**: Query if a domain is blocked, redirected, or not blocked in the hosts file with detailed feedback
- **Safebrowsing as separate toggle**: Separated safebrowsing from pornography block with its own independent toggle, preventing services like youtube from being broken on enabling pornography blocklist
- **Entries count per source**: Show blocked entries count for each host source
- **Hot source names parsing**: Added support for parsing and showing host source names
- **Dynamic host sources management**: Support for enabling/disabling, editing hosts sources & names
- **Custom hosts rules**: New feature to add custom blocking/redirecting rules with IP customization
- **Dynamic multi-sources toggling**: Add backend support for toggling individual host sources dynamically
- **Custom rules import**: Experimental import of custom rules from bindhosts with safety checks
- **Adblock profiles management**: New feature to manage and switch between different adblock profiles (Default, lite, balanced, agressive) with auto profile detection on installation based on device performance, Such a good solution for devices that may suffer device performance issues as well.
- **Action script mode**: Customize the purpose of module action button (pause/resume/update hosts)
- **Offline installation**: Allow module offline installation with idle protection status
- **Auto-resume protection**: Auto resume adblock in case of it being paused during installation
- **Enhanced connection handling**: Wait for internet connection instead of aborting, added retries limit of 6
- **Dynamic Busybox/Toybox support**: Use busybox crond applet directly without extra checks, added toybox support with full native fallback
- **Improved auto-update fallback**: Implement fallback when crond/busybox doesn't exist with proper error handling
- **Enhanced hosts remounting**: Improved hosts file mounting logic, avoiding bootloops and conflicts with metamodules, such as HybridMount
- **Hosts update parallelism limiting**: Limit parallel hosts update processing to be easier on device resources
- **Log improvements**: Adjust duration format from h:m:s to m:s:ms, better error logging
- **April joke feature**: Introducing "Re-Malware" easter egg for April 1st

**WebUI** _(Many thanks to @KOWX712)_
- **Material Web Components migration**: Full Vite-based build with Material Web Component integration
- **Theme&Design rework**: Completely reworked theming system using Material Design with dynamically loaded themes from theme.json
- **Domain query feature**: Query domain blocking status directly from WebUI
- **Loading indicator for cron toggle**: Visual feedback when enabling/disabling cron protection toggle
- **Action mode toggle**: Toggle for action script mode (pause/resume/update hosts)
- **Enhanced entries display**: Show entries count for each host source and enabled blocklist in WebUI
- **Hosts sources management**: UI improvements for enabling/disabling and editing host sources, alongside displaying host source name + favicon
_(NOTE: to add a host source with a name, you may enter the url and an inline comment with the host source name such as `https://example.com # Example Hosts`)_
- **Log exporting refactor**: Include module version in exported log zipfile
- **Terminal improvements**: Refactored terminal to not show output for play/pause actions
- **UI/UX improvements**: Multiple styling improvements, cleaner hosts sources box layout, better prompt styling

### General Changes

**Refactoring**
- Simplified auto update logic with better crond provider detection
- Remove useless function commands before actual function definitions
- Rewrite log_duration function for better human-readable execution times
- Enhanced error handling throughout the main core script

**Architecture Improvements**
- Set $PATH before checking for tools to ensure proper command availability
- Improved crond process detection and management

**Performance & Compatibility**
- Limit hosts update parallelism for easier device resource usage
- Add 1.5s cooldown after running crond for stability
- Better performance for blocklist handling logic
- Convert 127.0.0.1 entries to 0.0.0.0 for consistency
- Improved blocked entries counting to handle different block methods
- Limit loading parallelism for better device compatibility

**Code Quality**
- Drop useless function commands before functions
- Remove dead pornography hosts source link + extra source due to its large size
- Remove unused variables for cleaner code
- Respect user's disabled host sources on updating profiles and avoid duplications

**Workflow & CI/CD**
- Added Discord alert workflow for push events
- Improved GitHub Actions for Discord releases
- Auto changelog truncating on release
- Auto update module version badge on release
- Test build ID format changed to commit-hash@branch-name

**Documentation & Credits**
- Updated contributor usernames
- Updated hosts source links
- Whitelist improvements with new domain entries

## v7.0

### Please take a look at the notes at the end of the changelog after reading it, thank you.
### Oh and also HAPPY NEW YEAR!!!

### 🐛 Bug Fixes

**Scripts**
- Fixed a whitelist bug that could delete entire hosts file if a non-raw URL was entered
- Fixed abnormal output issues
- Fixed possible issue with internet connectivity check on module installation
- Fixed module status being reset
- Fixed other ad-blocking modules can be enabled after Re-Malwack installation & rebooting
- Fixed blacklist entries being parsed incorrectly as "0.0.0.0 domain.com0.0.0.0 blacklisted-domain.com"
- Removed non-related host source which was _accidentally_ added to pornography blocklist
- Fixed hosts file not being filtered during update
- Fixed "unexpected `0`" error during status updates
- Fixed incorrect root manager path detection for KernelSU/APatch
- Fixed hosts file having multiple spaces not being collapsed
- Fixed parsing of default hosts entries
- Fixed possible links being broken after using module (e.g Google Maps)

**WebUI**
- Fixed some ripple animation issues
- Fixed abnormal output issues

### ✨ Features

**Scripts**
- **Protection switch (Pause/Resume)**: Ability to pause and resume ad-blocking protection without disabling the module
- **Trackers block feature** (toggleable): New dedicated blocklist for tracking domains with separate toggle and auto-update capability
- **Import from other ad-blocker modules/apps**: New feature to import hosts from other ad-blocker modules/apps like bindhosts, Cubic-Adblock and AdAway [1] [2]
- **Improved hosts mounting**: The module now does an automatic hosts mount handling, this means that the module should work in most cases especially with mountify (technically any metamodule), or in case APatch lite mode was enabled [3]
- **ZN host redirect support**: Added initial support for ZN-hostsredirect module
- **Enhanced whitelisting**: Support for full URLs (automatic conversion to raw domains), better subdomain support, and wildcard whitelisting for domains containing asterisks (*) [4]
- **Better blacklist/whitelist/sources entries management**: You can now remove multiple domains instead of removing domains one-by-one.
- **Improved logging system**: Enhanced error logging outputs, included more detailed logging for an easier debugging process
- **Better URL sanitization**: Simpler and more robust URL handling for blacklist, whitelist and hosts sources
- **New ASCII banners**: Additional ASCII art banners with randomization for variety
- **Quiet mode argument (`--quiet`)**: Added `--quiet` argument for quieter operations (not to show ascii banner in case this argument was passed)
- **fail-safe strategies**: Added critical errors handling strategies, also some anti-exploit Implementations
- **Better module status message on module description**: More detailed, yet more perfect module status indicator message

**WebUI**
- **Complete UI Revamp**: 
  - New header card with module information
  - New module status dashboard
  - Warning card when protection is paused/reset
  - Revamped "About" section
- **test release indicator** Added a test release indicator for test releases
- **Theme switcher** (Light/Dark mode) in the header
- **Live terminal**: Real-time display during hosts update and blocklist toggling
- **Loading spinner on buttons**: Visual feedback for ongoing operations
- **Dashboard view**: Comprehensive overview of module status and statistics
- **FAB button**: Quick access to pause/resume protections
- **Multi-select capability**: Ability to select and batch remove multiple whitelist, blacklist entries, and sources
- **Batch operations**: Remove multiple entries at once instead of one by one
- **Paused status text**: Clear indication when protection is paused
- **Mount check**: Warning about broken hosts mount
- **ZN host redirect support**: Added support for ZN-hostredirect module
- **Festival mode**: Christmas edition with special visual effects

### General Changes

**Performance & Code Quality**
- Rewritten hosts update logic for significantly faster installation and processing
- Improved overall performance of hosts installation and processing pipeline
- Reduced unnecessary comments and code remnants
- Better code arrangement
- Improved trap logic for better error handling and logging

**Enhancements**
- Better output messages throughout the module
- Improved error logging and messages
- Replaced/Updated hosts sources file with extra and/or better hosts sources
- Logging of blocked entries count and last hosts file update time
- Logging of command execution time and triggers
- Better hosts reset/default state detection
- Improved detection of default hosts entries
- Sourcing config file earlier in script execution
- Better conditional arrangements for status checking

**Dependencies & Compatibility**
- Dropped compressed hosts support
- Dropped MMRL version check requirement in WebUI
- Support for KernelSU and APatch improved significantly

### Notes
- 1 - These are the supported things that you can import/merge into Re-Malwack:
> - `bindhosts` and `AdAway` -> hosts sources, blacklist, whitelist
> - `cubic-adblock` -> hosts sources only, you can refer to the sources from [here](https://github.com/Vaz15k/Cubic-AdBlock/blob/5c605d6ea5fba9a841615ec28de1c8ff1393029f/update_hosts.py#L53), 1hosts Pro is **excluded due to it being discontinued by 1hosts founder**
- 2 - In order to be able to import your adblock setup from AdAway to Re-Malwack, make sure you export a backup file from AdAway, uninstall AdAway + systemless hosts module, then store the exported backup file it in your `internal storage` -> `Downloads` folder, **do not rename the file to anything else other than `adaway-backup.json`**
- 3 - In case adblock doesn't work on browsers even though the module is active, or domain blacklisting/whitelisting doesn't apply or work perfectly inside browsers (and you don't have zn-hostsredirect module installed), while you're using KernelSU or any of its forks, **make sure to enable superuser option for browsers**
- 4 - Whitelist wildcard examples: `*domain.com - *.domain.com - *something - somthing*`
- 5 - Many thanks for @KOWX712, @bocchi-the-dev for their huge contributions to the module. Also thanks for @myst-25 for being an active tester and bug reporter in the module's [Telegram group](https://t.me/Re_Malwack)!
- 6 - And Finally, Thanks for everyone who waited for the new version of the module, I owe you all an apology for the release delay, but because I have a very busy life and after all, and that Re-Malwack is just a hobby project for me so yeah. But I'm always planning to make it bigger and better, so stay tuned for more :D

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
