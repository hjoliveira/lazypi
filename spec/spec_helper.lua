-- spec_helper.lua
-- Mocks for World of Warcraft API functions used by LazyPI

-- Mock global state
_G.mockState = {
    printedMessages = {},
    macros = {},
    events = {},
    scripts = {},
    mouseoverUnit = nil,
    isMouseoverPlayer = true,
    isMouseoverFriendly = true,
    numMacros = 0,
}

-- Reset all mock state
function _G.resetMockState()
    _G.mockState = {
        printedMessages = {},
        macros = {},
        events = {},
        scripts = {},
        mouseoverUnit = nil,
        isMouseoverPlayer = true,
        isMouseoverFriendly = true,
        numMacros = 0,
    }
    -- Reset SlashCmdList
    _G.SlashCmdList = {}
    _G.SLASH_LAZYPI1 = nil
    _G.SLASH_LAZYPI2 = nil
    -- Reset frame globals
    _G.LazyPIFrame = nil
    _G.LazyPI = nil
end

-- Mock print function
_G.print = function(...)
    local args = {...}
    local message = table.concat(args, " ")
    table.insert(_G.mockState.printedMessages, message)
end

-- Mock MAX_ACCOUNT_MACROS constant
_G.MAX_ACCOUNT_MACROS = 120

-- Mock UnitName
function _G.UnitName(unit)
    if unit == "mouseover" then
        return _G.mockState.mouseoverUnit
    elseif unit == "player" then
        return "TestPlayer"
    end
    return nil
end

-- Mock UnitIsPlayer
function _G.UnitIsPlayer(unit)
    if unit == "mouseover" then
        return _G.mockState.isMouseoverPlayer
    end
    return false
end

-- Mock UnitIsFriend
function _G.UnitIsFriend(unit1, unit2)
    if unit2 == "mouseover" then
        return _G.mockState.isMouseoverFriendly
    end
    return false
end

-- Mock GetMacroIndexByName
function _G.GetMacroIndexByName(name)
    for i, macro in ipairs(_G.mockState.macros) do
        if macro.name == name then
            return i
        end
    end
    return 0
end

-- Mock GetNumMacros
function _G.GetNumMacros()
    return _G.mockState.numMacros, 0
end

-- Mock EditMacro
function _G.EditMacro(index, name, icon, body)
    if _G.mockState.macros[index] then
        _G.mockState.macros[index].name = name or _G.mockState.macros[index].name
        _G.mockState.macros[index].icon = icon or _G.mockState.macros[index].icon
        _G.mockState.macros[index].body = body
    end
end

-- Mock CreateMacro
function _G.CreateMacro(name, icon, body, perCharacter)
    local macro = {
        name = name,
        icon = icon,
        body = body,
        perCharacter = perCharacter
    }
    table.insert(_G.mockState.macros, macro)
    _G.mockState.numMacros = _G.mockState.numMacros + 1
    return #_G.mockState.macros
end

-- Mock Frame object
local function createMockFrame(frameType, frameName)
    local frame = {
        _name = frameName,
        _events = {},
        _scripts = {},
    }

    function frame:RegisterEvent(event)
        self._events[event] = true
        table.insert(_G.mockState.events, event)
    end

    function frame:UnregisterEvent(event)
        self._events[event] = nil
    end

    function frame:SetScript(scriptType, handler)
        self._scripts[scriptType] = handler
        _G.mockState.scripts[scriptType] = handler
    end

    function frame:GetScript(scriptType)
        return self._scripts[scriptType]
    end

    return frame
end

-- Mock CreateFrame
function _G.CreateFrame(frameType, frameName)
    local frame = createMockFrame(frameType, frameName)
    -- Register the frame globally like WoW does
    if frameName then
        _G[frameName] = frame
    end
    return frame
end

-- Mock SlashCmdList
_G.SlashCmdList = {}

-- Helper to load the addon
function _G.loadAddon()
    -- Reset state before loading
    _G.resetMockState()

    -- Simulate the addon loading environment
    local addonName = "LazyPI"
    local addon = {}

    -- Load Core.lua with the addon environment
    local chunk, err = loadfile("LazyPI/Core.lua")
    if not chunk then
        error("Failed to load Core.lua: " .. tostring(err))
    end

    -- Call with addon name and table as varargs
    chunk(addonName, addon)

    return addon
end

-- Helper to simulate an event
function _G.simulateEvent(event, ...)
    local handler = _G.mockState.scripts["OnEvent"]
    if handler then
        -- Get the frame from the global LazyPI
        local frame = _G.LazyPIFrame or {}
        handler(frame, event, ...)
    end
end

-- Helper to execute slash command
function _G.executeSlashCommand(msg)
    local handler = _G.SlashCmdList["LAZYPI"]
    if handler then
        handler(msg or "")
    end
end

-- Helper to get last printed message
function _G.getLastPrintedMessage()
    return _G.mockState.printedMessages[#_G.mockState.printedMessages]
end

-- Helper to check if message was printed
function _G.wasMessagePrinted(pattern)
    for _, msg in ipairs(_G.mockState.printedMessages) do
        if msg:match(pattern) then
            return true
        end
    end
    return false
end
