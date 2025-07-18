import { spawn, exec, toast } from './assets/kernelsu.js';

const basePath = "/data/adb/Re-Malwack";
const modulePath = "/data/adb/modules/Re-Malwack";

const filePaths = {
    blacklist: 'blacklist.txt',
    whitelist: 'whitelist.txt',
    "custom-source": 'sources.txt',
};

let isShellRunning = false;

// Link redirect
const links = [
    { element: 'telegram', url: 'https://t.me/Re_Malwack' },
    { element: 'github', url: 'https://github.com/ZG089/Re-Malwack' },
    { element: 'xda', url: 'https://xdaforums.com/t/re-malwack-revival-of-malwack-module.4690049/' },
    { element: 'sponsor', url: 'https://buymeacoffee.com/zg089' }
];

// Block types
const blockTypes = [
    { id: 'porn', toggle: 'block-porn-toggle', name: 'porn sites', flag: '--block-porn' },
    { id: 'gambling', toggle: 'block-gambling-toggle', name: 'gambling sites', flag: '--block-gambling' },
    { id: 'fakenews', toggle: 'block-fakenews-toggle', name: 'fake news sites', flag: '--block-fakenews' },
    { id: 'social', toggle: 'block-social-toggle', name: 'social media sites', flag: '--block-social' }
];

let modeActive = false;

// Function to handle about menu
function aboutMenu() {
    const aboutOverlay = document.getElementById('about-overlay');
    const aboutMenu = document.getElementById('about-menu');
    const closeAbout = document.getElementById('close-about');
    const showMenu = () => {
        aboutOverlay.style.display = 'flex';
        setTimeout(() => {
            aboutOverlay.style.opacity = '1';
        }, 10);
        document.body.style.overflow = 'hidden';
    };
    const hideMenu = () => {
        aboutOverlay.style.opacity = '0';
        setTimeout(() => {
            aboutOverlay.style.display = 'none';
            document.body.style.overflow = 'auto';
        }, 300);
    };
    showMenu();
    closeAbout.addEventListener('click', (event) => {
        event.stopPropagation();
        hideMenu();
    });
    aboutOverlay.addEventListener('click', (event) => {
        if (!aboutMenu.contains(event.target)) {
            hideMenu();
        }
    });
    menu.addEventListener('click', (event) => event.stopPropagation());
}

// Get module version from module.prop
async function getVersion() {
    const version = await exec("grep '^version=' /data/adb/modules/Re-Malwack/module.prop | cut -d'=' -f2");
    if (version.errno === 0) {
        document.getElementById('version-text').textContent = version.stdout.trim();
        getStatus();
    }
}

// Function to check if running in MMRL
async function checkMMRL() {
    if (Object.keys($Re_Malwack).length > 0) {
        // Set status bars theme based on device theme
        try {
            $Re_Malwack.setLightStatusBars(!window.matchMedia('(prefers-color-scheme: dark)').matches)
        } catch (error) {
            console.error("Error setting status bars theme:", error)
        }
    } else {
        console.log("Not running in MMRL environment.");
    }
}

// Function to get working status
async function getStatus() {
    const statusElement = document.getElementById('status-text');
    const disableBox = document.querySelector('.header-disabled');
    try {
        const rawStatus = await exec("cat /data/adb/Re-Malwack/counts/blocked_mod.count");
        let status = rawStatus.stdout.trim();
        if (parseInt(status) === 0) {
            disableBox.style.display = 'flex';
            statusElement.textContent = '-';
            getlastUpdated(false);
            return;
        // Convert 1 000 000 to 1M
        } else if (parseInt(status) > 999999) {
            status = (parseInt(status) / 1000000).toFixed(1) + 'M';
        // Convert 1 000 to 1k
        } else if (parseInt(status) > 9999) {
            status = (parseInt(status) / 1000).toFixed(1) + 'k';
        }
        statusElement.textContent = status;
        disableBox.style.display = 'none';
    } catch (error) {
        console.error("Error getting status:", error);
    }
    getlastUpdated();
}

