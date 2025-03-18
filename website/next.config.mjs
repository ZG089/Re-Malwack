/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  basePath: '',
  images: {
    unoptimized: true,
  },
  // This ensures CSS is properly included
  webpack: (config) => {
    return config;
  },
  // Disable trailing slash to fix asset loading
  trailingSlash: false,
  // Ensure assets are properly referenced
  assetPrefix: './',
};

export default nextConfig;
