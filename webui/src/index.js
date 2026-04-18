import { spawn, exec, toast, getPackagesInfo } from 'kernelsu-alt';
import '@material/web/all.js';
import ReMalwareIcon from './assets/Re-Malware.svg?raw';

const basePath = "/data/adb/Re-Malwack";
const modulePath = "/data/adb/modules/Re-Malwack";
const CONFIG_PATH = `${basePath}/config.sh`;

const filePaths = {
    blacklist: 'blacklist.txt',
    whitelist: 'whitelist.txt',
    "custom-source": 'sources.txt',
    "custom-rule": 'custom_rules.txt',
};

const festivals = [
    {
        id: 'christmas',
        start: { month: 12, day: 1 }, // December 1
        end: { month: 12, day: 31 }   // December 31
    }
    // {
    //     id: 'halloween',
    //     start: { month: 9, day: 25 }, // October 25
    //     end: { month: 9, day: 31 }   // October 31
    // }
];

let isShellRunning = false;

// Link redirect
const links = [
    { element: 'telegram', url: 'https://t.me/Re_Malwack' },
    { element: 'github', url: 'https://github.com/ZG089/Re-Malwack' },
    { element: 'xda', url: 'https://xdaforums.com/t/re-malwack-revival-of-malwack-module.4690049/' },
    { element: 'sponsor', url: 'https://buymeacoffee.com/zg089' }
];

let initAboutMenu = false;
// Function to handle about menu
function aboutMenu() {
    const aboutOverlay = document.getElementById('about-dialog');
    if (!initAboutMenu) {
        initCredit();
        initAboutMenu = true;
    }
    aboutOverlay.show();
}

// Get module version from module.prop
async function getVersion() {
    const versionMain = document.getElementById('version-text');
    const versionBox = document.getElementById('test-version-box');
    const versionText = document.getElementById('test-version-text');

    let displayHash = "";

    const result = await exec(`grep '^version=' "${modulePath}/module.prop" | cut -d'=' -f2`);
    if (result.errno === 0) {
        const rawVersion = result.stdout.trim();
        const testMatch = rawVersion.match(/^(.*?)-test \((.*?)\)$/);

        if (testMatch) {
            versionMain.textContent = testMatch[1];
            displayHash = testMatch[2] || '';
        } else {
            versionMain.textContent = rawVersion || 'Unknown';
            return;
        }
    } else if (import.meta.env.DEV) {
        versionMain.textContent = "DEV";
        displayHash = "DEVELOPMENT STAGE";
    }
    versionText.textContent = `You're using a test release: ${displayHash}`;
    versionBox.classList.add('display-flex');
}

async function isZnhr() {
    try {
        const { errno } = await exec(`
            znhr="/data/adb/modules/hostsredirect"
            [ -f "$znhr/module.prop" ] && [ ! -f "$znhr/disable" ]
        `);
        return errno === 0;
    } catch {
        return false;
    }
}

async function checkMount() {
    const result = await exec(`
        system_hosts="$(cat /system/etc/hosts | wc -l)"
        module_hosts="$(cat ${modulePath}/system/etc/hosts | wc -l)"
        [ $system_hosts -eq $module_hosts ] || echo "error"
    `);
    if (result.stdout.trim().includes("error") && !await isZnhr() || import.meta.env.DEV) {
        document.getElementById('broken-mount-box').classList.add('display-flex');
    }
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
    const result = await exec(`[ -f "${basePath}/hosts.bak" ] && grep -q "^adblock_switch=1" "${CONFIG_PATH}"`);
    return result.errno === 0;
}

function formatNumber(numStr, isApril1st = false, includeLabel = false) {
    let num = parseInt(numStr, 10);
    if (isNaN(num)) return numStr;

    let formattedNum = num.toString();
    if (num > 999999) {
        formattedNum = (num / 1000000).toFixed(1) + 'M';
    } else if (num > 9999) {
        formattedNum = (num / 1000).toFixed(1) + 'K';
    }

    if (!includeLabel) return formattedNum;

    const label = isApril1st ? "Allowed Ads" : "Blocked entries";
    return `${formattedNum} ${label}`;
}

