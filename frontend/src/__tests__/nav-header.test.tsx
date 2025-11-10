import { describe, it, expect, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import { NavHeader } from "@/components/nav-header";

// Mock next/navigation
vi.mock("next/navigation", () => ({
  useRouter: () => ({
    push: vi.fn(),
    refresh: vi.fn(),
  }),
}));

// Mock theme toggle
vi.mock("@/components/theme-toggle", () => ({
  ThemeToggle: () => <div data-testid="theme-toggle">Theme Toggle</div>,
}));

describe("NavHeader", () => {
  it("renders the application title 'Know'", () => {
    render(<NavHeader />);
    expect(screen.getByText("Know")).toBeInTheDocument();
  });

  it("renders the application title 'see'", () => {
    render(<NavHeader />);
    expect(screen.getByText("see")).toBeInTheDocument();
  });

  it("renders the new chat button", () => {
    render(<NavHeader />);
    expect(screen.getByText("New Chat")).toBeInTheDocument();
  });

  it("renders the theme toggle", () => {
    render(<NavHeader />);
    expect(screen.getByTestId("theme-toggle")).toBeInTheDocument();
  });
});
