import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["hooks/scripts/tests/**/*.test.ts"],
  },
});