// Function to get working status
async function getStatus() {
    const statusElement = document.getElementById('status-text');
    const disableBox = document.getElementById('disabled-box');
    const disableText = document.getElementById('disable-text');
    const result = await exec("cat /data/adb/Re-Malwack/counts/blocked_mod.count");

    // Check if it's april 1st
    const now = new Date();
    const isApril1st = (now.getMonth() === 3 && now.getDate() === 1);

    const statusTitleElement = document.getElementById('status-title');
    if (statusTitleElement) {
        statusTitleElement.textContent = isApril1st ? "Allowed Ads" : "Blocked Entries";
    }

    if (result.errno === 0) {
        let status = result.stdout.trim();
        if (parseInt(status) === 0) {
            const pause = await isPaused();
            disableText.textContent = pause ? "Protection is paused" : "Protection is disabled due to reset";
            disableBox.classList.add('display-flex');
            statusElement.textContent = '-';
            getlastUpdated(false);
            return;
        }
        statusElement.textContent = formatNumber(status, isApril1st, false);
        disableBox.classList.remove('display-flex');
    } else if (import.meta.env.DEV) {
        statusElement.textContent = formatNumber(10, isApril1st, false);
        disableBox.classList.add('display-flex');
        disableText.textContent = "Protection is under development";
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

    const hostsFile = await isZnhr() ? `/data/adb/hostsredirect/hosts` : `${modulePath}/system/etc/hosts`;
    const last = await exec(`date -r '${hostsFile}' '+%H %d/%m/%Y'`);
    const now = await exec("date +'%H %d/%m/%Y'");
    if (import.meta.env.DEV) {
        last.stdout = "12 5/12/2026";
        now.stdout = "12 12/12/2026";
    }
    if (last.stdout.trim() !== '' && now.stdout.trim() !== '') {
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


// ===== Action Mode =====

let actionMode = 0; // default to load properly

function getStatusText() {
    return actionMode === 1 ? "Pause & Resume" : "Update Hosts";
}

function updateActionModeLabel() {
    const label = document.getElementById("action-mode-status");
    label.classList.toggle("pause", actionMode === 1);
    label.classList.toggle("update", actionMode === 0);
    label.textContent = getStatusText();
}

function loadActionMode() {
    exec(`grep '^action_mode=' ${CONFIG_PATH} | cut -d'=' -f2 || echo '0'`).then((result) => {
        if (result.errno === 0) {
            actionMode = parseInt(result.stdout, 10) === 0 ? 0 : 1;
            updateActionModeLabel();
        } else if (import.meta.env.DEV) {
            actionMode = 0;
            updateActionModeLabel();
        }
    });
}

function updateActionMode(mode) {
    exec(`sed -i 's/^action_mode=.*/action_mode=${mode}/' ${CONFIG_PATH}`).then((result) => {
        if (result.errno === 0 || import.meta.env.DEV) {
            actionMode = mode;
            updateActionModeLabel();
            showPrompt(`Action Mode set to ${getStatusText()}`, true, 2000);
        } else {
            showPrompt("Failed to change Action Mode", false, 2000);
        }
    });
}

// Function to check block status for different site categories
async function checkBlockStatus() {
    try {
        const result = await fetch('link/persistent_dir/config.sh').then(response => {
            if (!response.ok) throw new Error('Config file not found');
            return response.text();
        });
        const lines = result.split("\n");

        let blocklistCounts = {};
        try {
            const countsResult = await fetch('link/persistent_dir/counts/blocklists.counts').then(res => res.text());
            countsResult.split('\n').forEach(line => {
                const parts = line.split('|');
                if (parts.length === 2) {
                    blocklistCounts[parts[0].trim()] = parts[1].trim();
                }
            });
        } catch (e) {
            // ignore if counts file is not found
        }

        // Check each block type
        const now = new Date();
        const isApril1st = (now.getMonth() === 3 && now.getDate() === 1);
        const customBlock = document.querySelector('.custom-block');
        customBlock.querySelectorAll('.list-item').forEach(container => {
            const type = container.dataset.type;
            const toggle = container.querySelector('md-switch');
            const badge = document.getElementById(`badge-${type}`);
            const blockLine = lines.find(line => line.trim().startsWith(`block_${type}=`));

            let isEnabled = false;
            if (blockLine) {
                isEnabled = blockLine.split('=')[1].trim() === '1';
            }
            toggle.selected = isEnabled;

            if (badge) {
                const enabled = isEnabled && blocklistCounts[type] !== undefined;
                badge.textContent = formatNumber(blocklistCounts[type] || 0, isApril1st, true);
                badge.classList.toggle('display-flex', enabled);
            }
        });

        // Check daily update status
        const dailyUpdateToggle = document.getElementById('daily-update-toggle');
        const dailyUpdateLine = lines.find(line => line.trim().startsWith('daily_update='));
        if (dailyUpdateLine) {
            const value = dailyUpdateLine.split('=')[1].trim();
            dailyUpdateToggle.selected = value === '1';
        } else {
            dailyUpdateToggle.selected = false;
        }

        // Check DNS logging status
        const dnsLoggingToggle = document.getElementById('dns-logging-toggle');
        const dnsLoggingLine = lines.find(line => line.trim().startsWith('dns_logging='));
        if (dnsLoggingLine) {
            const value = dnsLoggingLine.split('=')[1].trim();
            dnsLoggingToggle.selected = value === '1';
        } else {
            dnsLoggingToggle.selected = false;
        }
    } catch (error) {
        if (error.message === 'Config file not found') {
            const success = await linkFile();
            if (success) await checkBlockStatus();
        }
    }
}

/**
 * Run rmlwk command and show stdout in terminal
 * @param {string} commandOption - rmlwk --option
 * @param {boolean} showTerminal - show terminal
 * @returns {Promise<boolean>} - true if the command was successful
 */
function performAction(commandOption, showTerminal = true) {
    const terminal = document.querySelector('.terminal');
    const terminalContent = document.getElementById('terminal-output-text');
    const backBtn = document.getElementById('aciton-back-btn');
    const closeBtn = document.querySelector('.close-terminal');
    const loadingOverlay = document.getElementById('loading-overlay');

    const closeTerminal = () => {
        document.body.classList.remove('noscroll');
        terminal.classList.remove('show');
        terminalContent.innerHTML = "";
        closeBtn.classList.remove('show');
    }

    const appendOutput = (data, isError = false) => {
        if (!showTerminal) return;
        const newline = document.createElement('p');
        newline.className = 'output-line';
        if (isError) newline.classList.add('error');
        newline.textContent = data;
        terminalContent.appendChild(newline);
        terminalContent.scrollTo({ top: terminalContent.scrollHeight, behavior: 'smooth' });
    }

    if (showTerminal) {
        terminal.classList.add('show');
        document.body.classList.add('noscroll');
        backBtn.onclick = () => closeTerminal();
        closeBtn.onclick = () => closeTerminal();
    } else {
        loadingOverlay.classList.add('show');
    }

    if (isShellRunning) return;

    isShellRunning = true;
    return new Promise((resolve) => {
        const output = spawn('sh', [`${modulePath}/rmlwk.sh`, `${commandOption}`], { env: { MAGISKTMP: 'true', WEBUI: 'true' } });
        output.stdout.on('data', (data) => appendOutput(data));
        output.stderr.on('data', (data) => appendOutput(data, true));
        output.on('exit', (code) => {
            isShellRunning = false;
            if (showTerminal) {
                closeBtn.classList.add('show');
            } else {
                loadingOverlay.classList.remove('show');
            }
            getStatus();
            checkBlockStatus();
            updateAdblockSwtich();
            resolve(code === 0);
        });
    });
}

let setupResetDialogListener = false;

// Function to reset hosts
async function resetHostsFile() {
    const resetDialog = document.getElementById("confirmation-dialog");
    const cancelButton = document.getElementById("cancel-reset");
    const resetButton = document.getElementById("confirm-reset");

    resetDialog.show();

    if (!setupResetDialogListener) {
        cancelButton.onclick = () => resetDialog.close();
        resetButton.onclick = () => {
            resetDialog.close();
            performAction("--reset");
        }
        setupResetDialogListener = true;
    }
}

// Function to enable/disable daily update
async function toggleDailyUpdate() {
    const toggle = document.getElementById('daily-update-toggle');
    const action = toggle.selected ? "enable" : "disable";

    const result = await performAction(`--auto-update ${action}`, false);
    if (result) {
        showPrompt(`Daily update ${action}d`, true);
    } else {
        showPrompt(`Failed to toggle daily update`, false);
    }
}

// Function to enable/disable DNS logging
async function toggleDnsLogging() {
    const toggle = document.getElementById('dns-logging-toggle');
    const action = toggle.selected ? "enable" : "disable";

    const result = await performAction(`--dns-logging ${action}`, false);
    if (result) {
        await checkRebootRequired();
        showPrompt(
            toggle.selected ? "DNS Logging enabled, Reboot to apply changes." : "DNS Logging disabled, Reboot to apply changes.",
            true,
            5000,
            () => { exec("reboot"); },
            "Reboot"
        );
    } else {
        showPrompt("Failed to toggle DNS logging", false);
    }
}

// Function to export logs
async function exportLogs() {
    const result = await exec(`sh ${modulePath}/rmlwk.sh --export-logs --quiet`);
    if (result.errno === 0) {
        showPrompt(result.stdout.trim(), true, 3000);
    } else {
        console.error("Error exporting logs:", result.stderr);
        showPrompt("Failed to export logs", false);
    }
}


// Function to handle blocking/unblocking different site categories
function setupCustomBlock() {
    const customBlock = document.querySelector('.custom-block');
    customBlock.querySelectorAll('.list-item').forEach(container => {
        const toggle = container.querySelector('md-switch');
        const type = container.dataset.type;

        toggle.addEventListener('change', () => {
            const action = toggle.selected ? `--block-${type}` : `--block-${type} 0`;
            performAction(action);
        });
    });
}

// Function to show prompt
function showPrompt(message, isSuccess = true, duration = 2000, actionCallback = null, actionText = null) {
    const prompt = document.getElementById('prompt');
    prompt.textContent = message;
    
    if (actionCallback && actionText) {
        const btn = document.createElement('md-text-button');
        btn.textContent = actionText;
        btn.onclick = actionCallback;
        btn.style.marginLeft = "12px";
        btn.style.flexShrink = "0";
        prompt.style.display = "flex";
        prompt.style.justifyContent = "space-between";
        prompt.style.alignItems = "center";
        prompt.appendChild(btn);
    } else {
        prompt.style.display = "";
    }

    prompt.classList.toggle('error', !isSuccess);
    if (window.promptTimeout) {
        clearTimeout(window.promptTimeout);
    }
    setTimeout(() => {
        prompt.classList.add('show');
        window.promptTimeout = setTimeout(() => {
            prompt.classList.remove('show');
        }, duration);
    }, 10);
}

// Function to handle add whitelist/blacklist/custom-rules
function handleAdd(fileType) {
    if (fileType === "custom-rule") {
        const ipInput = document.getElementById('custom-rule-ip');
        const domInput = document.getElementById('custom-rule-domain');
        const ipValue = ipInput.value.trim();
        const domValue = domInput.value.trim();
        const addBtn = document.getElementById('custom-rule-add');

        if (ipValue === "" || domValue === "" || addBtn.disabled) return;

        addBtn.disabled = true;
        showPrompt(`Adding rule…`, true, 3000);
        const output = [];
        const result = spawn('sh', [`${modulePath}/rmlwk.sh`, '--custom-rule', 'add', ipValue, domValue]);
        result.stdout.on('data', (data) => output.push(data));
        result.on('exit', async (code) => {
            addBtn.disabled = false;
            const msg = output.length ? output[output.length - 1].trim() : (code === 0 ? "Success" : "Failed");
            showPrompt(msg, code === 0);
            if (code === 0) {
                ipInput.value = "";
                domInput.value = "";
            }
            await loadFile(fileType);
            await getStatus();
        });
        return;
    }

    const addBtn = document.getElementById(`${fileType}-add`);
    const inputElement = document.getElementById(`${fileType}-input`);
    const inputValue = inputElement.value.trim();
    const output = [];

    if (inputValue === "" || addBtn.disabled) return;
    console.log(`Input value for ${fileType}: "${inputValue}"`);

    addBtn.disabled = true;
    showPrompt(`Adding to ${fileType}…`, true, 3000);

    // Split inputValue by spaces for all fileTypes so that multiple items are passed as separate arguments
    const args = [];
    args.push(`${modulePath}/rmlwk.sh`, `--${fileType}`, 'add', ...inputValue.split(/\s+/));

    const result = spawn('sh', args);
    result.stdout.on('data', (data) => output.push(data));
    result.on('exit', async (code) => {
        addBtn.disabled = false;
        showPrompt(output[output.length - 1].trim(), code === 0);
        if (code === 0) inputElement.value = "";
        await loadFile(fileType);
        await getStatus();
    });
}

function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
        showPrompt("Copied to clipboard", true);
    }).catch(() => {
        showPrompt("Failed to copy to clipboard", false);
    });
}

