// totalDownloads.js

const https = require('https');

const repoOwner = 'ZG089';
const repoName = 'Re-Malwack';
const apiUrl = `https://api.github.com/repos/${repoOwner}/${repoName}/releases`;

function fetchReleases(url) {
  return new Promise((resolve, reject) => {
    https.get(url, {
      headers: { 'User-Agent': 'node.js' }
    }, res => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', reject);
  });
}

async function getTotalDownloads() {
  try {
    const releases = await fetchReleases(apiUrl);
    let total = 0;
    releases.forEach(release => {
      release.assets.forEach(asset => {
        total += asset.download_count;
      });
    });
    console.log(`Total Downloads: ${total}`);
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

getTotalDownloads();
