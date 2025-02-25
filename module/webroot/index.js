// Elements
const aboutButton = document.getElementById('about-button');
const inputs = document.querySelectorAll('input');
const focusClass = 'input-focused';
const telegramLink = document.getElementById('telegram');
const githubLink = document.getElementById('github');
const xdaLink = document.getElementById('xda');
const sponsorLink = document.getElementById('sponsor');
const blockPornToggle = document.getElementById('block-porn-toggle');
const blockGamblingToggle = document.getElementById('block-gambling-toggle');
const blockFakenewsToggle = document.getElementById('block-fakenews-toggle');
const blockSocialToggle = document.getElementById('block-social-toggle');

const basePath = "/data/adb/Re-Malwack";

const filePaths = {
    blacklist: `${basePath}/blacklist.txt`,
    whitelist: `${basePath}/whitelist.txt`,
    "custom-source": `${basePath}/custom-source.txt`,
};

// Link redirect
const links = [
    { element: telegramLink, url: 'https://t.me/Re_Malwack', name: 'Telegram' },
    { element: githubLink, url: 'https://github.com/ZG089/Re-Malwack', name: 'GitHub' },
    { element: xdaLink, url: 'https://xdaforums.com/t/re-malwack-revival-of-malwack-module.4690049/', name: 'XDA' },
    { element: sponsorLink, url: 'https://buymeacoffee.com/zg089', name: 'Sponsor' }
];

// Block types
const blockTypes = [
    { id: 'porn', toggle: blockPornToggle, name: 'porn sites', flag: '--block-porn' },
    { id: 'gambling', toggle: blockGamblingToggle, name: 'gambling sites', flag: '--block-gambling' },
    { id: 'fakenews', toggle: blockFakenewsToggle, name: 'fake news sites', flag: '--block-fakenews' },
    { id: 'social', toggle: blockSocialToggle, name: 'social media sites', flag: '--block-social' }
];

// Ripple effect configuration
const rippleClasses = ['.ripple-container', '.link-icon'];

let isScrolling = false;
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
            aboutMenu.style.opacity = '1';
        }, 10);
        document.body.style.overflow = 'hidden';
    };
    const hideMenu = () => {
        aboutOverlay.style.opacity = '0';
        aboutMenu.style.opacity = '0';
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
    try {
        const version = await execCommand("grep '^version=' /data/adb/modules/Re-Malwack/module.prop | cut -d'=' -f2");
        document.getElementById('version-text').textContent = `${version} | `;
        getStatus();
    } catch (error) {
        if (typeof ksu !== 'undefined' && ksu.mmrl) {
            updateStatus("Please enable JavaScript API in MMRL settings:\n1. Settings\n2. Security\n3. Allow JavaScript API\n4. Re-Malwack\n5. Enable both option");
        } else {
            updateStatus("Error reading description from module.prop");
        }
    }
}

// Function to update the status text dynamically in the WebUI
function updateStatus(statusText) {
    const statusElement = document.getElementById('version-status');
    statusElement.innerHTML = statusText.replace(/\n/g, '<br>');
}

// Function to check if running in MMRL
function checkMMRL() {
    if (typeof ksu !== 'undefined' && ksu.mmrl) {
        // Request API permission
        // Require MMRL version code 33045 or higher
        try {
            $Re_Malwack.requestAdvancedKernelSUAPI();
            $Re_Malwack.requestFileSystemAPI();
        } catch (error) {
            console.log("Error requesting API:", error);
        }
    } else {
        console.log("Not running in MMRL environment.");
    }
}

// Function to get working status
async function getStatus() {
    try {
        await execCommand("grep -q '0.0.0.0' /system/etc/hosts");
        document.getElementById('status-text').textContent = "Protection is enabled ✅";
    } catch (error) {
        document.getElementById('status-text').textContent = "Ready 🟡";
    }
}

// Function to check block status for different site categories
async function checkBlockStatus(type) {
    try {
        const result = await execCommand(`grep -q '^block_${type.id}=1' ${basePath}/config.sh`);
        type.toggle.checked = !result;
    } catch (error) {
        type.toggle.checked = false;
    }
}

