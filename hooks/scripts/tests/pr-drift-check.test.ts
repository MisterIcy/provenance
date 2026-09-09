import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";

const execFileSyncMock = vi.fn();

vi.mock("node:child_process", () => ({
  execFileSync: (...args: unknown[]) => execFileSyncMock(...args),
}));

describe("pr-drift-check", () => {
  const originalEnv = process.env.CLAUDE_PLUGIN_OPTION_PR_SYNC_ENABLED;

  beforeEach(() => {
    execFileSyncMock.mockReset();
  });

  afterEach(() => {
    if (originalEnv === undefined) {
      delete process.env.CLAUDE_PLUGIN_OPTION_PR_SYNC_ENABLED;
    } else {
      process.env.CLAUDE_PLUGIN_OPTION_PR_SYNC_ENABLED = originalEnv;
    }
  });

  it("isGhAvailable returns false when gh is missing", async () => {
    execFileSyncMock.mockImplementation(() => {
      throw new Error("not found");
    });
    const { isGhAvailable } = await import("../pr-drift-check.ts");
    expect(isGhAvailable()).toBe(false);
  });

  it("isGhAvailable returns true when gh responds", async () => {
    execFileSyncMock.mockReturnValue("");
    const { isGhAvailable } = await import("../pr-drift-check.ts");
    expect(isGhAvailable()).toBe(true);
  });

  it("getOpenPrNumber returns null when there is no open PR", async () => {
    execFileSyncMock.mockReturnValue("\n");
    const { getOpenPrNumber } = await import("../pr-drift-check.ts");
    expect(getOpenPrNumber()).toBeNull();
  });

  it("getOpenPrNumber returns the PR number when one is open", async () => {
    execFileSyncMock.mockReturnValue("42\n");
    const { getOpenPrNumber } = await import("../pr-drift-check.ts");
    expect(getOpenPrNumber()).toBe("42");
  });

  it("getOpenPrNumber returns null when gh errors", async () => {
    execFileSyncMock.mockImplementation(() => {
      throw new Error("no PR");
    });
    const { getOpenPrNumber } = await import("../pr-drift-check.ts");
    expect(getOpenPrNumber()).toBeNull();
  });

  it("buildContext embeds the PR number and asks to invoke pr-description-sync", async () => {
    const { buildContext } = await import("../pr-drift-check.ts");
    const output = JSON.parse(buildContext("7"));
    expect(output.hookSpecificOutput.hookEventName).toBe("PostToolUse");
    expect(output.hookSpecificOutput.additionalContext).toContain("#7");
    expect(output.hookSpecificOutput.additionalContext).toContain("provenance:pr-description-sync");
  });
});
