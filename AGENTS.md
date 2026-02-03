# Agent Guidelines for LazyPI

This document provides instructions for AI agents working on this codebase.

## Project Overview

LazyPI is a World of Warcraft addon for Priests to simplify Power Infusion macro management. The main code is in `LazyPI/Core.lua`.

## Installing Lua and Busted

### On Ubuntu/Debian

```bash
# Install Lua 5.4 and LuaRocks
sudo apt-get update
sudo apt-get install -y lua5.4 liblua5.4-dev luarocks

# Install busted testing framework
sudo luarocks install busted
```

### On macOS

```bash
# Using Homebrew
brew install lua luarocks

# Install busted
luarocks install busted
```

### On Windows

1. Download and install Lua from https://www.lua.org/download.html
2. Install LuaRocks from https://luarocks.org/
3. Run: `luarocks install busted`

## Running Tests

From the repository root directory, run:

```bash
busted --verbose
```

Or simply:

```bash
busted
```

The tests are located in the `spec/` directory and use the busted testing framework with mocked WoW API functions.

## Test Requirements

**Tests must be run after making any code change.**

Before committing changes:

1. Run `busted --verbose` to execute all tests
2. Ensure all tests pass (exit code 0)
3. If tests fail, fix the issues before committing

The GitHub Actions workflow will automatically run tests on all pushes and pull requests. PRs with failing tests should not be merged.

## Project Structure

```
lazypi/
├── .busted              # Busted configuration
├── .github/
│   └── workflows/
│       └── check.yml    # CI workflow that runs tests
├── AGENTS.md            # This file
├── LazyPI/
│   ├── Core.lua         # Main addon code
│   └── LazyPI.toc       # WoW addon manifest
├── LICENSE
├── README.md
└── spec/
    ├── spec_helper.lua  # Test helpers and WoW API mocks
    └── Core_spec.lua    # Unit tests for Core.lua
```

## Writing Tests

Tests are written using the [busted](https://lunarmodules.github.io/busted/) framework. The `spec/spec_helper.lua` file provides:

- Mocked WoW API functions (UnitName, CreateFrame, CreateMacro, etc.)
- Helper functions for loading the addon in a test environment
- Utilities for simulating events and slash commands

Example test structure:

```lua
require("spec.spec_helper")

describe("Feature", function()
    local addon

    before_each(function()
        addon = loadAddon()
    end)

    it("should do something", function()
        -- Test code
        assert.is_true(condition)
    end)
end)
```

## Mocked WoW API

The following WoW API functions are mocked in `spec_helper.lua`:

- `CreateFrame()` - Creates mock frame objects
- `UnitName()` - Returns mock unit names
- `UnitIsPlayer()` - Checks if unit is a player
- `UnitIsFriend()` - Checks if unit is friendly
- `GetMacroIndexByName()` - Gets macro index
- `GetNumMacros()` - Returns macro count
- `CreateMacro()` - Creates a mock macro
- `EditMacro()` - Edits a mock macro
- `print()` - Captures printed messages

Use `_G.mockState` to configure test scenarios and `_G.resetMockState()` to reset between tests.