// Function to get last updated time of hosts file
async function getlastUpdated(isEnable = true) {
    const lastUpdatedElement = document.getElementById('last-update');

    if (!isEnable) {
        lastUpdatedElement.textContent = '-';
        return;
    }

    const last = await exec("date -r '/data/adb/modules/Re-Malwack/system/etc/hosts' '+%H %d/%m'");
    const now = await exec("date +'%H %d/%m'");
    if (last.errno === 0 || now.errno === 0) {
        // Last update today
        if (last.stdout.split(' ')[1] === now.stdout.split(' ')[1]) {
            if (last.stdout.split(' ')[0] === now.stdout.split(' ')[0]) {
                // Last update less than 1hr
                lastUpdatedElement.textContent = 'Just Now';
            } else {
                // Last update less than 24hr
                const hours = parseInt(now.stdout.split(' ')[0]) - parseInt(last.stdout.split(' ')[0]);
                lastUpdatedElement.textContent = `${hours}h ago`;
            }
        } else {
            // Last update yesterday
            if (parseInt(now.stdout.split(' ')[1].split('/')[0]) - parseInt(last.stdout.split(' ')[1].split('/')[0]) === 1) {
                lastUpdatedElement.textContent = 'Yesterday';
            }
            // Last update XX days ago
            else {
                const days = parseInt(now.stdout.split(' ')[1].split('/')[0]) - parseInt(last.stdout.split(' ')[1].split('/')[0]);
                lastUpdatedElement.textContent = `${days}d ago`;
            }
        }
    } else {
        console.error("Error getting last updated time:", last.stderr || now.stderr);
        lastUpdatedElement.textContent = '-';
    }
}

// Function to check block status for different site categories
async function checkBlockStatus() {
    try {
        const result = await fetch('link/persistent_dir/config.sh').then(response => {
            if (!response.ok) throw new Error('Config file not found');
            return response.text();
        });
        const lines = result.split("\n");
        
        // Check each block type
        for (const type of blockTypes) {
            const toggle = document.getElementById(type.toggle);
            const blockLine = lines.find(line => line.trim().startsWith(`block_${type.id}=`));
            if (blockLine) {
                const value = blockLine.split('=')[1].trim();
                toggle.checked = value === '1';
            } else {
                toggle.checked = false;
            }
        }

        // Check daily update status
        const dailyUpdateToggle = document.getElementById('daily-update-toggle');
        const dailyUpdateLine = lines.find(line => line.trim().startsWith('daily_update='));
        if (dailyUpdateLine) {
            const value = dailyUpdateLine.split('=')[1].trim();
            dailyUpdateToggle.checked = value === '1';
        } else {
            dailyUpdateToggle.checked = false;
        }
    } catch (error) {
        console.error('Failed to check status:', error);
        if (error.message === 'Config file not found') {
            try {
                await linkFile();
                await checkBlockStatus();
                return;
            } catch (linkError) {
                console.error('Failed to link file:', linkError);
            }
        }
        // Set all toggles to false on error
        for (const type of blockTypes) {
            const toggle = document.getElementById(type.toggle);
            toggle.checked = false;
        }
        // Set daily update toggle to false on error
        document.getElementById('daily-update-toggle').checked = false;
    }
}

/**
 * Run rmlwk command and show stdout in terminal
 * @param {string} commandOption - rmlwk --option
 * @returns {void}
 */
function performAction(commandOption) {
    const terminal = document.querySelector('.terminal');
    const terminalContent = document.getElementById('terminal-output-text');
    const backBtn = document.getElementById('aciton-back-btn');
    const closeBtn = document.querySelector('.close-terminal');

    terminal.classList.add('show');
    document.body.style.overflow = 'hidden';
    if (isShellRunning) return;

    const closeTerminal = () => {
        document.body.style.overflow = 'auto';
        terminal.classList.remove('show');
        terminalContent.innerHTML = "";
        closeBtn.classList.remove('show');
        backBtn.removeEventListener('click', () => closeTerminal());
        closeBtn.removeEventListener('click', () => closeTerminal());
    }

    backBtn.addEventListener('click', () => closeTerminal());
    closeBtn.addEventListener('click', () => closeTerminal());

    isShellRunning = true;
    const output = spawn('sh', ['/data/adb/modules/Re-Malwack/rmlwk.sh', `${commandOption}`], { env: { MAGISKTMP: 'true' }});
    output.stdout.on('data', (data) => {
        const newline = document.createElement('p');
        newline.className = 'output-line';
        newline.textContent = data;
        terminalContent.appendChild(newline);
    });
    output.on('exit', (code) => {
        isShellRunning = false;
        closeBtn.classList.add('show');
        getStatus();
        checkBlockStatus();
    });
}

