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
    const result = await exec(`grep '^version=' ${modulePath}/module.prop | cut -d'=' -f2`);
    if (result.errno === 0) {
        const [version, ...hashParts] = result.stdout.trim().split('-');
        const hash = hashParts.join('-');

        document.getElementById('version-text').textContent = version || 'Unknown';        
        if (hash) {
            document.getElementById('test-version-box').style.display = 'flex';
            document.getElementById('test-version-text').textContent = `You're using a test release: ${hash}`;
        }

        getStatus();
    }
}

function checkMount() {
    exec(`system_hosts="$(cat /system/etc/hosts | wc -l)"
          module_hosts="$(cat ${modulePath}/system/etc/hosts | wc -l)"
          [ $system_hosts -eq $module_hosts ] || echo "error"
        `).then(({ stdout }) => {
            if (stdout === "error") document.getElementById('broken-mount-box').style.display = 'flex';
        });
}

// Function to check if running in MMRL
async function checkMMRL() {
    if (typeof $Re_Malwack !== 'undefined' && Object.keys($Re_Malwack).length > 0) {
        // Set status bars theme based on device theme
        try {
            $Re_Malwack.setLightStatusBars(!window.matchMedia('(prefers-color-scheme: dark)').matches)
        } catch (error) {
            console.error("Error setting status bars theme:", error)
        }
    }
}

async function isPaused() {
    const result = await exec(`[ -f "${basePath}/hosts.bak" ] && grep -q "^adblock_switch=1" "${basePath}/config.sh"`);
    return result.errno === 0;
}