// Function to handle peform script and output
async function performAction(promptMessage, commandOption, errorPrompt, errorMessage) {
    try {
        showPrompt(promptMessage, true, 50000);
        await new Promise(resolve => setTimeout(resolve, 300));
        const output = await execCommand(`sh /data/adb/modules/Re-Malwack/rmlwk.sh ${commandOption}`);
        const lines = output.split("\n");
        lines.forEach(line => {
            showPrompt(line, true);
        });
        await getStatus();
    } catch (error) {
        console.error(errorMessage, error);
        showPrompt(errorPrompt, false);
    }
}

// Function to update hosts file
async function updateHostsFile() {
    await performAction("- Downloading updates, Please wait...", "--update-hosts", "- Failed to update hosts", "Failed to update hosts:");
}

// Function to reset hosts
async function resetHostsFile() {
    await performAction("- Resetting hosts file...", "--reset", "- Failed to reset hosts", "Failed to reset hosts:");
}

// Function to export logs
async function exportLogs() {
    try {
        await execCommand(`tar -czvf /sdcard/Download/Re-Malwack_$(date +%Y-%m-%d_%H:%M).tar.gz --exclude='/data/adb/Re-Malwack' -C ${basePath} logs`);
        showPrompt("Logs saved to /sdcard/Download", true);
    } catch (error) {
        console.error("Failed to export logs:", error);
        showPrompt("Failed to export logs", false);
    }
}

// Function to handle blocking/unblocking different site categories
async function handleBlock(type) {
    const isRemoving = type.toggle.checked;
    const prompt_message = isRemoving ? "- Removing entries..." : `- Applying block for ${type.name}...`;
    const action = isRemoving ? `${type.flag} 0` : type.flag;
    const errorPrompt = `- Failed to apply block for ${type.name}`;
    const errorMessage = `Failed to apply block for ${type.name}:`;

    try {
        showPrompt(prompt_message, true, 50000);
        await new Promise(resolve => setTimeout(resolve, 300));
        const output = await execCommand(`sh /data/adb/modules/Re-Malwack/rmlwk.sh ${action}`);
        const lines = output.split("\n");
        lines.forEach(line => {
            showPrompt(line, true);
        });
        await getStatus();
        await checkBlockStatus(type);
    } catch (error) {
        console.error(errorMessage, error);
        showPrompt(errorPrompt, false);
    }
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
        prompt.classList.add('visible');
        prompt.classList.remove('hidden');
        window.promptTimeout = setTimeout(() => {
            prompt.classList.remove('visible');
            prompt.classList.add('hidden');
        }, duration);
    }, 100);
}

