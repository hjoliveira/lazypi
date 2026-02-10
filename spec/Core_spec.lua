-- Core_spec.lua
-- Unit tests for LazyPI Core.lua

require("spec.spec_helper")

describe("LazyPI Addon", function()
    local addon

    before_each(function()
        addon = loadAddon()
    end)

    describe("initialization", function()
        it("should set macro name to 'LazyPI'", function()
            assert.equal("LazyPI", addon.macroName)
        end)

        it("should initialize currentTarget as nil", function()
            assert.is_nil(addon.currentTarget)
        end)

        it("should register ADDON_LOADED event", function()
            assert.is_true(_G.mockState.events[1] == "ADDON_LOADED" or _G.mockState.events[2] == "ADDON_LOADED")
        end)

        it("should register PLAYER_LOGIN event", function()
            assert.is_true(_G.mockState.events[1] == "PLAYER_LOGIN" or _G.mockState.events[2] == "PLAYER_LOGIN")
        end)

        it("should register slash commands", function()
            assert.equal("/lazypi", SLASH_LAZYPI1)
            assert.equal("/lpi", SLASH_LAZYPI2)
        end)

        it("should have slash command handler registered", function()
            assert.is_function(SlashCmdList["LAZYPI"])
        end)
    end)

    describe("class detection", function()
        it("should configure Power Infusion for Priest", function()
            local priestAddon = loadAddon("PRIEST")
            assert.equal("Power Infusion", priestAddon.spellName)
            assert.equal("spell_holy_powerinfusion", priestAddon.spellIcon)
            assert.equal("@player", priestAddon.fallbackCondition)
        end)

        it("should configure Misdirection for Hunter", function()
            local hunterAddon = loadAddon("HUNTER")
            assert.equal("Misdirection", hunterAddon.spellName)
            assert.equal("ability_hunter_misdirection", hunterAddon.spellIcon)
            assert.equal("@pet,exists,nodead", hunterAddon.fallbackCondition)
        end)

        it("should default to Power Infusion for unknown classes", function()
            local otherAddon = loadAddon("MAGE")
            assert.equal("Power Infusion", otherAddon.spellName)
        end)
    end)

    describe("Print function", function()
        it("should prefix messages with [LazyPI]", function()
            addon:Print("Test message")
            assert.is_true(wasMessagePrinted("%[LazyPI%]"))
        end)

        it("should include the message content", function()
            addon:Print("Hello World")
            assert.is_true(wasMessagePrinted("Hello World"))
        end)
    end)

    describe("UpdateMacroToMouseover", function()
        describe("when in combat", function()
            before_each(function()
                _G.mockState.inCombat = true
                _G.mockState.mouseoverUnit = "FriendlyPlayer"
                _G.mockState.isMouseoverPlayer = true
                _G.mockState.isMouseoverFriendly = true
            end)

            it("should print combat warning", function()
                addon:UpdateMacroToMouseover()
                assert.is_true(wasMessagePrinted("Cannot update macro during combat"))
            end)

            it("should not set currentTarget", function()
                addon:UpdateMacroToMouseover()
                assert.is_nil(addon.currentTarget)
            end)

            it("should not create or edit macros", function()
                local initialCount = #_G.mockState.macros
                addon:UpdateMacroToMouseover()
                assert.equal(initialCount, #_G.mockState.macros)
            end)
        end)

        describe("when no mouseover target", function()
            it("should print 'No mouseover target'", function()
                _G.mockState.mouseoverUnit = nil
                addon:UpdateMacroToMouseover()
                assert.is_true(wasMessagePrinted("No mouseover target"))
            end)

            it("should not set currentTarget", function()
                _G.mockState.mouseoverUnit = nil
                addon:UpdateMacroToMouseover()
                assert.is_nil(addon.currentTarget)
            end)
        end)

        describe("when mouseover is not a player", function()
            it("should print 'Mouseover is not a player'", function()
                _G.mockState.mouseoverUnit = "SomeNPC"
                _G.mockState.isMouseoverPlayer = false
                addon:UpdateMacroToMouseover()
                assert.is_true(wasMessagePrinted("Mouseover is not a player"))
            end)

            it("should not set currentTarget", function()
                _G.mockState.mouseoverUnit = "SomeNPC"
                _G.mockState.isMouseoverPlayer = false
                addon:UpdateMacroToMouseover()
                assert.is_nil(addon.currentTarget)
            end)
        end)

        describe("when mouseover is not friendly", function()
            it("should print 'Mouseover is not friendly'", function()
                _G.mockState.mouseoverUnit = "EnemyPlayer"
                _G.mockState.isMouseoverPlayer = true
                _G.mockState.isMouseoverFriendly = false
                addon:UpdateMacroToMouseover()
                assert.is_true(wasMessagePrinted("Mouseover is not friendly"))
            end)

            it("should not set currentTarget", function()
                _G.mockState.mouseoverUnit = "EnemyPlayer"
                _G.mockState.isMouseoverPlayer = true
                _G.mockState.isMouseoverFriendly = false
                addon:UpdateMacroToMouseover()
                assert.is_nil(addon.currentTarget)
            end)
        end)

        describe("when mouseover is a valid friendly player", function()
            before_each(function()
                _G.mockState.mouseoverUnit = "FriendlyPlayer"
                _G.mockState.isMouseoverPlayer = true
                _G.mockState.isMouseoverFriendly = true
            end)

            describe("and macro already exists", function()
                before_each(function()
                    -- Create the LazyPI macro first
                    CreateMacro("LazyPI", "spell_holy_powerinfusion", "old body", false)
                end)

                it("should set currentTarget to the mouseover name", function()
                    addon:UpdateMacroToMouseover()
                    assert.equal("FriendlyPlayer", addon.currentTarget)
                end)

                it("should update the macro", function()
                    addon:UpdateMacroToMouseover()
                    assert.is_truthy(_G.mockState.macros[1].body:match("FriendlyPlayer"))
                end)

                it("should print 'Target set' message", function()
                    addon:UpdateMacroToMouseover()
                    assert.is_true(wasMessagePrinted("Target set: FriendlyPlayer"))
                end)
            end)

            describe("and macro does not exist", function()
                describe("and macro slots available", function()
                    it("should create a new macro", function()
                        addon:UpdateMacroToMouseover()
                        assert.equal(1, #_G.mockState.macros)
                        assert.equal("LazyPI", _G.mockState.macros[1].name)
                    end)

                    it("should set currentTarget", function()
                        addon:UpdateMacroToMouseover()
                        assert.equal("FriendlyPlayer", addon.currentTarget)
                    end)

                    it("should print 'Created macro for' message", function()
                        addon:UpdateMacroToMouseover()
                        assert.is_true(wasMessagePrinted("Created macro for: FriendlyPlayer"))
                    end)
                end)

                describe("and max macros reached", function()
                    before_each(function()
                        _G.mockState.numMacros = MAX_ACCOUNT_MACROS
                    end)

                    it("should print error about max macros", function()
                        addon:UpdateMacroToMouseover()
                        assert.is_true(wasMessagePrinted("maximum global macros reached"))
                    end)

                    it("should not create a macro", function()
                        local initialCount = #_G.mockState.macros
                        addon:UpdateMacroToMouseover()
                        assert.equal(initialCount, #_G.mockState.macros)
                    end)
                end)
            end)
        end)
    end)

    describe("Slash commands", function()
        describe("update command", function()
            it("should call UpdateMacroToMouseover", function()
                _G.mockState.mouseoverUnit = nil
                executeSlashCommand("update")
                assert.is_true(wasMessagePrinted("No mouseover target"))
            end)

            it("should be case insensitive", function()
                _G.mockState.mouseoverUnit = nil
                executeSlashCommand("UPDATE")
                assert.is_true(wasMessagePrinted("No mouseover target"))
            end)
        end)

        describe("status command", function()
            it("should show 'No target set' when no target", function()
                executeSlashCommand("status")
                assert.is_true(wasMessagePrinted("No target set"))
            end)

            it("should show current target when set", function()
                addon.currentTarget = "TestTarget"
                executeSlashCommand("status")
                assert.is_true(wasMessagePrinted("Current target: TestTarget"))
            end)
        end)

        describe("clear command", function()
            before_each(function()
                addon.currentTarget = "SomeTarget"
                CreateMacro("LazyPI", "spell_holy_powerinfusion", "old body", false)
            end)

            describe("when in combat", function()
                it("should print combat warning", function()
                    _G.mockState.inCombat = true
                    executeSlashCommand("clear")
                    assert.is_true(wasMessagePrinted("Cannot update macro during combat"))
                end)

                it("should not clear currentTarget", function()
                    _G.mockState.inCombat = true
                    executeSlashCommand("clear")
                    assert.equal("SomeTarget", addon.currentTarget)
                end)

                it("should not modify the macro", function()
                    _G.mockState.inCombat = true
                    executeSlashCommand("clear")
                    assert.equal("old body", _G.mockState.macros[1].body)
                end)
            end)

            it("should clear currentTarget", function()
                executeSlashCommand("clear")
                assert.is_nil(addon.currentTarget)
            end)

            it("should reset macro to fallback", function()
                executeSlashCommand("clear")
                assert.is_truthy(_G.mockState.macros[1].body:match("@mouseover"))
                assert.is_truthy(_G.mockState.macros[1].body:match("@target"))
                assert.is_truthy(_G.mockState.macros[1].body:match("@player"))
            end)

            it("should print 'Target cleared' message", function()
                executeSlashCommand("clear")
                assert.is_true(wasMessagePrinted("Target cleared"))
            end)
        end)

        describe("help command (default)", function()
            it("should show commands on empty input", function()
                executeSlashCommand("")
                assert.is_true(wasMessagePrinted("Commands:"))
            end)

            it("should show commands on unknown input", function()
                executeSlashCommand("unknown")
                assert.is_true(wasMessagePrinted("Commands:"))
            end)

            it("should list update command", function()
                executeSlashCommand("help")
                assert.is_true(wasMessagePrinted("/lpi update"))
            end)

            it("should list status command", function()
                executeSlashCommand("help")
                assert.is_true(wasMessagePrinted("/lpi status"))
            end)

            it("should list clear command", function()
                executeSlashCommand("help")
                assert.is_true(wasMessagePrinted("/lpi clear"))
            end)
        end)
    end)

    describe("Event handling", function()
        describe("ADDON_LOADED", function()
            it("should print loaded message when LazyPI loads", function()
                simulateEvent("ADDON_LOADED", "LazyPI")
                assert.is_true(wasMessagePrinted("Loaded"))
            end)

            it("should not print for other addons", function()
                _G.mockState.printedMessages = {}
                simulateEvent("ADDON_LOADED", "OtherAddon")
                local hasLoadedMessage = false
                for _, msg in ipairs(_G.mockState.printedMessages) do
                    if msg:match("Loaded") then
                        hasLoadedMessage = true
                    end
                end
                assert.is_false(hasLoadedMessage)
            end)
        end)

        describe("PLAYER_LOGIN", function()
            it("should create macros when slots available", function()
                _G.mockState.numMacros = 0
                simulateEvent("PLAYER_LOGIN")
                -- Should have created both LazyPI and LazyPI Update macros
                local foundLazyPI = false
                local foundLazyPIUpdate = false
                for _, macro in ipairs(_G.mockState.macros) do
                    if macro.name == "LazyPI" then foundLazyPI = true end
                    if macro.name == "LazyPI Update" then foundLazyPIUpdate = true end
                end
                assert.is_true(foundLazyPI)
                assert.is_true(foundLazyPIUpdate)
            end)
        end)
    end)

    describe("Macro body format (Priest)", function()
        it("should include #showtooltip Power Infusion", function()
            _G.mockState.mouseoverUnit = "TestPlayer"
            _G.mockState.isMouseoverPlayer = true
            _G.mockState.isMouseoverFriendly = true
            addon:UpdateMacroToMouseover()
            assert.is_truthy(_G.mockState.macros[1].body:match("#showtooltip Power Infusion"))
        end)

        it("should include target name in @playername format", function()
            _G.mockState.mouseoverUnit = "TestPlayer"
            _G.mockState.isMouseoverPlayer = true
            _G.mockState.isMouseoverFriendly = true
            addon:UpdateMacroToMouseover()
            assert.is_truthy(_G.mockState.macros[1].body:match("@TestPlayer"))
        end)

        it("should include help and nodead conditions", function()
            _G.mockState.mouseoverUnit = "TestPlayer"
            _G.mockState.isMouseoverPlayer = true
            _G.mockState.isMouseoverFriendly = true
            addon:UpdateMacroToMouseover()
            assert.is_truthy(_G.mockState.macros[1].body:match("help"))
            assert.is_truthy(_G.mockState.macros[1].body:match("nodead"))
        end)

        it("should include @player fallback for when target is unavailable", function()
            _G.mockState.mouseoverUnit = "TestPlayer"
            _G.mockState.isMouseoverPlayer = true
            _G.mockState.isMouseoverFriendly = true
            addon:UpdateMacroToMouseover()
            assert.is_truthy(_G.mockState.macros[1].body:match("@player"))
        end)
    end)
end)

describe("LazyPI Addon (Hunter)", function()
    local addon

    before_each(function()
        addon = loadAddon("HUNTER")
    end)

    describe("class configuration", function()
        it("should set spellName to Misdirection", function()
            assert.equal("Misdirection", addon.spellName)
        end)

        it("should set spellIcon to ability_hunter_misdirection", function()
            assert.equal("ability_hunter_misdirection", addon.spellIcon)
        end)

        it("should set fallbackCondition to @pet,exists,nodead", function()
            assert.equal("@pet,exists,nodead", addon.fallbackCondition)
        end)

        it("should include @focus in fallbackChain", function()
            assert.is_truthy(addon.fallbackChain:match("@focus"))
        end)
    end)

    describe("UpdateMacroToMouseover", function()
        describe("when in combat", function()
            it("should print combat warning", function()
                _G.mockState.inCombat = true
                _G.mockState.mouseoverUnit = "FriendlyPlayer"
                _G.mockState.isMouseoverPlayer = true
                _G.mockState.isMouseoverFriendly = true
                addon:UpdateMacroToMouseover()
                assert.is_true(wasMessagePrinted("Cannot update macro during combat"))
            end)
        end)

        describe("when mouseover is a valid friendly player", function()
            before_each(function()
                _G.mockState.mouseoverUnit = "TankPlayer"
                _G.mockState.isMouseoverPlayer = true
                _G.mockState.isMouseoverFriendly = true
            end)

            describe("and macro already exists", function()
                before_each(function()
                    CreateMacro("LazyPI", "ability_hunter_misdirection", "old body", false)
                end)

                it("should set currentTarget to the mouseover name", function()
                    addon:UpdateMacroToMouseover()
                    assert.equal("TankPlayer", addon.currentTarget)
                end)

                it("should update the macro with Misdirection", function()
                    addon:UpdateMacroToMouseover()
                    assert.is_truthy(_G.mockState.macros[1].body:match("Misdirection"))
                    assert.is_truthy(_G.mockState.macros[1].body:match("TankPlayer"))
                end)
            end)

            describe("and macro does not exist", function()
                it("should create a new macro with hunter icon", function()
                    addon:UpdateMacroToMouseover()
                    assert.equal(1, #_G.mockState.macros)
                    assert.equal("ability_hunter_misdirection", _G.mockState.macros[1].icon)
                end)
            end)
        end)
    end)

    describe("Macro body format (Hunter)", function()
        before_each(function()
            _G.mockState.mouseoverUnit = "TankPlayer"
            _G.mockState.isMouseoverPlayer = true
            _G.mockState.isMouseoverFriendly = true
        end)

        it("should include #showtooltip Misdirection", function()
            addon:UpdateMacroToMouseover()
            assert.is_truthy(_G.mockState.macros[1].body:match("#showtooltip Misdirection"))
        end)

        it("should include target name in @playername format", function()
            addon:UpdateMacroToMouseover()
            assert.is_truthy(_G.mockState.macros[1].body:match("@TankPlayer"))
        end)

        it("should include help and nodead conditions", function()
            addon:UpdateMacroToMouseover()
            assert.is_truthy(_G.mockState.macros[1].body:match("help"))
            assert.is_truthy(_G.mockState.macros[1].body:match("nodead"))
        end)

        it("should include @pet fallback instead of @player", function()
            addon:UpdateMacroToMouseover()
            assert.is_truthy(_G.mockState.macros[1].body:match("@pet"))
            assert.is_falsy(_G.mockState.macros[1].body:match("@player"))
        end)

        it("should cast Misdirection not Power Infusion", function()
            addon:UpdateMacroToMouseover()
            assert.is_truthy(_G.mockState.macros[1].body:match("Misdirection"))
            assert.is_falsy(_G.mockState.macros[1].body:match("Power Infusion"))
        end)
    end)

    describe("Fallback macro format (Hunter)", function()
        it("should include mouseover, target, pet, and focus in fallback chain", function()
            _G.mockState.numMacros = 0
            simulateEvent("PLAYER_LOGIN")
            local mainMacro = nil
            for _, macro in ipairs(_G.mockState.macros) do
                if macro.name == "LazyPI" then mainMacro = macro end
            end
            assert.is_truthy(mainMacro)
            assert.is_truthy(mainMacro.body:match("@mouseover,help,nodead"))
            assert.is_truthy(mainMacro.body:match("@target,help,nodead"))
            assert.is_truthy(mainMacro.body:match("@pet,exists,nodead"))
            assert.is_truthy(mainMacro.body:match("@focus,help,nodead"))
            assert.is_truthy(mainMacro.body:match("Misdirection"))
        end)

        it("should use hunter icon for fallback macro", function()
            _G.mockState.numMacros = 0
            simulateEvent("PLAYER_LOGIN")
            local mainMacro = nil
            for _, macro in ipairs(_G.mockState.macros) do
                if macro.name == "LazyPI" then mainMacro = macro end
            end
            assert.equal("ability_hunter_misdirection", mainMacro.icon)
        end)
    end)

    describe("clear command (Hunter)", function()
        before_each(function()
            addon.currentTarget = "SomeTarget"
            CreateMacro("LazyPI", "ability_hunter_misdirection", "old body", false)
        end)

        it("should reset macro to hunter fallback", function()
            executeSlashCommand("clear")
            assert.is_truthy(_G.mockState.macros[1].body:match("@mouseover"))
            assert.is_truthy(_G.mockState.macros[1].body:match("@target"))
            assert.is_truthy(_G.mockState.macros[1].body:match("@pet"))
            assert.is_truthy(_G.mockState.macros[1].body:match("@focus"))
            assert.is_truthy(_G.mockState.macros[1].body:match("Misdirection"))
        end)

        it("should not include @player in hunter fallback", function()
            executeSlashCommand("clear")
            assert.is_falsy(_G.mockState.macros[1].body:match("@player"))
        end)
    end)
end)
