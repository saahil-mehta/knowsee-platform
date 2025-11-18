import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  experimental: {
    optimizePackageImports: ["@copilotkit/react-ui", "@copilotkit/react-core"],
  },
};

export default nextConfig;
