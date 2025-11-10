import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { ThemePanel } from "../components/theme-panel";

describe("ThemePanel", () => {
  it("renders the current color chip", () => {
    render(<ThemePanel themeColor="#123456" onThemeChange={() => {}} />);

    const colorPreview = screen.getByTestId("theme-preview");
    expect(colorPreview).toHaveStyle({ backgroundColor: "#123456" });
  });

  it("notifies listeners when the color input changes", async () => {
    const user = userEvent.setup();
    const onThemeChange = vi.fn();
    render(<ThemePanel themeColor="#123456" onThemeChange={onThemeChange} />);

    const input = screen.getByLabelText(/accent color/i) as HTMLInputElement;
    await user.type(input, "#ffffff");

    expect(onThemeChange).toHaveBeenCalled();
  });
});
