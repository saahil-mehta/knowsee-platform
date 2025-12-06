import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone", // Required for Docker deployment
  experimental: {
    ppr: true,
  },
  images: {
    remotePatterns: [
      {
        hostname: "avatar.vercel.sh",
      },
      {
        protocol: "https",
        //https://nextjs.org/docs/messages/next-image-unconfigured-host
        hostname: "*.public.blob.vercel-storage.com",
      },
    ],
  },
  // Proxy API calls to Python backend in development
  // Skip proxy in test mode to use frontend mock models
  rewrites() {
    if (process.env.PLAYWRIGHT === "True") {
      return Promise.resolve([]);
    }

    return Promise.resolve([
      {
        source: "/api/chat",
        destination:
          process.env.NODE_ENV === "development"
            ? "http://127.0.0.1:8000/api/chat"
            : "/api/chat",
      },
    ]);
  },
};

export default nextConfig;
