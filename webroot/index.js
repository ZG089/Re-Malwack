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

// Link redirect
const links = [
    { element: telegramLink, url: 'https://t.me/Re_Malwack', name: 'Telegram' },
    { element: githubLink, url: 'https://github.com/ZG089/Re-Malwack', name: 'GitHub' },
    { element: xdaLink, url: 'https://xdaforums.com/t/re-malwack-revival-of-malwack-module.4690049/', name: 'XDA' },
    { element: sponsorLink, url: 'https://buymeacoffee.com/zg089', name: 'Sponsor' }
];

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
        const command = "grep '^version=' /data/adb/modules/Re-Malwack/module.prop | cut -d'=' -f2";
        const version = await execCommand(command);
        document.getElementById('version-text').textContent = `${version} | `;
    } catch (error) {
        console.error("Failed to read version from module.prop:", error);
    }
}

// Function to get working status
async function getStatus() {
    try {
        await execCommand("grep -q '0.0.0.0' /system/etc/hosts");
        document.getElementById('status-text').textContent = "Protection is enabled ✅";
    } catch (error) {
        console.error("Failed to check status:", error);
        document.getElementById('status-text').textContent = "Ready 🟡";
    }
}

// Function to check block porn sites status
async function blockPornStatus() {
    try {
        const result = await execCommand("su -c 'grep -q '^block_porn=1' /data/adb/Re-Malwack/config.sh'");
        blockPornToggle.checked = !result;
    } catch (error) {
        blockPornToggle.checked = false;
        console.error('Error checking block porn status:', error);
    }
}

// Function to check block gambling sites status
async function blockGamblingStatus() {
    try {
        const result = await execCommand("su -c 'grep -q '^block_gambling=1' /data/adb/Re-Malwack/config.sh'");
        blockGamblingToggle.checked = !result;
    } catch (error) {
        blockGamblingToggle.checked = false;
        console.error('Error checking block gambling status:', error);
    }
}

// Function to check block fakenews sites status
async function blockFakenewsStatus() {
    try {
        const result = await execCommand("su -c 'grep -q '^block_fakenews=1' /data/adb/Re-Malwack/config.sh'");
        blockFakenewsToggle.checked = !result;
    } catch (error) {
        blockFakenewsToggle.checked = false;
        console.error('Error checking block fakenews status:', error);
    }
}

// Function to handle peform script and output
async function performAction(promptMessage, commandOption, errorPrompt, errorMessage) {
    try {
        showPrompt(promptMessage, true, 50000);
        await new Promise(resolve => setTimeout(resolve, 300));
        const command = `su -c '/data/adb/modules/Re-Malwack/system/bin/rmlwk ${commandOption}'`;
        const output = await execCommand(command);
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

// Function to block pornography sites
async function blockPorn() {
    let prompt_message;
    let action;
    if (blockPornToggle.checked) {
        prompt_message = "- Removing entries...";
        action = "--block-porn 0";
    } else {
        prompt_message = "- Downloading entries for porn sites block...";
        action = "--block-porn";
    }
    await performAction(prompt_message, action, "- Failed to download porn block hosts", "Failed to download porn block hosts:");
    blockPornStatus();
}

// Function to block gambling sites
async function blockGambling() {
    let prompt_message;
    let action;
    if (blockGamblingToggle.checked) {
        prompt_message = "- Removing entries...";
        action = "--block-gambling 0";
    } else {
        prompt_message = "- Downloading entries for gambling sites block...";
        action = "--block-gambling";
    }
    await performAction(prompt_message, action, "- Failed to download gambling block hosts", "Failed to download gambling block hosts:");
    blockGamblingStatus();
}

// Function to block fake news sites
async function blockFakeNews() {
    let prompt_message;
    let action;
    if (blockFakenewsToggle.checked) {
        prompt_message = "- Removing entries...";
        action = "--block-fakenews 0";
    } else {
        prompt_message = "- Downloading entries for faknews sites block...";
        action = "--block-fakenews";
    }
    await performAction(prompt_message, action, "- Failed to download fake news block hosts", "Failed to download fake news block hosts:");
    blockFakenewsStatus();
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

    document.getElementById("whitelist-add").addEventListener("click", () => handleAdd("whitelist"));
    document.getElementById("blacklist-add").addEventListener("click", () => handleAdd("blacklist"));
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
        await execCommand(`su -c '/data/adb/modules/Re-Malwack/system/bin/rmlwk --${fileType} ${inputValue}'`);
        console.log(`${fileType}ed "${inputValue}" successfully.`);
        showPrompt(`${fileType}ed ${inputValue} successfully.`, true);
        inputElement.value = "";
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

// Function to handle input focus
function handleFocus(event) {
    setTimeout(() => {
        document.body.classList.add(focusClass);
        event.target.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }, 100);
}

// Function to handle input blur
function handleBlur() {
    setTimeout(() => {
        document.body.classList.remove(focusClass);
    }, 100);
}

// Add event listeners to each input
inputs.forEach(input => {
    input.addEventListener('focus', handleFocus);
    input.addEventListener('blur', handleBlur);
});

// Link redirect
links.forEach(link => {
    link.element.addEventListener('click', async () => {
        try {
            await execCommand(`am start -a android.intent.action.VIEW -d ${link.url}`);
        } catch (error) {
            console.error(`Error opening ${link.name} link:`, error);
        }
    });
});

// Initial load
document.addEventListener('DOMContentLoaded', async () => {
    document.getElementById("about-button").addEventListener("click", aboutMenu);
    document.getElementById("update").addEventListener("click", updateHostsFile);
    document.getElementById("reset").addEventListener("click", resetHostsFile);
    document.getElementById("block-porn").addEventListener("click", blockPorn);
    document.getElementById("block-gambling").addEventListener("click", blockGambling);
    document.getElementById("block-fake").addEventListener("click", blockFakeNews);
    attachAddButtonListeners();
    getVersion();
    getStatus();
    blockPornStatus();
    blockGamblingStatus()
    blockFakenewsStatus()
});