// Function to update hosts file
function updateHostsFile() {
    performAction("--update-hosts");
}

// Function to reset hosts
async function resetHostsFile() {
    const resetOverlay = document.getElementById("confirmation-overlay");
    const cancelButton = document.getElementById("cancel-reset");
    const resetButton = document.getElementById("confirm-reset");

    resetOverlay.style.display = 'flex';
    setTimeout(() => {
        resetOverlay.style.opacity = 1;
    }, 10)

    const closeResetOverlay = () => {
        resetOverlay.style.opacity = 0;
        setTimeout(() => {
            resetOverlay.style.display = 'none';
        }, 200)
    }

    let setupListener = true;
    if (setupListener) {
        cancelButton.addEventListener('click', () => closeResetOverlay());
        resetOverlay.addEventListener('click', (e) => {
            if (e.target === resetOverlay) closeResetOverlay();
        })
        resetButton.addEventListener('click', () => {
            closeResetOverlay();
            performAction("--reset");
        })
        setupListener = false;
    }
}

// Function to enable/disable daily update
async function toggleDailyUpdate() {
    const isEnabled = document.getElementById('daily-update-toggle').checked;
    const result = await exec(`sh /data/adb/modules/Re-Malwack/rmlwk.sh --auto-update ${isEnabled ? "disable" : "enable"}`);
    if (result.errno !== 0) {
        showPrompt("Failed to toggle daily update", false);
        console.error("Error toggling daily update:", result.stderr);
    } else {
        showPrompt(`Daily update ${isEnabled ? "disabled" : "enabled"}`, true);
        await checkBlockStatus();
    }
}

// Function to export logs
async function exportLogs() {
    const result = await exec(`
        LOG_DATE="$(date +%Y-%m-%d_%H%M%S)"
        tar -czvf /sdcard/Download/Re-Malwack_logs_$LOG_DATE.tar.gz --exclude='${basePath}' -C ${basePath} logs &>/dev/null
        echo "$LOG_DATE"
    `);
    if (result.errno === 0) {
        showPrompt(`Logs saved to /sdcard/Download/Re-Malwack_logs_${result.stdout.trim()}.tar.gz`, true, 3000);
    } else {
        console.error("Error exporting logs:", result.stderr);
        showPrompt("Failed to export logs", false);
    }
}

// Function to handle blocking/unblocking different site categories
function handleBlock(type) {
    const toggle = document.getElementById(type.toggle);
    const isRemoving = toggle.checked;
    const action = isRemoving ? `${type.flag} 0` : type.flag;

    performAction(action);
}

// Function to show prompt
function showPrompt(message, isSuccess = true, duration = 2000) {
    const prompt = document.getElementById('prompt');
    prompt.textContent = message;
    prompt.classList.toggle('error', !isSuccess);
    if (window.promptTimeout) {
        clearTimeout(window.promptTimeout);
    }
    setTimeout(() => {
        prompt.style.transform = 'translateY(calc((var(--window-inset-bottom, 0px) + 30px) * -1))';
        window.promptTimeout = setTimeout(() => {
            prompt.style.transform = 'translateY(100%)';
        }, duration);
    }, 100);
}

// Function to handle add whitelist/blacklist
async function handleAdd(fileType) {
    const inputElement = document.getElementById(`${fileType}-input`);
    const inputValue = inputElement.value.trim();
    console.log(`Input value for ${fileType}: "${inputValue}"`);
    if (inputValue === "") {
        console.error("Input is empty. Skipping add operation.");
        return;
    }
    if (fileType === "whitelist") {
        performAction(`--whitelist add ${inputValue}`);
        inputElement.value = "";
        return;
    }
    const result = await exec(`sh /data/adb/modules/Re-Malwack/rmlwk.sh --${fileType} add ${inputValue}`);
    if (result.errno === 0) {
        showPrompt(`${fileType}ed ${inputValue} successfully.`, true);
        inputElement.value = "";
        await loadFile(fileType);
        await getStatus();
    } else {
        console.error(`Error adding ${fileType} "${inputValue}":`, result.stderr);
        showPrompt(`Failed to add ${fileType} ${inputValue}`, false);
    }
}

