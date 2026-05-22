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
    versionText.textContent = `Click to copy test build ID: ${displayHash}`;
    versionBox.classList.add('display-flex');

    const testVersionCard = document.getElementById('test-version-card-click');
    const testVersionIcon = document.getElementById('test-version-icon');
    const testVersionTitle = document.getElementById('test-version-title');

    if (testVersionCard && displayHash) {
        testVersionCard.onclick = () => {
            navigator.clipboard.writeText(displayHash).then(() => {
                testVersionIcon.textContent = "check";
                testVersionTitle.textContent = "Copied!";
                versionText.textContent = "Test build ID copied to clipboard";
                setTimeout(() => {
                    testVersionIcon.textContent = "science";
                    testVersionTitle.textContent = "Test Release";
                    versionText.textContent = `Click to copy test build ID: ${displayHash}`;
                }, 2000);
            }).catch(() => {
                showPrompt("Failed to copy to clipboard", false);
            });
        };
    }
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

    const mountBox = document.getElementById('broken-mount-box');
    const mountCard = document.getElementById('broken-mount-card-click');
    const mountText = document.getElementById('broken-mount-text');

    if (result.stdout.trim().includes("error") && !await isZnhr() || import.meta.env.DEV) {
        mountBox.classList.add('display-flex');

        if (mountCard) {
            mountCard.onclick = () => {
                mountText.textContent = "Attempting to remount...";
                const remountResult = spawn('sh', [`${modulePath}/rmlwk.sh`, `--remount-hosts`]);
                remountResult.on('exit', (code) => {
                    if (code === 0) {
                        mountBox.classList.remove('display-flex');
                        showPrompt("Hosts remounted successfully", true);
                        getStatus();
                    } else {
                        mountText.textContent = "Remount failed. Tap here to reboot your device.";
                        showPrompt("Failed to remount hosts", false);

                        mountCard.onclick = () => {
                            const rebootDialog = document.getElementById('reboot-dialog');
                            if (rebootDialog) {
                                rebootDialog.show();
                                const cancelBtn = document.getElementById('cancel-reboot');
                                const confirmBtn = document.getElementById('confirm-reboot');
                                if (cancelBtn) cancelBtn.onclick = () => rebootDialog.close();
                                if (confirmBtn) confirmBtn.onclick = () => {
                                    rebootDialog.close();
                                    exec('reboot');
                                };
                            } else {
                                exec('reboot');
                            }
                        };
                    }
                });
            };
        }
    } else {
        mountBox.classList.remove('display-flex');
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

function formatNumber(numStr, isApril1st, includeLabel, customLabel) {
    let num = parseInt(numStr, 10);
    if (isNaN(num)) return numStr;

    let formattedNum = num.toString();
    if (num > 999999) {
        formattedNum = (num / 1000000).toFixed(1) + 'M';
    } else if (num > 9999) {
        formattedNum = (num / 1000).toFixed(1) + 'K';
    }

    if (!includeLabel) return formattedNum;

    const label = customLabel || (isApril1st ? "Allowed Ads" : "Blocked entries");
    return `${formattedNum} ${label}`;
}

// Function to get working status
async function getStatus() {
    const statusElement = document.getElementById('status-text');
    const disableBox = document.getElementById('disabled-box');
    const disableText = document.getElementById('disable-text');
    const idleWarningBox = document.getElementById('idle-warning-box');

    const result = await exec("cat /data/adb/Re-Malwack/counts/blocked_mod.count");

    const idleCheck = await exec(`[ -f "${basePath}/mode_ready" ]`);
    if (idleWarningBox) {
        if (idleCheck.errno === 0) {
            idleWarningBox.classList.add('display-flex');
        } else {
            idleWarningBox.classList.remove('display-flex');
        }
    }

    const welcomeBox = document.getElementById('welcome-box');
    if (welcomeBox) {
        if (localStorage.getItem('firstLaunch') !== 'false') {
            const firstInstallCheck = await exec(`[ -f "${basePath}/first_install_flag" ]`);
            if (firstInstallCheck.errno === 0) {
                welcomeBox.classList.add('display-flex');
                exec(`rm -f "${basePath}/first_install_flag"`);
            }
            localStorage.setItem('firstLaunch', 'false');
        } else {
            welcomeBox.classList.remove('display-flex');
        }
    }

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
            const countsResult = await fetch(`link/persistent_dir/counts/blocklists.counts?t=${Date.now()}`).then(res => res.text());
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
                const countLabel = type === 'safebrowsing' ? 'Domain rules' : undefined;
                badge.textContent = formatNumber(blocklistCounts[type] || 0, isApril1st, true, countLabel);
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
        updateLoggedDnsVisibility(dnsLoggingToggle.selected);
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
        closeBtn.classList.remove('show');
        backBtn.style.display = '';
        setTimeout(() => {
            terminalContent.innerHTML = "";
        }, 400); // Wait for the transition to finish
    }

    const stepMap = {
        '[*]': { icon: 'sync', cls: 'step-running' },
        '[i]': { icon: 'info', cls: 'step-info' },
        '[✓]': { icon: 'check_circle', cls: 'step-done' },
        '[!]': { icon: 'warning', cls: 'step-warn' },
        '[✗]': { icon: 'error', cls: 'step-warn' },
    };

    const completeRunningSteps = () => {
        terminalContent.querySelectorAll('.step-item.step-running').forEach(el => {
            el.classList.replace('step-running', 'step-done');
            const icon = el.querySelector('.step-icon');
            if (icon) icon.textContent = 'check_circle';
        });
    };

    const appendOutput = (data, isError = false) => {
        if (!showTerminal) return;
        String(data).split('\n').forEach(raw => {
            const line = raw.trim();
            if (!line) return;

            const text = line;

            const prefix = Object.keys(stepMap).find(p => text.startsWith(p));
            if (prefix) {
                const { icon, cls } = stepMap[prefix];
                // Complete any still-spinning step whenever any new prefixed line arrives
                completeRunningSteps();
                const label = text.slice(prefix.length).trim();
                const item = document.createElement('div');
                item.className = `step-item ${cls}`;
                item.innerHTML = `<span class="step-icon">${icon}</span><span class="step-label">${label}</span>`;
                terminalContent.appendChild(item);
            } else {
                const el = document.createElement('p');
                el.className = isError ? 'output-line error' : 'output-line step-detail';
                el.textContent = text;
                terminalContent.appendChild(el);
            }
            terminalContent.scrollTo({ top: terminalContent.scrollHeight, behavior: 'smooth' });
        });
    };

    if (showTerminal) {
        terminal.classList.add('show');
        document.body.classList.add('noscroll');
        if (commandOption === "--update-hosts") {
            backBtn.style.display = 'none';
        } else {
            backBtn.style.display = '';
            backBtn.onclick = () => closeTerminal();
        }
        closeBtn.onclick = () => closeTerminal();

        // Show animation until 1st output
        const waitingEl = document.createElement('div');
        waitingEl.className = 'terminal-waiting';
        waitingEl.id = 'terminal-waiting-indicator';
        waitingEl.innerHTML = `<span>Initializing</span><div class="terminal-waiting-dots"><span></span><span></span><span></span></div>`;
        terminalContent.appendChild(waitingEl);
    } else {
        loadingOverlay.classList.add('show');
    }

    if (isShellRunning) return;

    isShellRunning = true;
    return new Promise((resolve) => {
        const args = commandOption.trim().split(/\s+/);
        const output = spawn('sh', [`${modulePath}/rmlwk.sh`, ...args], { env: { MAGISKTMP: 'true', WEBUI: 'true' } });
        let firstData = true;
        const removeWaiting = () => {
            if (firstData) {
                firstData = false;
                const w = document.getElementById('terminal-waiting-indicator');
                if (w) w.remove();
            }
        };
        output.stdout.on('data', (data) => { removeWaiting(); appendOutput(data); });
        output.stderr.on('data', (data) => { removeWaiting(); appendOutput(data, true); });
        output.on('exit', (code) => {
            isShellRunning = false;
            if (showTerminal) {
                completeRunningSteps();
                closeBtn.classList.add('show');
            } else {
                loadingOverlay.classList.remove('show');
            }
            getStatus();
            checkBlockStatus();
            updateAdblockSwtich();
            // Refresh sources list to update per-source counts after hosts update
            if (commandOption.includes('--update-hosts')) {
                loadFile('custom-source');
            }
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
        updateLoggedDnsVisibility(toggle.selected);
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

function updateLoggedDnsVisibility(enabled) {
    const title = document.getElementById('logged-dns-title');
    const box = document.getElementById('logged-dns');
    const display = enabled ? '' : 'none';
    if (title) title.style.display = display;
    if (box) box.style.display = display;
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


// File Explorer -- Import/Export Setting
let xvExplorerMode = 'import'; // 'import' or 'export'
const XV_ROOT = "/sdcard";
let xvCurrentPath = XV_ROOT;

function openXVExplorer(mode = 'import') {
    xvExplorerMode = mode;
    const modal = document.getElementById("xvExplorerModal");
    if (!modal) return;
    modal.classList.add("open");

    const footer = document.getElementById("xv-footer");
    if (footer) {
        footer.style.display = mode === 'export' ? 'flex' : 'none';
    }

    xvCurrentPath = XV_ROOT;
    xvLoadFolder(XV_ROOT);
}

// Function to export settings
async function exportSettings(targetDir) {
    document.getElementById("xvExplorerModal").classList.remove("open");
    const now = new Date();
    const logDate = now.getFullYear() + '-' +
        String(now.getMonth() + 1).padStart(2, '0') + '-' +
        String(now.getDate()).padStart(2, '0') + '__' +
        String(now.getHours()).padStart(2, '0') +
        String(now.getMinutes()).padStart(2, '0') +
        String(now.getSeconds()).padStart(2, '0');
    const targetPath = `${targetDir}/Re-Malwack-settings_${logDate}.tar.gz`;
    const result = await exec(
        `cd ${basePath} && tar -czf "${targetPath}" --exclude='./logs' --exclude='./logs/*' --exclude='./counts' --exclude='./counts/*' . 2>/dev/null || exit 1`
    );
    if (result.errno === 0) {
        showPrompt(`Settings exported to ${targetPath}`, true, 3000);
    } else {
        showPrompt("Export failed", false);
    }
}

function xvUpdateBreadcrumb() {
    const container = document.getElementById("breadcrumb");
    container.innerHTML = "";
    const parts = xvCurrentPath.replace(XV_ROOT, "").split("/").filter(Boolean);

    const root = document.createElement("span");
    root.textContent = "Internal Storage";
    root.onclick = () => xvLoadFolder(XV_ROOT);
    container.appendChild(root);

    let path = XV_ROOT;
    parts.forEach(part => {
        path += "/" + part;
        container.appendChild(document.createTextNode(" / "));
        const crumb = document.createElement("span");
        crumb.textContent = part;
        const p = path;
        crumb.onclick = () => xvLoadFolder(p);
        container.appendChild(crumb);
    });
}

function xvLoadFolder(path) {
    if (!path.startsWith(XV_ROOT)) path = XV_ROOT;
    xvCurrentPath = path;
    xvUpdateBreadcrumb();

    const explorer = document.getElementById("fileExplorer");
    explorer.innerHTML = "Loading…";

    exec(`ls -Ap "${path}" 2>/dev/null`).then(({ errno, stdout }) => {
        explorer.innerHTML = "";

        if (xvCurrentPath !== XV_ROOT) {
            const row = xvMakeRow("📁", "..", "folder");
            row.onclick = () => {
                let parent = xvCurrentPath.split("/").slice(0, -1).join("/");
                if (!parent.startsWith(XV_ROOT)) parent = XV_ROOT;
                xvLoadFolder(parent);
            };
            explorer.appendChild(row);
        }

        if (errno !== 0 || !stdout?.trim()) {
            const empty = xvMakeRow("", "Empty folder", "disabled");
            explorer.appendChild(empty);
            return;
        }

        stdout.trim().split("\n").forEach(item => {
            if (item.endsWith("/")) {
                const folderName = item.slice(0, -1);
                const row = xvMakeRow("folder", folderName, "folder");
                row.onclick = () => xvLoadFolder(xvCurrentPath + "/" + folderName);
                explorer.appendChild(row);
            } else {
                const isTar = item.endsWith(".tar.gz") || item.endsWith(".tar");
                // Disable file clicks in export mode
                const isClickable = isTar && xvExplorerMode === 'import';
                const row = xvMakeRow(isTar ? "archive" : "insert_drive_file", item, isClickable ? "file" : "disabled");
                if (isClickable) {
                    const fullPath = xvCurrentPath + "/" + item;
                    row.onclick = () => importSettings(fullPath);
                }
                explorer.appendChild(row);
            }
        });
    });
}

function xvMakeRow(icon, label, cls) {
    const row = document.createElement("div");
    row.className = "item " + cls;
    if (icon) {
        const ic = document.createElement("md-icon");
        ic.className = "icon";
        ic.textContent = icon;
        row.appendChild(ic);
    }
    const nm = document.createElement("span");
    nm.textContent = label;
    row.appendChild(nm);
    return row;
}

async function importSettings(filePath) {
    document.getElementById("xvExplorerModal").classList.remove("open");
    const result = await exec(`tar -xzf "${filePath}" -C ${basePath}/ 2>/dev/null || exit 1`);
    if (result.errno === 0) {
        showPrompt("Settings imported successfully", true, 3000);
        await checkBlockStatus();
        await getStatus();
        setTimeout(() => {
            showPrompt("Warning: You MUST 'Update hosts file' to apply these settings!", false, 4000);
        }, 3200);
    } else {
        showPrompt("Import failed", false);
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
        const result = spawn('sh', [`${modulePath}/rmlwk.sh`, '--custom-rule', 'add', ipValue, domValue], { env: { MAGISKTMP: 'true' } });
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

    const result = spawn('sh', args, { env: { MAGISKTMP: 'true' } });
    result.stdout.on('data', (data) => output.push(data));
    result.on('exit', async (code) => {
        addBtn.disabled = false;
        const rawMsg = output[output.length - 1].trim();
        const cleanMsg = rawMsg.replace(/\x1b\[[0-9;]*m/g, '').trim();
        showPrompt(cleanMsg, code === 0);
        if (code === 0) inputElement.value = "";
        await loadFile(fileType);
        await getStatus();
        if (window.updateProfileIndicator) window.updateProfileIndicator();
    });
}

function copyToClipboard(text, successMsg = "Copied to clipboard") {
    navigator.clipboard.writeText(text).then(() => {
        showPrompt(successMsg, true);
    }).catch(() => {
        showPrompt("Failed to copy to clipboard", false);
    });
}

let queryMultiSelectMode = false;
const querySelectedRows = new Map(); // tr -> { domain, ip, isSafebrowsing }

// --- Global Bottom Toolbar Component ---
let globalBottomToolbar = null;

function showBottomToolbar(options) {
    if (!globalBottomToolbar) {
        globalBottomToolbar = document.createElement('div');
        globalBottomToolbar.className = 'global-bottom-toolbar';
        globalBottomToolbar.id = 'global-bottom-toolbar';
        document.body.appendChild(globalBottomToolbar);
    }

    let buttonsHtml = '';
    options.buttons.forEach((btn, i) => {
        const btnTag = btn.type === 'filled' ? 'md-filled-button' : 'md-text-button';
        const iconHtml = btn.icon ? `<md-icon slot="icon">${btn.icon}</md-icon>` : '';
        buttonsHtml += `<${btnTag} id="g-tb-btn-${i}" style="flex-shrink:0;">
            ${iconHtml}
            <span id="g-tb-btn-text-${i}">${btn.text}</span>
        </${btnTag}>`;
    });

    globalBottomToolbar.innerHTML = `
        <md-icon-button id="g-tb-close"><md-icon>${options.closeIcon || 'close'}</md-icon></md-icon-button>
        <span id="g-tb-count" class="selection-count">${options.countText || ''}</span>
        <div class="spacer"></div>
        ${buttonsHtml}
    `;

    document.getElementById('g-tb-close').addEventListener('click', options.onClose);
    options.buttons.forEach((btn, i) => {
        document.getElementById(`g-tb-btn-${i}`).addEventListener('click', btn.onClick);
    });

    requestAnimationFrame(() => globalBottomToolbar.classList.add('show'));
}

function updateBottomToolbarText(text) {
    const textEl = document.getElementById('g-tb-count');
    if (textEl) textEl.textContent = text;
}

function getBottomToolbarButton(index) {
    return document.getElementById(`g-tb-btn-${index}`);
}

function setBottomToolbarButtonText(index, text) {
    const textEl = document.getElementById(`g-tb-btn-text-${index}`);
    if (textEl) {
        textEl.textContent = text;
    }
}

function hideBottomToolbar() {
    if (globalBottomToolbar) {
        globalBottomToolbar.classList.remove('show');
    }
}

function updateQueryMultiSelectToolbar() {
    if (!queryMultiSelectMode) {
        hideBottomToolbar();
        querySelectedRows.forEach((val, tr) => tr.classList.remove('selected-row'));
        querySelectedRows.clear();
        return;
    }

    const count = querySelectedRows.size;
    const countText = `${count} selected`;

    if (!globalBottomToolbar || !globalBottomToolbar.classList.contains('show')) {
        showBottomToolbar({
            closeIcon: 'close',
            countText: countText,
            onClose: () => {
                queryMultiSelectMode = false;
                updateQueryMultiSelectToolbar();
            },
            buttons: [
                {
                    text: 'Copy to Clipboard',
                    icon: 'content_copy',
                    type: 'text',
                    onClick: () => {
                        if (querySelectedRows.size === 0) return;
                        const domains = Array.from(querySelectedRows.values()).map(d => d.domain).join('\n');
                        copyToClipboard(domains, `Copied ${querySelectedRows.size} domain(s)`);
                        queryMultiSelectMode = false;
                        updateQueryMultiSelectToolbar();
                    }
                },
                {
                    text: 'Whitelist',
                    icon: 'verified_user',
                    type: 'filled',
                    onClick: () => {
                        const wlBtn = getBottomToolbarButton(1);
                        if (querySelectedRows.size === 0 || wlBtn.disabled) return;
                        
                        const domains = Array.from(querySelectedRows.values()).map(d => d.domain).join(' ');
                        const whitelistInput = document.getElementById("whitelist-input");
                        if (whitelistInput) whitelistInput.value = domains;
                        
                        document.getElementById("whitelist-add")?.click();

                        queryMultiSelectMode = false;
                        updateQueryMultiSelectToolbar();
                        setTimeout(() => handleQuery(), 1500); // Wait for whitelist add to finish, then refresh query
                    }
                }
            ]
        });
    } else {
        updateBottomToolbarText(countText);
    }

    const copyBtn = getBottomToolbarButton(0);
    const whitelistBtn = getBottomToolbarButton(1);

    if (count === 0) {
        if (copyBtn) copyBtn.disabled = true;
        if (whitelistBtn) whitelistBtn.disabled = true;
        return;
    }

    if (copyBtn) copyBtn.disabled = false;
    
    let hasInvalid = false;
    querySelectedRows.forEach(data => {
        if (data.ip !== '0.0.0.0' && data.ip !== '127.0.0.1') hasInvalid = true; // Redirected
        if (data.isSafebrowsing) hasInvalid = true; // Safebrowsing
    });
    
    if (whitelistBtn) whitelistBtn.disabled = hasInvalid;
}

// Function to handle query domain
function handleQuery() {
    const inputElement = document.getElementById('query-input');
    const resultCard = document.getElementById('query-result-card');
    const resultText = document.getElementById('query-result-text');
    const tableContainer = document.getElementById('query-table-container');
    const tbody = document.getElementById('query-result-table-body');
    const inputValue = inputElement.value.trim();

    if (inputValue === "") return;

    queryMultiSelectMode = false;
    updateQueryMultiSelectToolbar();

    resultText.textContent = "Querying...";
    tbody.innerHTML = "";
    if (tableContainer) tableContainer.style.display = "none";
    resultCard.classList.add('display-block');

    (async () => {
        try {
            const znhrDetected = await isZnhr();
            const hostsFile = znhrDetected ? `/data/adb/hostsredirect/hosts` : `${modulePath}/system/etc/hosts`;

            // Sanitize query
            const sanitizedQuery = inputValue.replace(/[^a-zA-Z0-9.\-_*]/g, '');
            if (sanitizedQuery === "") {
                resultText.textContent = "Invalid search query.";
                return;
            }

            const command = `
                matches=$(grep -i "${sanitizedQuery}" "${hostsFile}" | grep -v '^[[:space:]]*#' | head -n 100)
                if [ -z "$matches" ]; then exit 1; fi
                echo "$matches" | while read -r ip domain; do
                    is_sb="false"
                    if grep -q -i "[[:space:]]$domain$" "${basePath}/cache/safebrowsing/hosts1" 2>/dev/null; then
                        is_sb="true"
                    fi
                    echo "$ip|$domain|$is_sb"
                done
            `;
            const { errno, stdout, stderr } = await exec(command);

            if (errno !== 0 && stdout.trim() === "") {
                resultText.textContent = "No matches found (Domain is not blocked/redirected).";
                return;
            }

            const lines = stdout.split('\n').map(line => line.trim()).filter(line => line.length > 0);
            if (lines.length === 0) {
                resultText.textContent = "No matches found (Domain is not blocked/redirected).";
                return;
            }

            resultText.textContent = "";

            const escapeRegExp = (str) => str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
            const highlightRegex = new RegExp(`(${escapeRegExp(sanitizedQuery)})`, 'gi');

            lines.forEach(line => {
                const parts = line.split('|');
                if (parts.length < 3) return;

                const ip = parts[0];
                const domain = parts[1];
                const isSafebrowsing = parts[2] === 'true';

                const tr = document.createElement('tr');
                tr.style.userSelect = 'none'; // prevent text selection during long press

                // Domain cell
                const tdDomain = document.createElement('td');
                const highlighted = domain.replace(highlightRegex, '<span class="highlight">$1</span>');
                tdDomain.innerHTML = highlighted;
                tdDomain.style.cursor = 'pointer';
                tdDomain.title = 'Long press to select, click to copy';
                tr.appendChild(tdDomain);

                // Status cell
                const tdStatus = document.createElement('td');
                const badge = document.createElement('span');
                badge.className = 'status-badge';

                if (ip === '0.0.0.0' || ip === '127.0.0.1') {
                    badge.classList.add('blocked');
                    badge.textContent = 'Blocked';
                } else {
                    badge.classList.add('redirected');
                    badge.textContent = `Redirected (${ip})`;
                }

                tdStatus.appendChild(badge);
                
                if (isSafebrowsing) {
                    const sbBadge = document.createElement('span');
                    sbBadge.className = 'status-badge safebrowsing';
                    sbBadge.textContent = 'Safebrowsing';
                    sbBadge.style.marginLeft = '4px';
                    tdStatus.appendChild(sbBadge);
                }

                tr.appendChild(tdStatus);
                tbody.appendChild(tr);

                // Interaction listeners
                let pressTimer;
                let isSelecting = false;

                const handleLongPress = () => {
                    isSelecting = true;
                    if (!queryMultiSelectMode) {
                        queryMultiSelectMode = true;
                    }
                    toggleSelection();
                };

                const toggleSelection = () => {
                    if (querySelectedRows.has(tr)) {
                        querySelectedRows.delete(tr);
                        tr.classList.remove('selected-row');
                        if (querySelectedRows.size === 0) queryMultiSelectMode = false;
                    } else {
                        querySelectedRows.set(tr, { domain, ip, isSafebrowsing });
                        tr.classList.add('selected-row');
                    }
                    updateQueryMultiSelectToolbar();
                };

                tr.addEventListener('pointerdown', (e) => {
                    if (e.button !== 0 && e.pointerType === 'mouse') return;
                    isSelecting = false;
                    pressTimer = setTimeout(handleLongPress, 500);
                });

                tr.addEventListener('pointerup', () => clearTimeout(pressTimer));
                tr.addEventListener('pointerleave', () => clearTimeout(pressTimer));
                tr.addEventListener('pointercancel', () => clearTimeout(pressTimer));
                
                tr.addEventListener('contextmenu', (e) => {
                    e.preventDefault(); // prevent context menu on long press (mobile)
                });

                tr.addEventListener('click', (e) => {
                    if (isSelecting) return;
                    
                    if (queryMultiSelectMode) {
                        toggleSelection();
                    } else {
                        copyToClipboard(domain);
                    }
                });
            });

            if (tableContainer) tableContainer.style.display = "block";
        } catch (err) {
            resultText.textContent = `Failed to execute query: ${err.message || err}`;
        }
    })();
}

// Prevent input box blocked by keyboard
const inputs = document.querySelectorAll('md-outlined-text-field, input, textarea');
const focusClass = 'input-focused';
inputs.forEach(input => {
    input.addEventListener('focus', event => {
        const inDialog = event.currentTarget.closest('md-dialog');
        if (inDialog) return;

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
    input.addEventListener('blur', event => {
        const inDialog = event.currentTarget.closest('md-dialog');
        if (inDialog) return;

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
        const listElement = document.getElementById(`${fileType}-list`);
        listElement.innerHTML = "";

        const cacheBust = `?t=${Date.now()}`;
        const filePath = 'link/persistent_dir/' + filePaths[fileType] + cacheBust;
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
                const countResponse = await fetch(`link/persistent_dir/counts/sources.counts${cacheBust}`);
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
    const result = spawn('sh', [`${modulePath}/rmlwk.sh`, `--${fileType}`, action, ...lines], { env: { MAGISKTMP: 'true' } });
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
        if (window.updateProfileIndicator) window.updateProfileIndicator();
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
    confirmBtn.onclick = () => {
        const newDomain = editDomain.value.trim();
        const newName = editName.value.trim();
        if (!newDomain || (newDomain === domain && newName === name)) {
            closeDialog();
            return;
        }

        const newLine = `${isDisabled ? '# OFF # ' : ''}${newDomain}${newName ? ' # ' + newName : ''}`;
        const targetFile = `${basePath}/${filePaths[fileType]}`;
        const escapeLine = (line) => line.replace(/[\/&]/g, '\\$&');

        const output = [];
        let result;
        if (fileType === 'custom-source') {
            // Use spawn so stdout is captured — await exec() drops output on KSU WebUI
            // Use rmlwk --custom-source edit so profile tracking files (_added.txt /
            // user profile file) are kept in sync — raw sed would bypass tracking
            // and cause names to be lost on the next profile switch or hosts update.
            // Pass old_url, new_url, new_name as three separate args — no spaces in any single arg
            // Shell assembles new_line itself to avoid KSU spawn space-splitting the name
            result = spawn('sh', [`${modulePath}/rmlwk.sh`, '--custom-source', 'edit', domain, newDomain, newName], { env: { MAGISKTMP: 'true' } });
        } else {
            result = spawn('sh', ['-c', `sed -i 's|${escapeLine(currentLine)}|${escapeLine(newLine)}|' "${targetFile}"`]);
        }

        result.stdout.on('data', (data) => output.push(data));
        result.on('exit', async (code) => {
            const rawMsg = (output[output.length - 1] || '').trim();
            const msg = rawMsg.replace(/\x1b\[[0-9;]*m/g, '').trim();
            showPrompt(msg || (code === 0 ? 'Updated successfully' : 'Failed to update line'), code === 0);
            if (code === 0) {
                if (onSuccess) onSuccess();
                await loadFile(fileType);
                if (window.updateProfileIndicator) window.updateProfileIndicator();
            }
            closeDialog();
        });
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
    const profileDialog = document.getElementById('profile-dialog');
    const profileText = document.getElementById('profile-text');
    const profileListContainer = document.getElementById('profile-list-container');
    const applyProfileBtn = document.getElementById('apply-profile-btn');
    const openCreateProfileDialogBtn = document.getElementById('open-create-profile-dialog');
    const createProfileDialog = document.getElementById('create-profile-dialog');
    const cancelCreateProfileBtn = document.getElementById('cancel-create-profile');
    const cancelProfileDialog = document.getElementById('cancel-profile-dialog');
    const submitNewProfile = document.getElementById('submit-new-profile');
    const createProfileSpinner = document.getElementById('create-profile-spinner');
    const newProfileName = document.getElementById('new-profile-name');
    const newProfileDesc = document.getElementById('new-profile-desc');
    const baseProfileSelect = document.getElementById('base-profile-select');
    const loadingOverlay = document.getElementById('loading-overlay');

    const editProfileDialog = document.getElementById('edit-profile-dialog');
    const editProfileName = document.getElementById('edit-profile-name');
    const editProfileDesc = document.getElementById('edit-profile-desc');
    const cancelEditProfile = document.getElementById('cancel-edit-profile');
    const confirmEditProfile = document.getElementById('confirm-edit-profile');

    let currentProfile = 'default';

    const restoreProfileDialogScroll = () => {
        profileDialog.show();
        setTimeout(() => {
            const selectedItem = document.getElementById('selected-profile-item');
            if (selectedItem) {
                selectedItem.scrollIntoView({ behavior: 'auto', block: 'center' });
            }
            const selectedProfileName = profileDialog.dataset.selectedProfile;
            if (selectedProfileName) {
                document.querySelectorAll('md-radio[name="profile-selection"]').forEach(r => {
                    r.checked = (r.value === selectedProfileName);
                });
            }
        }, 50);
    };

    profileBox.onclick = async (e) => {
        e.stopImmediatePropagation();
        profileDialog.show();
        await renderProfileList();
        setTimeout(() => {
            const selectedItem = document.getElementById('selected-profile-item');
            if (selectedItem) {
                selectedItem.scrollIntoView({ behavior: 'auto', block: 'center' });
            }
        }, 50);
    };

    cancelProfileDialog.onclick = () => {
        profileDialog.close();
    };

    openCreateProfileDialogBtn.onclick = () => {
        profileDialog.close();
        createProfileDialog.show();
    };

    cancelCreateProfileBtn.onclick = () => {
        createProfileDialog.close();
        restoreProfileDialogScroll();
    };

    applyProfileBtn.onclick = () => {
        const selectedProfileName = profileDialog.dataset.selectedProfile;
        if (!selectedProfileName) return;

        if (selectedProfileName === currentProfile) {
            profileDialog.close();
            return;
        }

        loadingOverlay.classList.add('show');
        profileDialog.close();
        const result = spawn(`sh ${modulePath}/rmlwk.sh --profile ${selectedProfileName}`);
        result.on('exit', (code) => {
            loadingOverlay.classList.remove('show');
            if (code !== 0 && !import.meta.env.DEV) {
                showPrompt(`Failed to change profile to ${selectedProfileName}`);
                return;
            }
            setActiveProfile(selectedProfileName);
            showPrompt(`Successfully switched to ${capitalize(selectedProfileName)} profile`);
            ["custom-source"].forEach(loadFile);
        });
    };

    cancelEditProfile.onclick = () => {
        editProfileDialog.close();
        restoreProfileDialogScroll();
    };

    confirmEditProfile.onclick = async () => {
        const originalName = editProfileName.getAttribute('data-original');
        const newName = editProfileName.value.trim().toLowerCase().replace(/[^a-z0-9_-]/g, '');
        const newDesc = editProfileDesc.value.trim();

        if (!newName) {
            showPrompt('Profile name cannot be empty', false);
            return;
        }

        if (newName === 'custom') {
            showPrompt('The name "custom" is reserved', false);
            return;
        }

        editProfileDialog.close();
        loadingOverlay.classList.add('show');

        const profilePath = `${basePath}/profiles/${originalName}.txt`;
        const newProfilePath = `${basePath}/profiles/${newName}.txt`;

        let cmd = '';
        if (originalName !== newName) {
            cmd += `mv "${profilePath}" "${newProfilePath}"\n`;
            if (currentProfile === originalName) {
                cmd += `sed -i "s/^profile=.*/profile=${newName}/" ${CONFIG_PATH}\n`;
            }
        }
        cmd += `sed -i '/^# DESC:/d' "${newProfilePath}"\n`;
        if (newDesc) {
            cmd += `sed -i '1i# DESC: ${newDesc}' "${newProfilePath}"\n`;
        }

        const result = await exec(cmd);
        loadingOverlay.classList.remove('show');

        if (result.errno === 0) {
            showPrompt(`Profile updated`);
            if (currentProfile === originalName && originalName !== newName) {
                setActiveProfile(newName);
            }
            renderProfileList();
            restoreProfileDialogScroll();
        } else {
            showPrompt('Failed to update profile', false);
            restoreProfileDialogScroll();
        }
    };

    const capitalize = (str) => str.charAt(0).toUpperCase() + str.slice(1);

    window.updateProfileIndicator = async () => {
        if (!currentProfile) return;
        try {
            const check = await exec(`[ -s "${basePath}/profiles/${currentProfile}_added.txt" ] || [ -s "${basePath}/profiles/${currentProfile}_removed.txt" ]`);
            const isCustomized = check.errno === 0;
            profileText.textContent = capitalize(currentProfile) + (isCustomized ? ' (Customized)' : '');
        } catch (e) {
            profileText.textContent = capitalize(currentProfile);
        }
    };

    const setActiveProfile = (profileName) => {
        currentProfile = profileName.toLowerCase();
        profileText.textContent = capitalize(profileName);
        window.updateProfileIndicator();
    };

    exec(`grep "^profile=" ${CONFIG_PATH} | cut -d'=' -f2 | head -n 1 || echo 'default'`).then((result) => {
        if (result.errno === 0) {
            setActiveProfile(result.stdout.trim());
        }
    });

    const getProfiles = async () => {
        const cmd = `
            for p in ${modulePath}/profiles/*.txt ${basePath}/profiles/*.txt; do
                [ -f "$p" ] || continue
                name=$(basename "$p" .txt)
                
                # Exclude _added.txt and _removed.txt
                case "$name" in
                    *_added | *_removed) continue ;;
                esac

                desc=$( (grep -m 1 "^# DESC: " "$p" 2>/dev/null || true) | sed 's/^# DESC: //' )
                type="builtin"
                case "$p" in
                    *"${basePath}/profiles"*) type="user" ;;
                esac
                
                customized="false"
                if [ -s "${basePath}/profiles/\${name}_added.txt" ] || [ -s "${basePath}/profiles/\${name}_removed.txt" ]; then
                    customized="true"
                fi
                echo "$name|$desc|$type|$customized"
            done
        `;
        const result = await exec(cmd);
        const profiles = [];
        if (result.errno === 0 && result.stdout) {
            const lines = result.stdout.trim().split('\n');
            for (const line of lines) {
                if (!line) continue;
                const [name, desc, type, customized] = line.split('|');
                if (name && !profiles.find(p => p.name === name)) {
                    profiles.push({ name, desc: desc || '', type, customized: customized === 'true' });
                }
            }
        }
        return profiles;
    };

    const renderProfileList = async () => {
        profileListContainer.innerHTML = '<div style="display: flex; justify-content: center; padding: 16px;"><md-circular-progress indeterminate></md-circular-progress></div>';
        let profiles = [];
        try {
            profiles = await getProfiles();
        } catch (err) {
            console.error(err);
        }
        profileListContainer.innerHTML = '';

        let currentSelect = document.getElementById('base-profile-select');
        let newSelect = currentSelect;
        if (currentSelect && currentSelect.parentNode) {
            newSelect = currentSelect.cloneNode(false);
            currentSelect.parentNode.replaceChild(newSelect, currentSelect);
        }

        const builtinProfiles = profiles.filter(p => p.type === 'builtin');
        const userProfiles = profiles.filter(p => p.type === 'user');

        const renderGroup = (groupProfiles, titleText) => {
            if (groupProfiles.length === 0) return;
            const title = document.createElement('div');
            title.className = 'list-title';
            title.textContent = titleText;
            title.style.marginTop = '4px';
            title.style.marginBottom = '-2px';
            profileListContainer.appendChild(title);

            groupProfiles.forEach(p => {
                if (p.name !== 'custom' && newSelect) {
                    const opt = document.createElement('md-select-option');
                    opt.value = p.name;
                    opt.innerHTML = `<div slot="headline">${capitalize(p.name)}</div>`;
                    newSelect.appendChild(opt);
                }

                const item = document.createElement('div');
                item.className = 'profile-list-item';
                item.style.display = 'flex';
                item.style.alignItems = 'center';
                item.style.justifyContent = 'space-between';
                item.style.padding = '8px 0';
                item.style.borderBottom = '1px solid var(--md-sys-color-outline-variant)';

                const isSelected = p.name === currentProfile;
                if (isSelected) item.id = 'selected-profile-item';

                item.innerHTML = `
                    <div style="display: flex; align-items: center; gap: 12px; flex: 1; cursor: pointer;" class="profile-radio-container">
                        <md-radio name="profile-selection" value="${p.name}" ${isSelected ? 'checked' : ''} style="flex-shrink: 0;"></md-radio>
                        <div style="display: flex; flex-direction: column;">
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <span style="font-weight: 500; font-size: 1rem; color: var(--md-sys-color-on-surface);">${capitalize(p.name)}</span>
                                ${p.customized ? '<span class="badge" style="display:flex; padding: 2px 6px; font-size: 0.75rem; background:var(--md-sys-color-secondary-container); color:var(--md-sys-color-on-secondary-container);">Customized</span>' : ''}
                            </div>
                            ${p.desc ? `<span style="font-size: 0.85rem; color: var(--md-sys-color-on-surface-variant);">${p.desc}</span>` : ''}
                        </div>
                    </div>
                    <div style="display: flex;">
                        ${p.customized ? `
                            <md-icon-button class="reset-profile-btn" data-name="${p.name}" title="Reset Customizations">
                                <md-icon style="color: var(--md-sys-color-primary);">settings_backup_restore</md-icon>
                            </md-icon-button>
                        ` : ''}
                        ${p.type === 'user' ? `
                            <md-icon-button class="edit-profile-btn" data-name="${p.name}" data-desc="${p.desc || ''}" title="Edit Profile">
                                <md-icon style="color: var(--md-sys-color-primary); font-variation-settings: 'FILL' 1;">edit</md-icon>
                            </md-icon-button>
                            <md-icon-button class="delete-profile-btn" data-name="${p.name}" title="Delete Profile">
                                <md-icon style="color: var(--md-sys-color-primary); font-variation-settings: 'FILL' 1;">delete</md-icon>
                            </md-icon-button>
                        ` : ''}
                    </div>
                `;

                const radioContainer = item.querySelector('.profile-radio-container');
                const radio = item.querySelector('md-radio');

                if (isSelected) {
                    profileDialog.dataset.selectedProfile = p.name;
                }

                radioContainer.onclick = () => {
                    profileListContainer.querySelectorAll('md-radio').forEach(r => r.checked = false);
                    radio.checked = true;
                    profileDialog.dataset.selectedProfile = p.name;
                };

                const editBtn = item.querySelector('.edit-profile-btn');
                if (editBtn) {
                    editBtn.onclick = (e) => {
                        e.stopPropagation();
                        const name = editBtn.getAttribute('data-name');
                        const desc = editBtn.getAttribute('data-desc');
                        editProfileName.value = name;
                        editProfileDesc.value = desc;
                        editProfileName.setAttribute('data-original', name);
                        profileDialog.close();
                        editProfileDialog.show();
                    };
                }

                const deleteBtn = item.querySelector('.delete-profile-btn');
                if (deleteBtn) {
                    deleteBtn.onclick = async (e) => {
                        e.stopPropagation();
                        const name = deleteBtn.getAttribute('data-name');
                        const deleteDialog = document.getElementById('delete-profile-dialog');
                        const deleteContent = document.getElementById('delete-profile-content');
                        if (currentProfile === name) {
                            deleteContent.innerHTML = `Are you sure you want to permanently delete the profile <b>${capitalize(name)}</b>?<br><br><span style="color: var(--md-sys-color-error);">Note: This profile is currently selected. Deleting it will automatically switch your protection back to the Default profile.</span>`;
                        } else {
                            deleteContent.innerHTML = `Are you sure you want to permanently delete the profile <b>${capitalize(name)}</b>?`;
                        }
                        
                        profileDialog.close();
                        deleteDialog.show();
                        
                        document.getElementById('cancel-delete-profile').onclick = () => {
                            deleteDialog.close();
                            restoreProfileDialogScroll();
                        };
                        
                        document.getElementById('confirm-delete-profile').onclick = async () => {
                            deleteDialog.close();
                            loadingOverlay.classList.add('show');
                            await exec(`rm -f ${basePath}/profiles/${name}.txt ${basePath}/profiles/${name}_added.txt ${basePath}/profiles/${name}_removed.txt`);
                            loadingOverlay.classList.remove('show');
                            showPrompt(`Profile ${capitalize(name)} deleted`);
                            if (currentProfile === name) {
                                currentProfile = 'default';
                                setActiveProfile('default');
                                spawn(`sh ${modulePath}/rmlwk.sh --profile default`).on('exit', () => {
                                    ["custom-source"].forEach(loadFile);
                                });
                            }
                            renderProfileList();
                            restoreProfileDialogScroll();
                        };
                    };
                }

                const resetBtn = item.querySelector('.reset-profile-btn');
                if (resetBtn) {
                    resetBtn.onclick = (e) => {
                        e.stopPropagation();
                        const name = resetBtn.getAttribute('data-name');
                        profileDialog.close();
                        window.showResetProfileConfirm(capitalize(name), () => {
                            loadingOverlay.classList.add('show');
                            const result = spawn(`sh ${modulePath}/rmlwk.sh --reset-profile ${name}`);
                            result.on('exit', (code) => {
                                loadingOverlay.classList.remove('show');
                                if (code !== 0 && !import.meta.env.DEV) {
                                    showPrompt(`Failed to reset profile ${name}`);
                                    restoreProfileDialogScroll();
                                    return;
                                }
                                showPrompt(`Profile ${capitalize(name)} reset to defaults`);
                                if (currentProfile === name) {
                                    setActiveProfile(name);
                                    spawn(`sh ${modulePath}/rmlwk.sh --profile ${name}`).on('exit', () => {
                                        ["custom-source"].forEach(loadFile);
                                    });
                                }
                                renderProfileList();
                                restoreProfileDialogScroll();
                            });
                        });
                    };
                }

                profileListContainer.appendChild(item);
            });
        };

        renderGroup(builtinProfiles, "Built-in Profiles");
        renderGroup(userProfiles, "User Profiles");
    };

    submitNewProfile.onclick = async () => {
        const nameVal = newProfileName.value.trim().toLowerCase().replace(/[^a-z0-9_-]/g, '');
        const descVal = newProfileDesc.value.trim();
        const baseProfile = document.getElementById('base-profile-select').value;

        if (!nameVal) {
            showPrompt('Profile name cannot be empty', false);
            return;
        }

        if (nameVal === 'custom') {
            showPrompt('The name "custom" is reserved', false);
            return;
        }

        if (!baseProfile) {
            showPrompt('You must select a base profile', false);
            return;
        }

        submitNewProfile.style.display = 'none';
        createProfileSpinner.style.display = 'block';

        const fileContent = descVal ? `# DESC: ${descVal}\n` : '';
        let cmd = `mkdir -p ${basePath}/profiles\n`;

        if (baseProfile && baseProfile !== 'none') {
            cmd += `if [ -f "${basePath}/profiles/${baseProfile}.txt" ]; then cp "${basePath}/profiles/${baseProfile}.txt" "${basePath}/profiles/${nameVal}.txt"; elif [ -f "${modulePath}/profiles/${baseProfile}.txt" ]; then cp "${modulePath}/profiles/${baseProfile}.txt" "${basePath}/profiles/${nameVal}.txt"; fi\n`;
            cmd += `sed -i '/^# DESC:/d' "${basePath}/profiles/${nameVal}.txt"\n`;
            if (descVal) {
                cmd += `sed -i '1i# DESC: ${descVal}' "${basePath}/profiles/${nameVal}.txt"\n`;
            }
        } else {
            cmd += `echo "${fileContent}" > ${basePath}/profiles/${nameVal}.txt\n`;
        }

        const result = await exec(cmd);

        submitNewProfile.style.display = '';
        createProfileSpinner.style.display = 'none';

        if (result.errno === 0) {
            showPrompt(`Profile ${capitalize(nameVal)} created successfully`);
            newProfileName.value = '';
            newProfileDesc.value = '';
            createProfileDialog.close();
            renderProfileList();

            loadingOverlay.classList.add('show');
            const switchResult = spawn(`sh ${modulePath}/rmlwk.sh --profile ${nameVal}`);
            switchResult.on('exit', (code) => {
                loadingOverlay.classList.remove('show');
                if (code !== 0 && !import.meta.env.DEV) {
                    showPrompt(`Failed to switch to the new profile ${nameVal}`);
                    return;
                }
                setActiveProfile(nameVal);
                showPrompt(`Successfully applied ${capitalize(nameVal)} profile`);
                ["custom-source"].forEach(loadFile);
            });
        } else {
            showPrompt(`Failed to create profile: ${result.stderr}`, false);
        }
    };
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
    let welcomeClickCount = 0;
    const welcomeCardInner = document.getElementById("welcome-card-inner");
    if (welcomeCardInner) {
        welcomeCardInner.addEventListener("click", () => {
            welcomeClickCount++;
            const icon = document.getElementById("welcome-icon");
            const title = document.getElementById("welcome-title");
            const desc = document.getElementById("welcome-desc");

            if (welcomeClickCount === 2) {
                icon.textContent = "pan_tool";
                title.textContent = "Huh-";
                desc.textContent = "Hey stop clicking!";
                welcomeCardInner.style.setProperty("background-color", "var(--md-sys-color-error-container)", "important");
                welcomeCardInner.style.setProperty("color", "var(--md-sys-color-on-error-container)", "important");
            } else if (welcomeClickCount === 4) {
                icon.textContent = "question_mark";
                title.textContent = "Uhh...";
                desc.textContent = "What are you doing mate 🥀";
                welcomeCardInner.style.setProperty("background-color", "var(--md-sys-color-secondary-container)", "important");
                welcomeCardInner.style.setProperty("color", "var(--md-sys-color-on-secondary-container)", "important");
            } else if (welcomeClickCount === 8) {
                icon.textContent = "emoticon";
                title.textContent = "Nice try";
                desc.textContent = "No easter eggs here 😝";
                welcomeCardInner.style.setProperty("background-color", "var(--md-sys-color-tertiary-container)", "important");
                welcomeCardInner.style.setProperty("color", "var(--md-sys-color-on-tertiary-container)", "important");
            } else if (welcomeClickCount === 11) {
                icon.textContent = "celebration";
                title.textContent = "Alright you've found the secret!";
                desc.textContent = "Never gonna give you up, never gonna let you down :)";
                welcomeCardInner.style.setProperty("background-color", "var(--md-sys-color-primary-container)", "important");
                welcomeCardInner.style.setProperty("color", "var(--md-sys-color-on-primary-container)", "important");
                setTimeout(() => {
                    linkRedirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ");
                }, 1500);
            }
        });
    }

    document.getElementById("info-box").addEventListener("click", aboutMenu);
    document.getElementById("update").addEventListener("click", () => performAction("--update-hosts"));
    document.getElementById("daily-update-toggle").addEventListener("change", toggleDailyUpdate);
    document.getElementById("reset").addEventListener("click", resetHostsFile);
    document.getElementById("export-logs").addEventListener("click", exportLogs);
    document.getElementById("export-settings").addEventListener("click", () => openXVExplorer('export'));
    document.getElementById("import-settings").addEventListener("click", () => openXVExplorer('import'));
    document.getElementById("xv-save-btn").addEventListener("click", () => {
        if (xvExplorerMode === 'export') {
            exportSettings(xvCurrentPath);
        }
    });
    document.getElementById("xv-close-btn").addEventListener("click", () => {
        document.getElementById("xvExplorerModal").classList.remove("open");
    });
    document.getElementById("xvExplorerModal").addEventListener("click", (e) => {
        if (e.target === e.currentTarget) e.currentTarget.classList.remove("open");
    });

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
        if (result) {
            const paused = await isPaused();
            showPrompt(paused ? "Protection has been paused." : "Protection has been resumed.");
        } else {
            showPrompt("Failed to toggle protection", false);
        }
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
    document.getElementById("query-input").addEventListener("input", () => {
        const resultCard = document.getElementById('query-result-card');
        if (resultCard) {
            resultCard.classList.remove('display-block');
        }
    });


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
        await exec(`echo "" > ${basePath}/logs/dns.log`);
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

        if (lines.length === 0) throw new Error('dns.log is empty');

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
            toggleRow.className = 'dns-view-toggle-row';
            toggleRow.innerHTML = `
                <div class="dns-segment-control">
                    <div class="dns-segment-bg left"></div>
                    <div class="dns-segment-bg right"></div>
                    <div class="dns-segment-slider" id="dns-segment-slider"></div>
                    <button id="dns-btn-domain" class="dns-segment-btn"><span>Per Domain</span></button>
                    <button id="dns-btn-app" class="dns-segment-btn"><span>Per App</span></button>
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
        const toggle = document.getElementById('dns-view-toggle');
        if (toggle) toggle.remove();
    }
}

function dnsUpdateToggle() {
    const domBtn = document.getElementById('dns-btn-domain');
    const appBtn = document.getElementById('dns-btn-app');
    const slider = document.getElementById('dns-segment-slider');
    if (!domBtn || !appBtn || !slider) return;
    const isDomain = dnsViewMode === 'domain';
    domBtn.classList.toggle('dns-segment-btn--active', isDomain);
    appBtn.classList.toggle('dns-segment-btn--active', !isDomain);
    if (isDomain) {
        slider.style.transform = 'translateX(0)';
        slider.style.borderRadius = '24px 8px 8px 24px';
    } else {
        slider.style.transform = 'translateX(calc(100% + 4px))';
        slider.style.borderRadius = '8px 24px 24px 8px';
    }
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
    const isDomainView = listRoot === null;

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
        updateBottomToolbarText(`${n} domain${n !== 1 ? 's' : ''} selected`);

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
        setBottomToolbarButtonText(0, allSelected ? "Unselect All" : "Select All");
    };

    const onCountUpdate = () => updateCount();
    document.addEventListener('dns-count-update', onCountUpdate);

    if (!isDomainView && listRoot) {
        listRoot.querySelectorAll('.app-domains md-checkbox').forEach(dc => {
            dc.addEventListener('change', updateCount);
        });
    }

    const hide = () => {
        hideBottomToolbar();
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

    showBottomToolbar({
        closeIcon: 'close',
        countText: '',
        onClose: hide,
        buttons: [
            {
                text: 'Select All',
                icon: 'select_all',
                type: 'text',
                onClick: () => {
                    const allSelected = getBottomToolbarButton(0).querySelector('span').textContent === "Unselect All";
                    if (isDomainView) {
                        appCbs.forEach(cb => { cb.checked = !allSelected; });
                    } else if (listRoot) {
                        appCbs.forEach(cb => { cb.checked = !allSelected; });
                        listRoot.querySelectorAll('.app-domains md-checkbox').forEach(dc => { dc.checked = !allSelected; });
                    }
                    document.dispatchEvent(new CustomEvent('dns-count-update'));
                }
            },
            {
                text: 'Whitelist',
                icon: 'verified_user',
                type: 'filled',
                onClick: () => {
                    const domains = getCheckedDomains();
                    if (domains.length === 0) {
                        showPrompt('No domains selected', false);
                        return;
                    }
                    hide();
                    exec(`sh ${modulePath}/rmlwk.sh --whitelist add ${domains.join(' ')} > /dev/null 2>&1 &`);
                    showPrompt(`Whitelisting ${domains.length} domain${domains.length > 1 ? 's' : ''}…`, true, 3000);
                    setTimeout(() => { loadFile('whitelist'); getStatus(); }, 1500);
                }
            }
        ]
    });

    updateCount();
}

// Global dialog blur logic
customElements.whenDefined('md-dialog').then(() => {
    const openDialogs = new Set();
    const updateBlur = () => {
        const resetOverlay = document.getElementById('reset-confirm-overlay');
        const resetActive = resetOverlay && resetOverlay.classList.contains('show');

        if (openDialogs.size > 0 || resetActive) {
            document.body.classList.add('dialog-blur-active');
        } else {
            document.body.classList.remove('dialog-blur-active');
        }
    };

    const observer = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
            mutation.addedNodes.forEach((node) => {
                if (node.tagName === 'MD-DIALOG') {
                    node.addEventListener('open', () => { openDialogs.add(node); updateBlur(); });
                    node.addEventListener('closed', () => { openDialogs.delete(node); updateBlur(); });
                }
            });
        });
    });
    observer.observe(document.body, { childList: true, subtree: true });

    document.querySelectorAll('md-dialog').forEach(dialog => {
        if (dialog.open) openDialogs.add(dialog);
        dialog.addEventListener('open', () => { openDialogs.add(dialog); updateBlur(); });
        dialog.addEventListener('closed', () => { openDialogs.delete(dialog); updateBlur(); });
    });

    document.addEventListener('visibilitychange', () => {
        if (document.visibilityState === 'visible') {
            updateBlur();
        }
    });

    window._updateDialogBlur = updateBlur;
});


// Reset profile confirmation overlay logic
(function setupResetProfileConfirm() {
    const overlay = document.getElementById('reset-confirm-overlay');
    const cancelBtn = document.getElementById('reset-confirm-cancel');
    const confirmBtn = document.getElementById('reset-confirm-ok');
    const bodyText = document.getElementById('reset-confirm-body');

    if (!overlay || !cancelBtn || !confirmBtn) return;

    let _pendingCallback = null;

    window.showResetProfileConfirm = function (profileName, onConfirm) {
        bodyText.textContent = `This will reset all customizations for "${profileName}" back to defaults. This action cannot be undone.`;
        _pendingCallback = onConfirm;
        overlay.classList.add('show');
        if (window._updateDialogBlur) window._updateDialogBlur();
    };

    cancelBtn.onclick = () => {
        overlay.classList.remove('show');
        _pendingCallback = null;
        if (window._updateDialogBlur) window._updateDialogBlur();
        profileDialog.show();
    };

    confirmBtn.onclick = () => {
        overlay.classList.remove('show');
        if (typeof _pendingCallback === 'function') {
            _pendingCallback();
        }
        _pendingCallback = null;
        if (window._updateDialogBlur) window._updateDialogBlur();
    };
})();
