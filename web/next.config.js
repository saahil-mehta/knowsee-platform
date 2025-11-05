/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',

  // API rewrites for development
  async rewrites() {
    return [
      {
        source: '/api/v1/:path*',
        destination: process.env.NEXT_PUBLIC_API_URL
          ? `${process.env.NEXT_PUBLIC_API_URL}/v1/:path*`
          : 'http://localhost:8000/v1/:path*',
      },
    ];
  },

  // Security headers
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
        ],
      },
    ];
  },

  // Experimental features
  experimental: {
    serverActions: {
      bodySizeLimit: '10mb',
    },
  },
};

module.exports = nextConfig;