// Prevent input box blocked by keyboard
const inputs = document.querySelectorAll('input');
const focusClass = 'input-focused';
inputs.forEach(input => {
    input.addEventListener('focus', event => {
        document.body.classList.add(focusClass);
        setTimeout(() => {
            const offsetAdjustment = window.innerHeight * 0.1;
            const targetPosition = event.target.getBoundingClientRect().top + window.scrollY;
            const adjustedPosition = targetPosition - (window.innerHeight / 2) + offsetAdjustment;
            window.scrollTo({
                top: adjustedPosition,
                behavior: 'smooth',
            });
        }, 100);
    });
    input.addEventListener('blur', () => {
        document.body.classList.remove(focusClass);
    });
});

/**
 * Simulate MD3 ripple animation
 * Usage: class="ripple-element" style="position: relative; overflow: hidden;"
 * Note: Require background-color to work properly
 * @return {void}
 */
function applyRippleEffect() {
    document.querySelectorAll('.ripple-element, .reboot').forEach(element => {
        if (element.dataset.rippleListener !== "true") {
            element.addEventListener("pointerdown", async (event) => {
                // Pointer up event
                const handlePointerUp = () => {
                    ripple.classList.add("end");
                    setTimeout(() => {
                        ripple.classList.remove("end");
                        ripple.remove();
                    }, duration * 1000);
                    element.removeEventListener("pointerup", handlePointerUp);
                    element.removeEventListener("pointercancel", handlePointerUp);
                };
                element.addEventListener("pointerup", () => setTimeout(handlePointerUp, 80));
                element.addEventListener("pointercancel", () => setTimeout(handlePointerUp, 80));

                const ripple = document.createElement("span");
                ripple.classList.add("ripple");

                // Calculate ripple size and position
                const rect = element.getBoundingClientRect();
                const width = rect.width;
                const size = Math.max(rect.width, rect.height);
                const x = event.clientX - rect.left - size / 2;
                const y = event.clientY - rect.top - size / 2;

                // Determine animation duration
                let duration = 0.2 + (width / 800) * 0.4;
                duration = Math.min(0.8, Math.max(0.2, duration));

                // Set ripple styles
                ripple.style.width = ripple.style.height = `${size}px`;
                ripple.style.left = `${x}px`;
                ripple.style.top = `${y}px`;
                ripple.style.animationDuration = `${duration}s`;
                ripple.style.transition = `opacity ${duration}s ease`;

                // Get effective background color (traverse up if transparent)
                const getEffectiveBackgroundColor = (el) => {
                    while (el && el !== document.documentElement) {
                        const bg = window.getComputedStyle(el).backgroundColor;
                        if (bg && bg !== "rgba(0, 0, 0, 0)" && bg !== "transparent") {
                            return bg;
                        }
                        el = el.parentElement;
                    }
                    return "rgba(255, 255, 255, 1)";
                };

                const bgColor = getEffectiveBackgroundColor(element);
                const isDarkColor = (color) => {
                    const rgb = color.match(/\d+/g);
                    if (!rgb) return false;
                    const [r, g, b] = rgb.map(Number);
                    return (r * 0.299 + g * 0.587 + b * 0.114) < 96; // Luma formula
                };
                ripple.style.backgroundColor = isDarkColor(bgColor) ? "rgba(255, 255, 255, 0.2)" : "rgba(0, 0, 0, 0.2)";

                // Append ripple animation
                await new Promise(resolve => setTimeout(resolve, 80));
                if (isScrolling || modeActive) return;
                element.appendChild(ripple);
            });
            element.dataset.rippleListener = "true";
        }
    });
}

// Link redirect with am start
function linkRedirect(url) {
    toast("Redirecting to " + url);
    setTimeout(() => {
        exec(`am start -a android.intent.action.VIEW -d ${url}`, { env: { PATH: '/system/bin' }})
            .then(({ errno }) => {
                if (errno !== 0) toast("Failed to open link");
            });
    },100);
}