// Function to get working status
async function getStatus() {
    const statusElement = document.getElementById('status-text');
    const disableBox = document.querySelector('.header-disabled');
    const disableText = document.getElementById('disable-text');
    const result = await exec("cat /data/adb/Re-Malwack/counts/blocked_mod.count");
    if (result.errno === 0) {
        let status = result.stdout.trim();
        if (parseInt(status) === 0) {
            const pause = await isPaused();
            disableText.textContent = pause ? "Protection is paused" : "Protection is disabled due to reset";
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
    } else {
        console.error("Error getting status:", result.stderr);
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

    const last = await exec(`date -r '${modulePath}/system/etc/hosts' '+%H %d/%m/%Y'`);
    const now = await exec("date +'%H %d/%m/%Y'");
    if (last.errno === 0 || now.errno === 0) {
        const [lastHour, lastDay, lastMonth, lastYear] = last.stdout.trim().split(/[ /]/);
        const [nowHour, nowDay, nowMonth, nowYear] = now.stdout.trim().split(/[ /]/);

        // Convert to Date objects for accurate comparison
        const lastDate = new Date(lastYear, parseInt(lastMonth) - 1, parseInt(lastDay), parseInt(lastHour));
        const nowDate = new Date(nowYear, parseInt(nowMonth) - 1, parseInt(nowDay), parseInt(nowHour));

        const diffMs = nowDate - lastDate;
        const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
        const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

        if (diffDays === 0) {
            if (diffHours === 0) {
                lastUpdatedElement.textContent = 'Just Now';
            } else {
                lastUpdatedElement.textContent = `${diffHours}h ago`;
            }
        } else if (diffDays === 1) {
            lastUpdatedElement.textContent = 'Yesterday';
        } else {
            lastUpdatedElement.textContent = `${diffDays}d ago`;
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
        const customBlock = document.querySelector('.custom-block');
        customBlock.querySelectorAll('.toggle-container').forEach(container => {
            const toggle = container.querySelector('input[type="checkbox"]');
            const blockLine = lines.find(line => line.trim().startsWith(`block_${container.dataset.type}=`));
            if (blockLine) {
                const value = blockLine.split('=')[1].trim();
                toggle.checked = value === '1';
            } else {
                toggle.checked = false;
            }
        });

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
            const success = await linkFile();
            if (success) await checkBlockStatus();
        }
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
    const output = spawn('sh', [`${modulePath}/rmlwk.sh`, `${commandOption}`], { env: { MAGISKTMP: 'true', WEBUI: 'true' }});
    output.stdout.on('data', (data) => {
        const newline = document.createElement('p');
        newline.className = 'output-line';
        newline.textContent = data;
        terminalContent.appendChild(newline);
        terminalContent.scrollTo({ top: terminalContent.scrollHeight, behavior: 'smooth' });
    });
    output.stderr.on('data', (data) => {
        const newline = document.createElement('p');
        newline.className = 'output-line';
        newline.textContent = data;
        newline.style.color = 'red';
        terminalContent.appendChild(newline);
        terminalContent.scrollTo({ top: terminalContent.scrollHeight, behavior: 'smooth' });
    });
    output.on('exit', () => {
        isShellRunning = false;
        closeBtn.classList.add('show');
        getStatus();
        checkBlockStatus();
        updateAdblockSwtich();
    });
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
    const result = await exec(`sh ${modulePath}/rmlwk.sh --auto-update ${isEnabled ? "disable" : "enable"}`, { env: { WEBUI: 'true' } });
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
function setupCustomBlock() {
    const customBlock = document.querySelector('.custom-block');
    customBlock.querySelectorAll('.toggle-container').forEach(container => {
        const toggle = container.querySelector('input[type="checkbox"]');
        const type = container.dataset.type;

        container.addEventListener('click', () => {
            const action = toggle.checked ? `--block-${type} 0` : `--block-${type}`;
            performAction(action);
        });
    });
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
function handleAdd(fileType) {
    const box = document.getElementById(fileType);
    const inputElement = document.getElementById(`${fileType}-input`);
    const inputValue = inputElement.value.trim();
    const loading = box.querySelector('.loading');
    const output = [];

    if (inputValue === "" || (loading && loading.classList.contains('show'))) return;
    console.log(`Input value for ${fileType}: "${inputValue}"`);

    if (fileType === "whitelist") {
        performAction(`--whitelist add ${inputValue}`);
        inputElement.value = "";
        return;
    }

    loading.classList.add('show');

    const result = spawn('sh', [`${modulePath}/rmlwk.sh`, `--${fileType}`, 'add', `${inputValue}`], { env: { WEBUI: 'true' }});
    result.stdout.on('data', (data) => output.push(data));
    result.on('exit', async (code) => {
        loading.classList.remove('show');
        showPrompt(output[output.length - 1].trim(), code === 0);
        if (code === 0) inputElement.value = "";
        await loadFile(fileType);
        await getStatus();
    });
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

// Function to setup listener control button
function setupControlListListeners(listElement) {
    const controlList = listElement.previousElementSibling;
    if (!controlList || !controlList.classList.contains('control-list')) return;

    const backBtn = controlList.querySelector('.back');
    const selectAllBtn = controlList.querySelector('.select-all');
    const deleteBtn = controlList.querySelector('.delete');
    const fileType = listElement.id.replace('-list', '');

    if (listElement.controlListeners) {
        listElement.controlListeners.abort();
    }
    const controller = new AbortController();
    listElement.controlListeners = controller;

    const hideControls = () => {
        controlList.classList.remove('show');
        const checkboxes = listElement.querySelectorAll('.checkbox-wrapper');
        checkboxes.forEach(cb => {
            cb.classList.remove('show');
            const input = cb.querySelector('.checkbox');
            if (input) {
                input.checked = false;
            }
        });
        controller.abort();
    };

    const backAction = () => hideControls();

    const selectAllAction = () => {
        const checkboxes = listElement.querySelectorAll('.checkbox-wrapper .checkbox');
        const allSelected = checkboxes.length > 0 && Array.from(checkboxes).every(cb => cb.checked);
        checkboxes.forEach(cb => {
            cb.checked = !allSelected;
        });
    };

    const deleteAction = () => {
        const checkedItems = listElement.querySelectorAll('.checkbox-wrapper .checkbox:checked');
        if (checkedItems.length === 0) return;

        const lines = Array.from(checkedItems).map(item => item.closest('li').querySelector('span').textContent);
        removeLine(fileType, lines);

        hideControls();
    };

    backBtn.addEventListener('click', backAction, { signal: controller.signal });
    selectAllBtn.addEventListener('click', selectAllAction, { signal: controller.signal });
    deleteBtn.addEventListener('click', deleteAction, { signal: controller.signal });
}

// Function to read a file and display its content in the UI
async function loadFile(fileType) {
    try {
        const response = await fetch('link/persistent_dir/' + filePaths[fileType]);
        if (!response.ok) throw new Error('File not found');
        const content = await response.text();
        const lines = content
            .split("\n")
            .map(line => line.trim())
            .filter(line => line && !line.startsWith("#"));
        const listElement = document.getElementById(`${fileType}-list`);
        listElement.innerHTML = "";
        lines.forEach((line, index) => {
            const listItem = document.createElement("li");
            const checkboxId = `${fileType}-checkbox-${index}`;
            listItem.innerHTML = `
                <span>${line}</span>
                <div class="checkbox-wrapper">
                    <input type="checkbox" class="checkbox" id="${checkboxId}" disabled />
                    <label for="${checkboxId}" class="custom-checkbox">
                        <span class="tick-symbol">
                            <svg xmlns="http://www.w3.org/2000/svg"  viewBox="0 -3 26 26" width="16px" height="16px" fill="#fff"><path d="M 22.566406 4.730469 L 20.773438 3.511719 C 20.277344 3.175781 19.597656 3.304688 19.265625 3.796875 L 10.476563 16.757813 L 6.4375 12.71875 C 6.015625 12.296875 5.328125 12.296875 4.90625 12.71875 L 3.371094 14.253906 C 2.949219 14.675781 2.949219 15.363281 3.371094 15.789063 L 9.582031 22 C 9.929688 22.347656 10.476563 22.613281 10.96875 22.613281 C 11.460938 22.613281 11.957031 22.304688 12.277344 21.839844 L 22.855469 6.234375 C 23.191406 5.742188 23.0625 5.066406 22.566406 4.730469 Z"/></svg>
                        </span>
                    </label>
                </div>
            `;

            let pressTimer;
            let isLongPress = false;

            const startPress = (e) => {
                if (e.button && e.button !== 0) return;
                isLongPress = false;
                pressTimer = window.setTimeout(() => {
                    isLongPress = true;
                    const list = listItem.closest('ul');
                    if (list) {
                        const controlList = list.previousElementSibling;
                        const checkboxes = list.querySelectorAll('.checkbox-wrapper');
                        checkboxes.forEach(cb => {
                            cb.classList.add('show');
                        });
                        if (controlList) controlList.classList.add('show');
                        setupControlListListeners(list);
                        const checkbox = listItem.querySelector('.checkbox');
                        if (checkbox) {
                            checkbox.checked = true;
                        }
                    }
                }, 500);
            };

            const cancelPress = () => clearTimeout(pressTimer);
            const clickHandler = (e) => {
                if (isLongPress) {
                    e.preventDefault();
                    e.stopPropagation();
                }
            };

            listItem.addEventListener('click', () => {
                if (!listItem.querySelector('.checkbox-wrapper').classList.contains('show')) return;
                const checkbox = listItem.querySelector('.checkbox');
                checkbox.checked = !checkbox.checked;
            });
            listItem.addEventListener('mousedown', startPress);
            listItem.addEventListener('mouseup', cancelPress);
            listItem.addEventListener('mouseleave', cancelPress);
            listItem.addEventListener('touchstart', startPress);
            listItem.addEventListener('touchend', cancelPress);
            listItem.addEventListener('click', clickHandler, true);
            listElement.appendChild(listItem);
        });
        applyRippleEffect();
    } catch (error) {
        console.log(`File ${filePaths[fileType]} not found`);
    }
}

// Function to remove a line from whitelist/blacklist/custom-source
function removeLine(fileType, lines) {
    const line = lines.join(' ');
    showPrompt(`Removing ${line}`, false);
    const result = spawn(`sh ${modulePath}/rmlwk.sh --${fileType} remove ${line}`);
    result.on('exit', (code) => {
        if (code === 0) {
            showPrompt(`Removed ${line} from ${fileType}`, true);
        } else {
            console.error(`Failed to remove line from ${fileType}:`, result.stderr);
            showPrompt(`Failed to remove ${line} from ${fileType}`, false);
        }
        loadFile(fileType);
        getStatus();
    });
}

// Function to link file
async function linkFile() {
    const result = await exec(`
        mkdir -p ${modulePath}/webroot/link
        [ -L ${modulePath} ] || ln -s ${basePath} ${modulePath}/webroot/link/persistent_dir
    `);
    if (result.errno !== 0) {
        console.error(`Failed to remove link persistent directory to webroot:`, result.stderr);
    }
    return result.errno === 0;
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
async function updateAdblockSwtich() {
    const play = document.getElementById('play-icon');
    const pause = document.getElementById('pause-icon');
    const protection = await isPaused();
    play.style.display = protection ? 'block' : 'none';
    pause.style.display = !protection ? 'block' : 'none';
}

function initCredit() {
    const credit = document.querySelector('.credit-list');
    fetch('contributors.json')
        .then(response => response.json())
        .then(data => {
            data.forEach(contributor => {
                const creditBox = document.createElement('div');
                creditBox.className = 'credit-box';
                creditBox.classList.add('ripple-element');
                creditBox.innerHTML = `
                    <img src="https://github.com/${contributor.username}.png" alt="${contributor.username}">
                    <h3>${contributor.username}</h3>
                    <h4>${contributor.type}</h4>
                    <p>${contributor.description}</p>
                `;
                credit.appendChild(creditBox);
                creditBox.addEventListener('click', () => {
                    linkRedirect(`https://github.com/${contributor.username}`);
                });
            });
            applyRippleEffect();
        })
        .catch(error => {
            console.error('Error loading contributors:', error);
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

document.querySelector('.credit').addEventListener('scroll', () => {
    isScrolling = true;
    clearTimeout(scrollTimeout);
    scrollTimeout = setTimeout(() => {
        isScrolling = false;
    }, 200);
});

function setupEventListener() {
    document.getElementById("about-button").addEventListener("click", aboutMenu);
    document.getElementById("update").addEventListener("click", () => performAction("--update-hosts"));
    document.getElementById("daily-update").addEventListener("click", toggleDailyUpdate);
    document.getElementById("reset").addEventListener("click", resetHostsFile);
    document.getElementById("export-logs").addEventListener("click", exportLogs);

    // Custom block toggle listeners
    setupCustomBlock();

    // About page links
    links.forEach(link => {
        document.getElementById(link.element).addEventListener("click", () => {
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
    checkMount();
    updateAdblockSwtich();
    initCredit();
    floatBtn.classList.add('show');
    await checkBlockStatus();
    ["custom-source", "blacklist", "whitelist"].forEach(loadFile);
});
