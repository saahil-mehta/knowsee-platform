import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  experimental: {
    optimizePackageImports: ["@copilotkit/react-ui", "@copilotkit/react-core"],
  },
};

export default nextConfig;