// Function to read a file and display its content in the UI
async function loadFile(fileType) {
    try {
        const response = await fetch('link/persistent_dir/' + filePaths[fileType]);
        if (!response.ok) console.log(`File ${filePaths[fileType]} not found`);
        const content = await response.text();
        const lines = content
            .split("\n")
            .map(line => line.trim())
            .filter(line => line && !line.startsWith("#"));
        const listElement = document.getElementById(`${fileType}-list`);
        listElement.innerHTML = "";
        lines.forEach(line => {
            const listItem = document.createElement("li");
            listItem.innerHTML = `
                <span>${line}</span>
                <button class="delete-btn ripple-element">
                    <svg xmlns="http://www.w3.org/2000/svg" height="20px" viewBox="0 -960 960 960" width="20px" fill="#FFFFFF"><path d="M312-144q-29.7 0-50.85-21.15Q240-186.3 240-216v-480h-48v-72h192v-48h192v48h192v72h-48v479.57Q720-186 698.85-165T648-144H312Zm72-144h72v-336h-72v336Zm120 0h72v-336h-72v336Z"/></svg>
                </button>
            `;
            listElement.appendChild(listItem);
            listItem.addEventListener('click', () => {
                listItem.scrollTo({ left: listItem.scrollWidth, behavior: 'smooth' });
            });
            listItem.querySelector(".delete-btn").addEventListener("click", () => removeLine(fileType, line));
        });
        applyRippleEffect();
    } catch (error) {
        console.error(`Failed to load ${fileType} file:`, error);
        throw error;
    }
}

// Function to remove a line from whitelist/blacklist/custom-source
async function removeLine(fileType, line) {
    const result = await exec(`sh /data/adb/modules/Re-Malwack/rmlwk.sh --${fileType} remove ${line}`);
    if (result.errno === 0) {
        showPrompt(`Removed ${line} from ${fileType}`, true);
        await loadFile(fileType);
        await getStatus();
    } else {
        console.error(`Failed to remove line from ${fileType}:`, result.stderr);
        showPrompt(`Failed to remove ${line} from ${fileType}`, false);
    }
}

// Function to link file
async function linkFile() {
    const result = await exec(`
        mkdir -p ${modulePath}/webroot/link
        [ -L ${modulePath} ] || ln -s ${basePath} ${modulePath}/webroot/link/persistent_dir`
    );
    if (result.errno !== 0) {
        console.error(`Failed to remove link persistent directory to webroot:`, result.stderr);
    }
}

/**
 * Setup the Rick Roll overlay to appear on April 1st
 * Consecutive trigger protection for user experience.
 * Clicking on understood button will redirect to rick roll
 * Double click on blank space to exit early
 * @returns {void} 
 */
function setupPrank() { 
    const today = new Date();
    if (today.getMonth() !== 3 || today.getDate() !== 1) return;

    const warningOverlay = document.getElementById('security-warning');
    const closeButton = document.getElementById('understood');
    const lastPrank = localStorage.getItem('lastPrank');

    // Make sure this won't be triggered in a row for user experience
    if (lastPrank !== '1') {
        openOverlay();
        // Set flag in localStorage to prevent it from happening next time
        localStorage.setItem('lastPrank', '1');
    }

    closeButton.addEventListener('click', () => redirectRr());
    warningOverlay.addEventListener('dblclick', (e) => {
        if (e.target === warningOverlay) closeOverlay();
    });

    const redirectRr = () => {
        closeOverlay(); 
        linkRedirect('https://youtu.be/dQw4w9WgXcQ');
    }

    function openOverlay() {
        document.body.style.overflow = 'hidden';
        warningOverlay.style.display = 'flex';
        setTimeout(() => warningOverlay.style.opacity = '1', 10);
    }

    function closeOverlay() {
        document.body.style.overflow = 'auto';
        warningOverlay.style.opacity = '0';
        setTimeout(() => warningOverlay.style.display = 'none', 200);
    }
}

/**
 * Setup WebUI color theme
 * localStorage: remalwack_theme - light, dark
 * @return {void}
 */