// Function to attach add button elent listener
function attachAddButtonListeners() {
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

// Function to handle add whitelist/blacklist
async function handleAdd(fileType) {
    const inputElement = document.getElementById(`${fileType}-input`);
    const inputValue = inputElement.value.trim();
    console.log(`Input value for ${fileType}: "${inputValue}"`);
    if (inputValue === "") {
        console.error("Input is empty. Skipping add operation.");
        return;
    }
    try {
        await execCommand(`sh /data/adb/modules/Re-Malwack/rmlwk.sh --${fileType} add ${inputValue}`);
        console.log(`${fileType}ed "${inputValue}" successfully.`);
        showPrompt(`${fileType}ed ${inputValue} successfully.`, true);
        inputElement.value = "";
        await loadFile(fileType);
        await getStatus();
    } catch (error) {
        console.log(`Fail to ${fileType} "${inputValue}": ${error}`);
        showPrompt(`Fail to ${fileType} ${inputValue}`, false);
    }
}

// Execute shell commands
async function execCommand(command) {
    return new Promise((resolve, reject) => {
        const callbackName = `exec_callback_${Date.now()}`;
        window[callbackName] = (errno, stdout, stderr) => {
            delete window[callbackName];
            if (errno === 0) {
                resolve(stdout);
            } else {
                console.error(`Error executing command: ${stderr}`);
                reject(stderr);
            }
        };
        try {
            ksu.exec(command, "{}", callbackName);
        } catch (error) {
            console.error(`Execution error: ${error}`);
            reject(error);
        }
    });
}

// Prevent input box blocked by keyboard
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

// Link redirect
links.forEach(link => {
    link.element.addEventListener("click", async () => {
        try {
            await execCommand(`am start -a android.intent.action.VIEW -d ${link.url}`);
        } catch (error) {
            console.error(`Error opening ${link.name} link:`, error);
        }
    });
});

// Function to apply ripple effect
function applyRippleEffect() {
    rippleClasses.forEach(selector => {
        document.querySelectorAll(selector).forEach(element => {
            if (element.dataset.rippleListener !== "true") {
                element.addEventListener("pointerdown", function (event) {
                    if (isScrolling) return;
                    if (modeActive) return;

                    const ripple = document.createElement("span");
                    ripple.classList.add("ripple");

                    // Calculate ripple size and position
                    const rect = element.getBoundingClientRect();
                    const width = rect.width;
                    const size = Math.max(rect.width, rect.height);
                    const x = event.clientX - rect.left - size / 2;
                    const y = event.clientY - rect.top - size / 2;

                    // Determine animation duration
                    let duration = 0.3 + (width / 800) * 0.3;
                    duration = Math.min(0.8, Math.max(0.2, duration));

                    // Set ripple styles
                    ripple.style.width = ripple.style.height = `${size}px`;
                    ripple.style.left = `${x}px`;
                    ripple.style.top = `${y}px`;
                    ripple.style.animationDuration = `${duration}s`;
                    ripple.style.transition = `opacity ${duration}s ease`;

                    // Adaptive color
                    const computedStyle = window.getComputedStyle(element);
                    const bgColor = computedStyle.backgroundColor || "rgba(0, 0, 0, 0)";
                    const textColor = computedStyle.color;
                    const isDarkColor = (color) => {
                        const rgb = color.match(/\d+/g);
                        if (!rgb) return false;
                        const [r, g, b] = rgb.map(Number);
                        return (r * 0.299 + g * 0.587 + b * 0.114) < 96; // Luma formula
                    };
                    ripple.style.backgroundColor = isDarkColor(bgColor) ? "rgba(255, 255, 255, 0.2)" : "";

                    // Append ripple and handle cleanup
                    element.appendChild(ripple);
                    const handlePointerUp = () => {
                        ripple.classList.add("end");
                        setTimeout(() => {
                            ripple.classList.remove("end");
                            ripple.remove();
                        }, duration * 1000);
                        element.removeEventListener("pointerup", handlePointerUp);
                        element.removeEventListener("pointercancel", handlePointerUp);
                    };
                    element.addEventListener("pointerup", handlePointerUp);
                    element.addEventListener("pointercancel", handlePointerUp);
                });
                element.dataset.rippleListener = "true";
            }
        });
    });
}

// Function to read a file and display its content in the UI
async function loadFile(fileType) {
    try {
        const content = await execCommand(`cat ${filePaths[fileType]}`);
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
                <button class="delete-btn ripple-container">
                    <svg xmlns="http://www.w3.org/2000/svg" height="20px" viewBox="0 -960 960 960" width="20px" fill="#FFFFFF"><path d="M312-144q-29.7 0-50.85-21.15Q240-186.3 240-216v-480h-48v-72h192v-48h192v48h192v72h-48v479.57Q720-186 698.85-165T648-144H312Zm72-144h72v-336h-72v336Zm120 0h72v-336h-72v336Z"/></svg>
                </button>
            `;
            listElement.appendChild(listItem);
            listItem.querySelector(".delete-btn").addEventListener("click", () => removeLine(fileType, line));
        });
        applyRippleEffect();
    } catch (error) {
        console.error(`Failed to load ${fileType} file:`, error);
    }
}

// Function to remove a line from whitelist/blacklist/custom-source
async function removeLine(fileType, line) {
    try {
        await execCommand(`sh /data/adb/modules/Re-Malwack/rmlwk.sh --${fileType} remove ${line}`);
        showPrompt(`Removed ${line} from ${fileType}`, true);
        await loadFile(fileType);
        await getStatus();
    } catch (error) {
        console.error(`Failed to remove line from ${fileType}:`, error);
        showPrompt(`Failed to remove ${line} from ${fileType}`, false);
    }
}

// Initial load
document.addEventListener('DOMContentLoaded', async () => {
    checkMMRL();
    document.getElementById("about-button").addEventListener("click", aboutMenu);
    document.getElementById("update").addEventListener("click", updateHostsFile);
    document.getElementById("reset").addEventListener("click", resetHostsFile);
    document.getElementById("export-logs").addEventListener("click", exportLogs);
    blockTypes.forEach(type => {
        document.getElementById(`block-${type.id}`).addEventListener("click", () => handleBlock(type));
    });
    attachAddButtonListeners();
    getVersion();
    for (const type of blockTypes) {
        await checkBlockStatus(type);
    }
    applyRippleEffect();
    await loadFile('whitelist');
    await loadFile('blacklist');
    await loadFile('custom-source');
});
