import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { ProverbBoard } from "../components/proverb-board";

const sampleProverbs = [
  "CopilotKit composes UI the way chefs compose flavors.",
  "Agents that see the UI can steer the product.",
];

describe("ProverbBoard", () => {
  it("renders every proverb as a card", () => {
    render(<ProverbBoard proverbs={sampleProverbs} onRemove={() => {}} />);

    sampleProverbs.forEach((proverb) => {
      expect(screen.getByText(proverb)).toBeInTheDocument();
    });
  });

  it("shows an empty message when no proverbs exist", () => {
    render(<ProverbBoard proverbs={[]} onRemove={() => {}} />);

    expect(
      screen.getByText(/ask the assistant to add a proverb/i),
    ).toBeInTheDocument();
  });

  it("invokes the remove handler with the matching index", async () => {
    const user = userEvent.setup();
    const onRemove = vi.fn();
    render(<ProverbBoard proverbs={sampleProverbs} onRemove={onRemove} />);

    await user.click(screen.getAllByRole("button", { name: /remove proverb/i })[0]);

    expect(onRemove).toHaveBeenCalledWith(0);
  });
});