function setupTheme() {
    const savedTheme = localStorage.getItem('remalwack_theme');
    const themeSelect = document.getElementById('theme-select');

    if (savedTheme === 'light') {
        applyTheme('light');
        themeSelect.value = 'light';
    } else if (savedTheme === 'dark') {
        applyTheme('dark');
        themeSelect.value = 'dark';
    } else {
        applyTheme('system');
        themeSelect.value = 'system';
    }

    // theme switcher
    themeSelect.addEventListener('change', () => {
        if (themeSelect.value === 'system') {
            localStorage.removeItem('remalwack_theme');
        } else {
            localStorage.setItem('remalwack_theme', themeSelect.value);
        }
        applyTheme(themeSelect.value);
    });

    function applyTheme(theme) {
        if (theme === 'light') {
            document.documentElement.classList.remove('dark-theme');
        } else if (theme === 'dark') {
            document.documentElement.classList.add('dark-theme');
        } else {
            if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
                document.documentElement.classList.add('dark-theme');
            } else {
                document.documentElement.classList.remove('dark-theme');
            }
        }
    }
}

// update adblock swtich
function updateAdblockSwtich() {
    const play = document.getElementById('play-icon');
    const pause = document.getElementById('pause-icon');
    exec('grep "^adblock_switch=" "/data/adb/Re-Malwack/config.sh" | cut -d= -f2')
        .then(({ errno, stdout, stderr }) => {
            if (errno !== 0) {
                console.error(stderr);
                return;
            }
            play.style.display = stdout === '1' ? 'block' : 'none';
            pause.style.display = stdout === '0' ? 'block' : 'noen';
        });
}

// Scroll event
let lastScrollY = window.scrollY;
let isScrolling = false;
let scrollTimeout;
const scrollThreshold = 25;
const floatBtn = document.querySelector('.float-container');
window.addEventListener('scroll', () => {
    isScrolling = true;
    clearTimeout(scrollTimeout);
    scrollTimeout = setTimeout(() => {
        isScrolling = false;
    }, 200);

    // Hide remove button on scroll
    const box = document.querySelector('.box li');
    if (box) {
        document.querySelectorAll('.box li').forEach(li => {
            li.scrollTo({ left: 0, behavior: 'smooth' });
        });
    }
    if (window.scrollY > lastScrollY && window.scrollY > scrollThreshold) {
        floatBtn.classList.remove('show');
    } else if (window.scrollY < lastScrollY) {
        floatBtn.classList.add('show');
    }
    lastScrollY = window.scrollY;
});

function setupEventListener() {
    document.getElementById("about-button").addEventListener("click", aboutMenu);
    document.getElementById("update").addEventListener("click", updateHostsFile);
    document.getElementById("daily-update").addEventListener("click", toggleDailyUpdate);
    document.getElementById("reset").addEventListener("click", resetHostsFile);
    document.getElementById("export-logs").addEventListener("click", exportLogs);
    blockTypes.forEach(type => {
        document.getElementById(`block-${type.id}`).addEventListener("click", () => handleBlock(type));
    });

    // About page links
    links.forEach(link => {
        document.getElementById(link.element).addEventListener("click", async () => {
            linkRedirect(link.url);
        });
    });

    // Adblock switch
    document.getElementById('adblock-switch').addEventListener("click", () => {
        performAction('--adblock-switch');
    });

    // Add button
    document.getElementById("whitelist-input").addEventListener("keypress", (e) => {
        if (e.key === "Enter") handleAdd("whitelist");
    });
    document.getElementById("blacklist-input").addEventListener("keypress", (e) => {
        if (e.key === "Enter") handleAdd("blacklist");
    });
    document.getElementById("custom-source-input").addEventListener("keypress", (e) => {
        if (e.key === "Enter") handleAdd("custom-source");
    });
    document.getElementById("whitelist-add").addEventListener("click", () => handleAdd("whitelist"));
    document.getElementById("blacklist-add").addEventListener("click", () => handleAdd("blacklist"));
    document.getElementById("custom-source-add").addEventListener("click", () => handleAdd("custom-source"));
}

// Initial load
document.addEventListener('DOMContentLoaded', async () => {
    setupTheme();
    checkMMRL();
    setupPrank();
    setupEventListener();
    applyRippleEffect();
    getVersion();
    updateAdblockSwtich();
    floatBtn.classList.add('show');
    await checkBlockStatus();
    ["custom-source", "blacklist", "whitelist"].forEach(loadFile);
});