// Function to handle query domain
function handleQuery() {
    const inputElement = document.getElementById('query-input');
    const resultCard = document.getElementById('query-result-card');
    const resultText = document.getElementById('query-result-text');
    const inputValue = inputElement.value.trim();

    if (inputValue === "") return;

    inputElement.value = "";
    resultText.textContent = "Querying...";
    resultCard.classList.add('display-block');

    const output = [];
    const result = spawn('sh', [`${modulePath}/rmlwk.sh`, `--query-domain`, `${inputValue}`, `--quiet`]);
    result.stdout.on('data', (data) => output.push(data));
    result.stderr.on('data', (data) => output.push(data));
    result.on('exit', () => {
        resultText.textContent = "";
        output.forEach(line => {
            const div = document.createElement('div');
            div.textContent = line;
            div.addEventListener('click', () => copyToClipboard(line));
            resultText.appendChild(div);
        })
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

// Link redirect with am start
function linkRedirect(url) {
    if (!/^[a-zA-Z]+:\/\//.test(url)) url = "https://" + url;
    toast("Redirecting to " + url);
    setTimeout(() => {
        exec(`am start -a android.intent.action.VIEW -d ${url}`)
            .then(({ errno }) => {
                if (errno !== 0) window.open(url, "_blank");
            });
    }, 100);
}

// Function to setup listener control button
function setupControlListListeners(listElement, fileType) {
    const controlList = listElement.previousElementSibling;
    if (!controlList || !controlList.classList.contains('control-list')) return;

    const backBtn = controlList.querySelector('.back');
    const selectAllBtn = controlList.querySelector('.select-all');
    const deleteBtn = controlList.querySelector('.delete');
    const enableBtn = controlList.querySelector('.enable');
    const disableBtn = controlList.querySelector('.disable');
    const checkboxes = listElement.querySelectorAll('md-checkbox');

    if (listElement.controlListeners) {
        listElement.controlListeners.abort();
    }
    const controller = new AbortController();
    listElement.controlListeners = controller;

    const hideControls = () => {
        controlList.classList.remove('show');
        checkboxes.forEach(cb => {
            cb.classList.remove('show');
            cb.checked = false;
        });
        controller.abort();
    };

    const backAction = () => hideControls();

    const selectAllAction = () => {
        const allSelected = checkboxes.length > 0 && Array.from(checkboxes).every(cb => cb.checked);
        checkboxes.forEach(cb => {
            if (cb.checked !== !allSelected) {
                cb.checked = !allSelected;
                cb.dispatchEvent(new Event('change', { bubbles: true }));
            }
        });
    };

    const editAction = (action) => {
        const checkedItems = Array.from(checkboxes).filter(cb => cb.checked);
        if (checkedItems.length === 0) return;

        const lines = Array.from(checkedItems).map(item => item.value);
        editLine(fileType, lines, action);

        hideControls();
    };

    backBtn.addEventListener('click', backAction, { signal: controller.signal });
    selectAllBtn.addEventListener('click', selectAllAction, { signal: controller.signal });
    deleteBtn.addEventListener('click', () => editAction("remove"), { signal: controller.signal });
    if (enableBtn) enableBtn.addEventListener('click', () => editAction("enable"), { signal: controller.signal });
    if (disableBtn) disableBtn.addEventListener('click', () => editAction("disable"), { signal: controller.signal });
}

// Function to read a file and display its content in the UI
async function loadFile(fileType) {
    try {
        const filePath = 'link/persistent_dir/' + filePaths[fileType];
        const response = await fetch(filePath);
        if (!response.ok) throw new Error(filePath + ' not found');
        const content = await response.text();
        const lines = content
            .split("\n")
            .map(line => line.trim())
            .filter(line => line);

        let sourceCounts = {};
        if (fileType === "custom-source") {
            try {
                const countResponse = await fetch('link/persistent_dir/counts/sources.counts');
                if (countResponse.ok) {
                    const countContent = await countResponse.text();
                    countContent.split("\n").forEach(line => {
                        const parts = line.split("|");
                        if (parts.length === 2) {
                            sourceCounts[parts[0].trim()] = parts[1].trim();
                        }
                    });
                }
            } catch (e) {
                console.log("No counts file found for sources.");
            }
        }

        let skipDivider = true;
        const now = new Date();
        const isApril1st = (now.getMonth() === 3 && now.getDate() === 1);
        const listElement = document.getElementById(`${fileType}-list`);
        listElement.innerHTML = "";

        // Function to create list items
        lines.forEach(line => {
            const rawLine = line;
            // Free favicon provided by GitHub@twentyhq/favicon
            const isDisabled = line.startsWith("# OFF # ");
            if (isDisabled) line = line.replace("# OFF # ", "");
            if (line.startsWith("#")) return;
            const item = line.split('#');
            const url = item[0].trim();
            const name = item.slice(1).join('#').trim();

            let domain = url.split(/\s+/).pop();
            try {
                if (!domain.startsWith("http")) domain = "http://" + domain;
                domain = new URL(domain).hostname;
            } catch {
                domain = domain.split(/[/:?#]/)[0];
            }
            const faviconUrl = `https://twenty-icons.com/${domain}`;

            const listItem = document.createElement("div");
            listItem.innerHTML = `
                <div class="host-item">
                    <div class="favicon-wrapper ${isDisabled ? 'disabled' : ''}">
                        <md-circular-progress indeterminate></md-circular-progress>
                        <img class="favicon-img favicon" src="${faviconUrl}" />
                    </div>
                    <div class="host-item-content ${isDisabled ? 'disabled' : ''}">
                        <div class="host-item-name">${name || url}</div>
                        ${fileType === "custom-source" ? `
                            <span class="badge blocklist-badge"></span>
                        ` : ''}
                    </div>
                    <div class="spacer"></div>
                    <md-checkbox value="${url}"></md-checkbox>
                </div>
            `;

            const img = listItem.querySelector(".favicon-img");
            const wrapper = listItem.querySelector(".favicon-wrapper");
            const loader = listItem.querySelector("md-circular-progress");
            wrapper.onclick = () => linkRedirect(url);
            img.onload = () => {
                loader.style.display = "none";
                img.style.display = "block";
            };
            img.onerror = () => {
                loader.style.display = "none";
                listItem.querySelector(".favicon-wrapper").innerHTML = `<md-icon>domain</md-icon>`
            };

            const badge = listItem.querySelector('.badge');
            if (badge) {
                badge.textContent = formatNumber(sourceCounts[url] || 0, isApril1st, true);
                badge.classList.toggle('display-flex', !isDisabled);
            }

            listItem.addEventListener('contextmenu', (e) => {
                e.preventDefault();
                const list = listItem.parentElement;
                if (list) {
                    const controlList = list.previousElementSibling;
                    const isControlListShowing = controlList.classList.contains('show');

                    if (isControlListShowing) {
                        const hideControls = () => {
                            controlList.classList.remove('show');
                            if (list.controlListeners) list.controlListeners.abort();
                        };
                        openEditDialog(fileType, rawLine, hideControls);
                        return;
                    }
                    const checkboxes = list.querySelectorAll('md-checkbox');
                    checkboxes.forEach(cb => cb.classList.add('show'));
                    controlList.classList.add('show');
                    setupControlListListeners(list, fileType);
                    const checkbox = listItem.querySelector('md-checkbox');
                    if (checkbox) {
                        checkbox.checked = true;
                        checkbox.dispatchEvent(new Event('change', { bubbles: true }));
                    }
                }
            });

            listItem.addEventListener('click', () => {
                const checkbox = listItem.querySelector('md-checkbox');
                if (checkbox.classList.contains('hidden')) return;
                checkbox.checked = !checkbox.checked;
                checkbox.dispatchEvent(new Event('change', { bubbles: true }));
            });

            if (!skipDivider) {
                listElement.appendChild(document.createElement("md-divider"));
            }
            skipDivider = false;
            listElement.appendChild(listItem);
        });
    } catch (e) {
        console.warn(e);
    }
}

// Function to remove a line from whitelist/blacklist/custom-source
function editLine(fileType, lines, action = "remove") {
    showPrompt(`${action === 'remove' ? 'Removing' : action === 'enable' ? 'Enabling' : 'Disabling'} entries…`, true, 3000);
    const output = [];
    const result = spawn('sh', [`${modulePath}/rmlwk.sh`, `--${fileType}`, action, ...lines]);
    result.stdout.on('data', (data) => output.push(data));
    result.on('exit', (code) => {
        if (code === 0) {
            const count = lines.length;
            const actionStr = action === 'remove' ? 'Removed' : action === 'enable' ? 'Enabled' : 'Disabled';
            const typeMap = {
                'whitelist': 'domain',
                'blacklist': 'domain',
                'custom-source': 'source',
                'custom-rule': 'rule'
            };
            const itemName = typeMap[fileType] || 'entry';
            showPrompt(`${actionStr} ${count} ${itemName}${count > 1 ? 's' : ''}`, true);
        } else {
            const allText = output.join('').trim().split('\n');
            const msg = allText.length ? allText[allText.length - 1] : `Failed to ${action} entries`;
            showPrompt(msg, false);
        }
        loadFile(fileType);
        getStatus();
    });
}

function openEditDialog(fileType, currentLine, onSuccess) {
    const editDialog = document.getElementById('edit-dialog');
    const editName = document.getElementById('edit-name');
    const editDomain = document.getElementById('edit-domain');
    const cancelBtn = document.getElementById('cancel-edit');
    const confirmBtn = document.getElementById('confirm-edit');

    const isDisabled = currentLine.startsWith('# OFF # ');
    const entry = isDisabled ? currentLine.replace('# OFF # ', '') : currentLine;
    const enrtyParts = entry.split('#');
    const domain = enrtyParts[0].trim();
    const name = enrtyParts.slice(1).join('#').trim() || '';

    editName.value = name;
    editDomain.value = domain;
    editDialog.show();

    const closeDialog = () => editDialog.close();

    cancelBtn.onclick = closeDialog;
    confirmBtn.onclick = async () => {
        const newDomain = editDomain.value.trim();
        const newName = editName.value.trim();
        if (!newDomain || (newDomain === domain && newName === name)) {
            closeDialog();
            return;
        }

        const newLine = `${isDisabled ? '# OFF # ' : ''}${newDomain}${newName ? ' # ' + newName : ''}`
        const targetFile = `${basePath}/${filePaths[fileType]}`;
        const escapeLine = (line) => line.replace(/[\/&]/g, '\\$&');

        const result = await exec(`sed -i 's|${escapeLine(currentLine)}|${escapeLine(newLine)}|' "${targetFile}"`);
        if (result.errno === 0) {
            if (onSuccess) onSuccess();
            await loadFile(fileType);
        } else {
            showPrompt('Failed to update line', false);
        }
        closeDialog();
    };
}

// Function to link file
async function linkFile() {
    const result = await exec(`
        mkdir -p ${modulePath}/webroot/link
        [ -L ${modulePath} ] || ln -s ${basePath} ${modulePath}/webroot/link/persistent_dir
    `);
    return result.errno === 0;
}

function setupPrank() {
    const today = new Date();
    if (today.getMonth() !== 3 || today.getDate() !== 1) {
        // Not April 1st, revert Easter Egg changes if any
        document.getElementById('module-name').textContent = "Re-Malwack";
        const statusText = document.getElementById('status-text');
        if (statusText && statusText.previousElementSibling && statusText.previousElementSibling.textContent === "Allowed Ads") {
            statusText.previousElementSibling.textContent = "Blocked Entries";
        }
        return;
    }

    // April 1st Easter Egg
    document.getElementById('module-name').textContent = "Re-Malware";

    // Change Blocked Entries to Allowed Ads
    const statusText = document.getElementById('status-text');
    if (statusText && statusText.previousElementSibling) {
        statusText.previousElementSibling.textContent = "Allowed Ads";
    }

    // Replace the logo with the Re-Malware SVG
    const logoElement = document.getElementById('logo');
    if (logoElement) {
        logoElement.innerHTML = ReMalwareIcon;
    }
}

let cachedThemeData = null;

/**
 * Load theme from theme.json and apply as CSS variables
 * @param {string} themeName - Name of the theme to load
 */
async function loadTheme(themeName) {
    try {
        if (!cachedThemeData) {
            const response = await fetch('theme.json');
            cachedThemeData = await response.json();
        }

        let schemeName = themeName;
        if (themeName === 'system') {
            const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
            const preferred = prefersDark ? 'dark' : 'light';
            schemeName = cachedThemeData.schemes[preferred] ? preferred : Object.keys(cachedThemeData.schemes)[0];
        }

        const scheme = cachedThemeData.schemes[schemeName];
        if (!scheme) return;

        const root = document.documentElement;
        for (const [key, value] of Object.entries(scheme)) {
            const cssVarName = `--md-sys-color-${key.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase()}`;
            root.style.setProperty(cssVarName, value);
        }
        root.style.setProperty('--md-sys-color-primary-main', scheme.primary);
        document.documentElement.classList.toggle('dark-theme', schemeName === 'dark');
    } catch (error) {
        console.error('Error loading theme:', error);
    }
}

/**
 * Setup WebUI color theme
 * localStorage: remalwack_theme - theme name
 * @return {Promise<void>}
 */
async function setupTheme() {
    const themeAnchor = document.getElementById('theme-toggle');
    const themeSelect = document.getElementById('theme-select');

    themeAnchor.onclick = (e) => {
        e.stopImmediatePropagation();
        themeSelect.open = !themeSelect.open
    }
    try {
        if (!cachedThemeData) {
            const response = await fetch('theme.json');
            cachedThemeData = await response.json();
        }

        // Clear and populate theme-select
        themeSelect.innerHTML = '';

        const options = [...Object.keys(cachedThemeData.schemes), 'system'];
        const savedTheme = localStorage.getItem('remalwack_theme') || 'system';

        options.forEach(key => {
            const option = document.createElement('md-menu-item');
            if (key === savedTheme) option.setAttribute('selected', '');
            option.innerHTML = `
                <div slot="headline">${key.charAt(0).toUpperCase() + key.slice(1)}</div>
            `;
            option.onclick = (e) => {
                e.stopImmediatePropagation();
                themeSelect.querySelectorAll('md-menu-item').forEach(item => {
                    item.removeAttribute('selected');
                });
                option.setAttribute('selected', '');
                setNewTheme(key);
            }
            themeSelect.appendChild(option);
        });

        await loadTheme(savedTheme);

        const setNewTheme = async (themeName) => {
            if (themeName === 'system') {
                localStorage.removeItem('remalwack_theme');
            } else {
                localStorage.setItem('remalwack_theme', themeName);
            }
            await loadTheme(themeName);
        }

        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
            if (themeSelect.value === 'system') {
                loadTheme('system');
            }
        });
    } catch (error) {
        console.error('Error setting up theme:', error);
    }
}

// setup profile
function setupProfile() {
    const profileBox = document.getElementById('profile');
    const profileMenu = document.getElementById('profile-menu');
    const profileText = document.getElementById('profile-text');
    const loadingOverlay = document.getElementById('loading-overlay');

    profileBox.onclick = (e) => {
        e.stopImmediatePropagation();
        profileMenu.open = !profileMenu.open
    }

    const setActiveProfile = (profileName) => {
        profileText.textContent = profileName;
        profileMenu.querySelectorAll('md-menu-item').forEach(item => item.removeAttribute('selected'));
        profileMenu.querySelector(`md-menu-item[value="${profileName.toLowerCase()}"]`).setAttribute('selected', '');
    }

    exec(`grep "^profile=" ${CONFIG_PATH} | cut -d'=' -f2 | head -n 1 || echo 'default'`).then((result) => {
        if (result.errno !== 0) return;
        const capitalize = (str) => str.charAt(0).toUpperCase() + str.slice(1);
        setActiveProfile(capitalize(result.stdout.trim()));
    });

    profileMenu.querySelectorAll('md-menu-item').forEach(item => {
        item.onclick = () => {
            loadingOverlay.classList.add('show');
            const result = spawn(`sh ${modulePath}/rmlwk.sh --profile ${item.textContent.toLowerCase()}`);
            result.on('exit', (code) => {
                loadingOverlay.classList.remove('show');
                if (code !== 0 && !import.meta.env.DEV) {
                    showPrompt(`Failed to change profile to ${item.textContent}`);
                    return;
                }
                setActiveProfile(item.textContent);
            });
        }
    });
}

// update adblock swtich
async function updateAdblockSwtich() {
    const play = document.getElementById('play-icon');
    const pause = document.getElementById('pause-icon');
    const protection = await isPaused();
    play.classList.toggle('display-block', protection);
    pause.classList.toggle('display-block', !protection);
}

function initCredit() {
    const credit = document.querySelector('.credit-list');
    fetch('contributors.json')
        .then(response => response.json())
        .then(data => {
            data.forEach(contributor => {
                const creditBox = document.createElement('div');
                creditBox.className = 'credit-box';
                creditBox.innerHTML = `
                    <img src="https://github.com/${contributor.username}.png" alt="${contributor.username}">
                    <h3>${contributor.username}</h3>
                    <h4>${contributor.type}</h4>
                    <p>${contributor.description}</p>
                    <md-ripple></md-ripple>
                `;
                credit.appendChild(creditBox);
                creditBox.addEventListener('click', () => {
                    linkRedirect(`https://github.com/${contributor.username}`);
                });
            });
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
    document.getElementById("info-box").addEventListener("click", aboutMenu);
    document.getElementById("update").addEventListener("click", () => performAction("--update-hosts"));
    document.getElementById("daily-update-toggle").addEventListener("change", toggleDailyUpdate);
    document.getElementById("reset").addEventListener("click", resetHostsFile);
    document.getElementById("export-logs").addEventListener("click", exportLogs);

    // Action mode listener
    document.getElementById("action-mode").addEventListener("click", () => updateActionMode(actionMode === 1 ? 0 : 1));

    // Custom block toggle listeners
    setupCustomBlock();

    // About page links
    links.forEach(link => {
        document.getElementById(link.element).addEventListener("click", () => {
            linkRedirect(link.url);
        });
    });

    // Adblock switch
    document.getElementById('adblock-switch').addEventListener("click", async () => {
        const result = await performAction('--adblock-switch', false);
        showPrompt(result ? "Success" : "Failed", result);
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
    document.getElementById("custom-rule-ip").addEventListener("keypress", (e) => {
        if (e.key === "Enter") handleAdd("custom-rule");
    });
    document.getElementById("custom-rule-domain").addEventListener("keypress", (e) => {
        if (e.key === "Enter") handleAdd("custom-rule");
    });
    document.getElementById("whitelist-add").addEventListener("click", () => handleAdd("whitelist"));
    document.getElementById("blacklist-add").addEventListener("click", () => handleAdd("blacklist"));
    document.getElementById("custom-source-add").addEventListener("click", () => handleAdd("custom-source"));
    document.getElementById("custom-rule-add").addEventListener("click", () => handleAdd("custom-rule"));

    // Query
    document.getElementById("query-input").addEventListener("keypress", (e) => {
        if (e.key === "Enter") handleQuery();
    });
    document.getElementById("query-search").addEventListener("click", () => handleQuery());
}

// Function to handle festival themes
function setupFestivalThemes() {
    const now = new Date();
    const currentMonth = now.getMonth() + 1;
    const currentDay = now.getDate();

    festivals.forEach(festival => {
        const start = festival.start;
        const end = festival.end;
        let isActive = false;

        if (start.month === end.month) {
            // Same month
            if (currentMonth === start.month && currentDay >= start.day && currentDay <= end.day) {
                isActive = true;
            }
        } else {
            // Spans year end, like Dec to Jan
            if ((currentMonth === start.month && currentDay >= start.day) ||
                (currentMonth === end.month && currentDay <= end.day)) {
                isActive = true;
            }
        }
        if (isActive) {
            const element = document.getElementById(festival.id);
            if (element) element.classList.add('show');
        }
    });
}

async function checkRebootRequired() {
    const result = await exec(`[ -f "${basePath}/reboot_required" ] && echo "true" || echo "false"`);
    if (result.stdout.trim() === "true") {
        document.getElementById('reboot-required-box').classList.add('display-flex');
    }
}

// Initial load
document.addEventListener('DOMContentLoaded', async () => {
    await Promise.all([setupTheme()]);
    document.querySelectorAll('[unresolved]').forEach(el => el.removeAttribute('unresolved'));
    checkMMRL();
    setupPrank();
    setupFestivalThemes();
    setupEventListener();
    getVersion();
    setupProfile();
    getStatus();
    checkMount();
    loadActionMode();
    updateAdblockSwtich();
    floatBtn.classList.add('show');
    checkRebootRequired();
    await checkBlockStatus();
    ["custom-source", "custom-rule", "blacklist", "whitelist"].forEach(loadFile);
    loadDnsLogs();

    // Bind listeners since setupEventListener is likely hoisted
    document.getElementById('dns-logging-toggle').addEventListener('change', toggleDnsLogging);
    document.getElementById('refresh-dns-logs').addEventListener('click', () => {
        const tbBack = document.getElementById('dns-tb-back');
        if (tbBack) tbBack.click();
        loadDnsLogs();
        showPrompt("DNS Logs refreshed", true);
    });
    document.getElementById('clear-dns-logs').addEventListener('click', async () => {
        const tbBack = document.getElementById('dns-tb-back');
        if (tbBack) tbBack.click();
        await exec(`rm ${basePath}/logs/dns.log`);
        showPrompt("DNS Logs cleared", true);
        loadDnsLogs();
    });
    document.getElementById('reboot-card-click')?.addEventListener('click', () => {
        const rebootDialog = document.getElementById('reboot-dialog');
        rebootDialog.show();
        document.getElementById('cancel-reboot').onclick = () => rebootDialog.close();
        document.getElementById('confirm-reboot').onclick = () => {
            rebootDialog.close();
            exec('reboot');
        };
    });
});

// Overwrite default dialog animation
document.querySelectorAll('md-dialog').forEach(dialog => {
    const defaultOpenAnim = dialog.getOpenAnimation;
    const defaultCloseAnim = dialog.getCloseAnimation;

    dialog.getOpenAnimation = () => {
        const defaultAnim = defaultOpenAnim.call(dialog);
        const customAnim = {};
        Object.keys(defaultAnim).forEach(key => customAnim[key] = defaultAnim[key]);

        customAnim.dialog = [
            [
                [{ opacity: 0, transform: 'translateY(50px)' }, { opacity: 1, transform: 'translateY(0)' }],
                { duration: 240, easing: 'ease' }
            ]
        ];
        customAnim.scrim = [
            [
                [{ 'opacity': 0 }, { 'opacity': 0.32 }],
                { duration: 240, easing: 'linear' },
            ],
        ];
        customAnim.container = [];

        return customAnim;
    };

    dialog.getCloseAnimation = () => {
        const defaultAnim = defaultCloseAnim.call(dialog);
        const customAnim = {};
        Object.keys(defaultAnim).forEach(key => customAnim[key] = defaultAnim[key]);

        customAnim.dialog = [
            [
                [{ opacity: 1, transform: 'translateY(0)' }, { opacity: 0, transform: 'translateY(-50px)' }],
                { duration: 240, easing: 'ease' }
            ]
        ];
        customAnim.scrim = [
            [
                [{ 'opacity': 0.32 }, { 'opacity': 0 }],
                { duration: 240, easing: 'linear' },
            ],
        ];
        customAnim.container = [];

        return customAnim;
    };

    dialog.addEventListener('opened', () => document.body.classList.add('noscroll'));
    dialog.addEventListener('closed', () => document.body.classList.remove('noscroll'));
});

// Load DNS logs natively
let dnsViewMode = 'domain';
let _domainCounts = null;
let _appMap = null;

async function loadDnsLogs() {
    const listElement = document.getElementById('logged-dns-list');
    try {
        const response = await fetch('link/persistent_dir/logs/dns.log');
        if (!response.ok) throw new Error('dns.log not found');
        const content = await response.text();
        const lines = content.split('\n').map(l => l.trim()).filter(l => l.length > 0);

        _domainCounts = {};
        _appMap = {};

        lines.forEach(line => {
            const sep = line.indexOf('|');
            if (sep === -1) return;
            const pkg = line.slice(0, sep).trim();
            const domain = line.slice(sep + 1).trim();
            if (!pkg || !domain) return;
            _domainCounts[domain] = (_domainCounts[domain] || 0) + 1;
            if (!_appMap[pkg]) _appMap[pkg] = {};
            _appMap[pkg][domain] = (_appMap[pkg][domain] || 0) + 1;
        });

        // inject toggle once
        if (!document.getElementById('dns-view-toggle')) {
            const toggleRow = document.createElement('div');
            toggleRow.id = 'dns-view-toggle';
            toggleRow.style.cssText = 'display:flex;padding:12px 16px 4px;';
            toggleRow.innerHTML = `
                <div style="display:flex;background:var(--md-sys-color-surface-container-high);border-radius:100px;padding:4px;gap:4px;width:100%;">
                    <button id="dns-btn-domain" style="flex:1;border:none;border-radius:100px;padding:8px 16px;cursor:pointer;font-size:0.875rem;font-family:inherit;outline:none;-webkit-tap-highlight-color:transparent;transition:background 0.2s,color 0.2s;">Per Domain</button>
                    <button id="dns-btn-app"    style="flex:1;border:none;border-radius:100px;padding:8px 16px;cursor:pointer;font-size:0.875rem;font-family:inherit;outline:none;-webkit-tap-highlight-color:transparent;transition:background 0.2s,color 0.2s;">Per App</button>
                </div>
            `;
            listElement.parentElement.insertBefore(toggleRow, listElement);

            document.getElementById('dns-btn-domain').addEventListener('click', () => {
                if (dnsViewMode === 'domain') return;
                const tbBack = document.getElementById('dns-tb-back');
                if (tbBack) tbBack.click();
                dnsViewMode = 'domain';
                dnsUpdateToggle();
                renderDnsView(document.getElementById('logged-dns-list'));
            });
            document.getElementById('dns-btn-app').addEventListener('click', () => {
                if (dnsViewMode === 'app') return;
                const tbBack = document.getElementById('dns-tb-back');
                if (tbBack) tbBack.click();
                dnsViewMode = 'app';
                dnsUpdateToggle();
                renderDnsView(document.getElementById('logged-dns-list'));
            });
        }

        dnsUpdateToggle();
        renderDnsView(listElement);

    } catch (e) {
        listElement.innerHTML = `<div style="text-align:center;padding:20px;opacity:0.5;">No logs recorded yet.</div>`;
    }
}

function dnsUpdateToggle() {
    const domBtn = document.getElementById('dns-btn-domain');
    const appBtn = document.getElementById('dns-btn-app');
    if (!domBtn || !appBtn) return;
    const primary = `var(--md-sys-color-primary)`;
    const onPrimary = `var(--md-sys-color-on-primary)`;
    const none = `transparent`;
    const muted = `var(--md-sys-color-on-surface-variant)`;
    domBtn.style.background = dnsViewMode === 'domain' ? primary : none;
    domBtn.style.color = dnsViewMode === 'domain' ? onPrimary : muted;
    appBtn.style.background = dnsViewMode === 'app' ? primary : none;
    appBtn.style.color = dnsViewMode === 'app' ? onPrimary : muted;
}

async function renderDnsView(listElement) {
    listElement.innerHTML = '';
    if (dnsViewMode === 'domain') {
        renderPerDomain(listElement);
    } else {
        await renderPerApp(listElement);
    }
}

function renderPerDomain(listElement) {
    const sorted = Object.entries(_domainCounts).sort((a, b) => b[1] - a[1]);
    let first = true;

    sorted.forEach(([domain, hits]) => {
        const item = document.createElement('div');
        item.innerHTML = `
            <div class="host-item">
                <div class="favicon-wrapper">
                    <md-circular-progress indeterminate></md-circular-progress>
                    <img class="favicon-img favicon" style="display:none;" src="https://twenty-icons.com/${domain}" />
                </div>
                <div class="host-item-content">
                    <div class="host-item-name">${domain}</div>
                    <span class="badge blocklist-badge" style="display:inline-flex;">${hits} ${hits === 1 ? 'hit' : 'hits'}</span>
                </div>
                <div class="spacer"></div>
                <md-checkbox value="${domain}"></md-checkbox>
            </div>
        `;

        const img = item.querySelector('.favicon-img');
        const wrapper = item.querySelector('.favicon-wrapper');
        const loader = item.querySelector('md-circular-progress');
        const cb = item.querySelector('md-checkbox');

        img.onload = () => { loader.style.display = 'none'; img.style.display = 'block'; };
        img.onerror = () => { loader.style.display = 'none'; wrapper.innerHTML = '<md-icon>domain</md-icon>'; };

        item.addEventListener('click', () => {
            if (!cb.classList.contains('show')) return;
            cb.checked = !cb.checked;
            document.dispatchEvent(new CustomEvent('dns-count-update'));
        });

        dnsAttachLongPress(item, () => {
            const allCbs = Array.from(listElement.querySelectorAll('md-checkbox'));
            allCbs.forEach(c => c.classList.add('show'));
            cb.checked = true;
            dnsShowToolbox(allCbs, null);
        });

        if (!first) listElement.appendChild(document.createElement('md-divider'));
        first = false;
        listElement.appendChild(item);
    });
}

async function getAppsInfo(pkgs) {
    const result = {};
    try {
        if (typeof globalThis.ksu?.getPackagesInfo === 'function') {
            const infos = await getPackagesInfo(pkgs);
            pkgs.forEach((pkg, i) => { result[pkg] = infos[i]?.appLabel || pkg; });
        } else {
            pkgs.forEach(pkg => { result[pkg] = pkg; });
        }
    } catch {
        pkgs.forEach(pkg => { result[pkg] = pkg; });
    }
    return result;
}

async function renderPerApp(listElement) {
    const sortedApps = Object.entries(_appMap)
        .map(([pkg, domains]) => ({ pkg, domains, total: Object.values(domains).reduce((a, b) => a + b, 0) }))
        .sort((a, b) => b.total - a.total);

    const labels = await getAppsInfo(sortedApps.map(a => a.pkg));
    let first = true;

    sortedApps.forEach(({ pkg, domains, total }) => {
        const label = labels[pkg] || pkg;
        const sortedDomains = Object.entries(domains).sort((a, b) => b[1] - a[1]);

        const card = document.createElement('div');
        card.dataset.pkg = pkg;
        card.innerHTML = `
            <div class="host-item app-card-header" style="cursor:pointer;-webkit-tap-highlight-color:transparent;">
                <div class="favicon-wrapper">
                    <div class="loader" data-package="${pkg}" style="display:flex;align-items:center;justify-content:center;width:100%;height:100%;"><md-circular-progress indeterminate></md-circular-progress></div>
                    <img class="app-icon" data-package="${pkg}" style="display:none;width:100%;height:100%;border-radius:8px;object-fit:cover;" />
                </div>
                <div class="host-item-content">
                    <div class="host-item-name" style="font-weight:500;">${label}</div>
                    <span class="badge blocklist-badge" style="display:inline-flex;">${total} ${total === 1 ? 'hit' : 'hits'}</span>
                </div>
                <div class="spacer"></div>
                <md-checkbox class="app-cb" value="${pkg}" style="display:none;"></md-checkbox>
                <md-icon class="expand-icon" style="transition:transform 0.2s;">expand_more</md-icon>
            </div>
            <div class="app-domains" style="display:none;padding-left:56px;"></div>
        `;

        const header = card.querySelector('.app-card-header');
        const domainsEl = card.querySelector('.app-domains');
        const expandIcon = card.querySelector('.expand-icon');
        const appCb = card.querySelector('.app-cb');
        let expanded = false;

        // build domain rows
        const domCbs = [];
        sortedDomains.forEach(([domain, hits], i) => {
            if (i > 0) domainsEl.appendChild(document.createElement('md-divider'));
            const row = document.createElement('div');
            row.className = 'host-item';
            row.style.cssText = 'padding-left:0;-webkit-tap-highlight-color:transparent;';
            row.innerHTML = `
                <div class="favicon-wrapper" style="width:28px;height:28px;">
                    <md-circular-progress indeterminate></md-circular-progress>
                    <img class="favicon-img" style="display:none;width:100%;height:100%;border-radius:4px;" src="https://twenty-icons.com/${domain}" />
                </div>
                <div class="host-item-content">
                    <div class="host-item-name" style="font-size:0.85em;">${domain}</div>
                    <span class="badge blocklist-badge" style="display:inline-flex;">${hits} ${hits === 1 ? 'hit' : 'hits'}</span>
                </div>
                <div class="spacer"></div>
                <md-checkbox value="${domain}"></md-checkbox>
            `;
            const dImg = row.querySelector('.favicon-img');
            const dLdr = row.querySelector('md-circular-progress');
            dImg.onload = () => { dLdr.style.display = 'none'; dImg.style.display = 'block'; };
            dImg.onerror = () => { dLdr.style.display = 'none'; row.querySelector('.favicon-wrapper').innerHTML = '<md-icon>domain</md-icon>'; };

            const domCb = row.querySelector('md-checkbox');
            domCbs.push(domCb);

            row.addEventListener('click', () => {
                if (!domCb.classList.contains('show')) return;
                domCb.checked = !domCb.checked;
                // update toolbox count
                document.dispatchEvent(new CustomEvent('dns-count-update'));
            });

            domainsEl.appendChild(row);
        });

        expandIcon.addEventListener('click', (e) => {
            e.stopPropagation();
            expanded = !expanded;
            domainsEl.style.display = expanded ? 'block' : 'none';
            expandIcon.style.transform = expanded ? 'rotate(180deg)' : '';
            if (appCb.style.display !== 'none') {
                domCbs.forEach(cb => {
                    if (expanded) cb.classList.add('show');
                    else cb.classList.remove('show');
                    cb.checked = expanded ? appCb.checked : cb.checked;
                });
            }
        });

        header.addEventListener('click', (e) => {
            if (e.target === expandIcon || expandIcon.contains(e.target)) return;
            if (appCb.style.display === 'none') return;
            appCb.checked = !appCb.checked;
            domCbs.forEach(cb => { cb.checked = appCb.checked; });
            document.dispatchEvent(new CustomEvent('dns-count-update'));
        });

        dnsAttachLongPress(header, () => {
            const allAppCbs = Array.from(listElement.querySelectorAll('.app-cb'));
            allAppCbs.forEach(c => {
                c.style.display = 'inline-flex';
                requestAnimationFrame(() => c.classList.add('show'));
            });
            appCb.checked = true;
            domCbs.forEach(cb => { cb.checked = true; });
            listElement.querySelectorAll('.app-domains').forEach(domList => {
                if (domList.style.display !== 'none') {
                    domList.querySelectorAll('md-checkbox').forEach(c => c.classList.add('show'));
                }
            });
            dnsShowToolbox(allAppCbs, listElement);
        });

        if (!first) listElement.appendChild(document.createElement('md-divider'));
        first = false;
        listElement.appendChild(card);
    });

    const useKsu = typeof globalThis.ksu?.getPackagesInfo === 'function';
    const usePm = typeof $packageManager !== 'undefined';

    if (!useKsu && !usePm) {
        listElement.querySelectorAll('.loader').forEach(l => { l.parentElement.innerHTML = '<md-icon>android</md-icon>'; });
        return;
    }

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (!entry.isIntersecting) return;
            const wrapper = entry.target;
            const pkg2 = wrapper.querySelector('.app-icon')?.getAttribute('data-package');
            if (!pkg2) return;
            observer.unobserve(wrapper);
            const imgEl = wrapper.querySelector('.app-icon');
            const loaderEl = wrapper.querySelector('.loader');
            imgEl.onload = () => { loaderEl.style.display = 'none'; imgEl.style.display = 'block'; };
            imgEl.onerror = () => { loaderEl.style.display = 'none'; wrapper.innerHTML = '<md-icon>android</md-icon>'; };
            if (usePm) {
                import('webuix').then(({ wrapInputStream }) => {
                    const stream = $packageManager.getApplicationIcon(pkg2, 0, 0);
                    wrapInputStream(stream).then(r => r.arrayBuffer()).then(buffer => {
                        imgEl.src = 'data:image/png;base64,' + btoa(new Uint8Array(buffer).reduce((d, b) => d + String.fromCharCode(b), ''));
                    });
                });
            } else {
                imgEl.src = 'ksu://icon/' + pkg2;
            }
        });
    }, { rootMargin: '100px', threshold: 0.1 });

    listElement.querySelectorAll('.favicon-wrapper').forEach(w => {
        if (w.querySelector('.app-icon')) observer.observe(w);
    });
}

function dnsAttachLongPress(el, cb) {
    let timer = null;
    el.addEventListener('pointerdown', () => { timer = setTimeout(cb, 500); });
    el.addEventListener('pointerup', () => clearTimeout(timer));
    el.addEventListener('pointerleave', () => clearTimeout(timer));
    el.addEventListener('contextmenu', (e) => e.preventDefault());
}

function dnsShowToolbox(appCbs, listRoot) {
    document.getElementById('dns-toolbox')?.remove();

    const isDomainView = listRoot === null;

    const toolbox = document.createElement('div');
    toolbox.id = 'dns-toolbox';
    toolbox.style.cssText = `
        position:fixed;bottom:0;left:0;right:0;z-index:999;
        display:flex;align-items:center;gap:4px;
        padding:12px 12px calc(12px + var(--bottom-inset, 0px)) 12px;
        background:var(--md-sys-color-surface-container-high);
        box-shadow:0 -2px 12px rgba(0,0,0,0.15);
        border-radius:16px 16px 0 0;
    `;
    toolbox.innerHTML = `
        <md-icon-button id="dns-tb-back"><md-icon>arrow_back</md-icon></md-icon-button>
        <span id="dns-tb-count" style="font-size:0.9rem;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;"></span>
        <div style="flex:1;"></div>
        <md-text-button id="dns-tb-all" style="flex-shrink:0;">Select All</md-text-button>
        <md-filled-button id="dns-tb-wl" style="flex-shrink:0;">Whitelist</md-filled-button>
    `;
    document.body.appendChild(toolbox);

    const getCheckedDomains = () => {
        if (isDomainView) {
            return appCbs.filter(cb => cb.checked).map(cb => cb.value);
        }
        const result = [];
        appCbs.forEach(appCb => {
            const card = appCb.closest('[data-pkg]');
            if (!card) return;
            card.querySelectorAll('.app-domains md-checkbox').forEach(dc => {
                if (dc.checked) result.push(dc.value);
            });
        });
        return [...new Set(result)];
    };

    const updateCount = () => {
        const n = getCheckedDomains().length;
        toolbox.querySelector('#dns-tb-count').textContent = `${n} domain${n !== 1 ? 's' : ''} selected`;

        let allSelected = false;
        if (isDomainView) {
            allSelected = appCbs.length > 0 && appCbs.every(cb => cb.checked);
        } else if (listRoot) {
            const allDomCbs = Array.from(listRoot.querySelectorAll('.app-domains md-checkbox'));
            const allAppsChecked = appCbs.length > 0 && appCbs.every(cb => cb.checked);
            const allShowingDomsChecked = allDomCbs.filter(dc => dc.classList.contains('show')).every(dc => dc.checked);
            if (allDomCbs.filter(dc => dc.classList.contains('show')).length > 0) {
                allSelected = allAppsChecked && allShowingDomsChecked;
            } else {
                allSelected = allAppsChecked;
            }
        }
        toolbox.querySelector('#dns-tb-all').textContent = allSelected ? "Unselect All" : "Select All";
    };

    const onCountUpdate = () => updateCount();
    document.addEventListener('dns-count-update', onCountUpdate);

    if (!isDomainView && listRoot) {
        listRoot.querySelectorAll('.app-domains md-checkbox').forEach(dc => {
            dc.addEventListener('change', updateCount);
        });
    }

    updateCount();

    const hide = () => {
        toolbox.remove();
        document.removeEventListener('dns-count-update', onCountUpdate);
        if (isDomainView) {
            appCbs.forEach(cb => { cb.classList.remove('show'); cb.checked = false; });
        } else {
            appCbs.forEach(cb => { 
                cb.classList.remove('show'); 
                cb.checked = false; 
                setTimeout(() => { cb.style.display = 'none'; }, 150);
            });
            if (listRoot) {
                listRoot.querySelectorAll('.app-domains md-checkbox').forEach(dc => {
                    dc.classList.remove('show'); dc.checked = false;
                });
            }
        }
    };

    toolbox.querySelector('#dns-tb-back').addEventListener('click', hide);

    toolbox.querySelector('#dns-tb-all').addEventListener('click', () => {
        const allSelected = toolbox.querySelector('#dns-tb-all').textContent === "Unselect All";
        
        if (isDomainView) {
            appCbs.forEach(cb => { cb.checked = !allSelected; });
        } else if (listRoot) {
            appCbs.forEach(cb => { cb.checked = !allSelected; });
            listRoot.querySelectorAll('.app-domains md-checkbox').forEach(dc => { dc.checked = !allSelected; });
        }
        document.dispatchEvent(new CustomEvent('dns-count-update'));
    });

    toolbox.querySelector('#dns-tb-wl').addEventListener('click', () => {
        const domains = getCheckedDomains();
        if (domains.length === 0) {
            showPrompt('No domains selected', false);
            return;
        }
        hide();
        exec(`sh ${modulePath}/rmlwk.sh --whitelist add ${domains.join(' ')} > /dev/null 2>&1 &`);
        showPrompt(`Whitelisting ${domains.length} domain${domains.length > 1 ? 's' : ''}…`, true, 3000);
        setTimeout(() => { loadFile('whitelist'); getStatus(); }, 1500);
    });
}
