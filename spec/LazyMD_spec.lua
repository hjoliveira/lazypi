-- LazyMD_spec.lua
-- Unit tests for LazyMD Core.lua

require("spec.spec_helper")

describe("LazyMD Addon", function()
    local addon

    before_each(function()
        addon = loadLazyMDAddon()
    end)

    describe("initialization", function()
        it("should set macro name to 'LazyMD'", function()
            assert.equal("LazyMD", addon.macroName)
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
            assert.equal("/lazymd", SLASH_LAZYMD1)
            assert.equal("/lmd", SLASH_LAZYMD2)
        end)

        it("should have slash command handler registered", function()
            assert.is_function(SlashCmdList["LAZYMD"])
        end)
    end)

    describe("Print function", function()
        it("should prefix messages with [LazyMD]", function()
            addon:Print("Test message")
            assert.is_true(wasMessagePrinted("%[LazyMD%]"))
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
                    -- Create the LazyMD macro first
                    CreateMacro("LazyMD", "ability_hunter_misdirection", "old body", false)
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
                        assert.equal("LazyMD", _G.mockState.macros[1].name)
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
                executeLazyMDSlashCommand("update")
                assert.is_true(wasMessagePrinted("No mouseover target"))
            end)

            it("should be case insensitive", function()
                _G.mockState.mouseoverUnit = nil
                executeLazyMDSlashCommand("UPDATE")
                assert.is_true(wasMessagePrinted("No mouseover target"))
            end)
        end)

        describe("status command", function()
            it("should show 'No target set' when no target", function()
                executeLazyMDSlashCommand("status")
                assert.is_true(wasMessagePrinted("No target set"))
            end)

            it("should show current target when set", function()
                addon.currentTarget = "TestTarget"
                executeLazyMDSlashCommand("status")
                assert.is_true(wasMessagePrinted("Current target: TestTarget"))
            end)
        end)

        describe("clear command", function()
            before_each(function()
                addon.currentTarget = "SomeTarget"
                CreateMacro("LazyMD", "ability_hunter_misdirection", "old body", false)
            end)

            describe("when in combat", function()
                it("should print combat warning", function()
                    _G.mockState.inCombat = true
                    executeLazyMDSlashCommand("clear")
                    assert.is_true(wasMessagePrinted("Cannot update macro during combat"))
                end)

                it("should not clear currentTarget", function()
                    _G.mockState.inCombat = true
                    executeLazyMDSlashCommand("clear")
                    assert.equal("SomeTarget", addon.currentTarget)
                end)

                it("should not modify the macro", function()
                    _G.mockState.inCombat = true
                    executeLazyMDSlashCommand("clear")
                    assert.equal("old body", _G.mockState.macros[1].body)
                end)
            end)

            it("should clear currentTarget", function()
                executeLazyMDSlashCommand("clear")
                assert.is_nil(addon.currentTarget)
            end)

            it("should reset macro to fallback", function()
                executeLazyMDSlashCommand("clear")
                assert.is_truthy(_G.mockState.macros[1].body:match("@mouseover"))
                assert.is_truthy(_G.mockState.macros[1].body:match("@target"))
                assert.is_truthy(_G.mockState.macros[1].body:match("@pet"))
                assert.is_truthy(_G.mockState.macros[1].body:match("@focus"))
            end)

            it("should print 'Target cleared' message", function()
                executeLazyMDSlashCommand("clear")
                assert.is_true(wasMessagePrinted("Target cleared"))
            end)
        end)

        describe("help command (default)", function()
            it("should show commands on empty input", function()
                executeLazyMDSlashCommand("")
                assert.is_true(wasMessagePrinted("Commands:"))
            end)

            it("should show commands on unknown input", function()
                executeLazyMDSlashCommand("unknown")
                assert.is_true(wasMessagePrinted("Commands:"))
            end)

            it("should list update command", function()
                executeLazyMDSlashCommand("help")
                assert.is_true(wasMessagePrinted("/lmd update"))
            end)

            it("should list status command", function()
                executeLazyMDSlashCommand("help")
                assert.is_true(wasMessagePrinted("/lmd status"))
            end)

            it("should list clear command", function()
                executeLazyMDSlashCommand("help")
                assert.is_true(wasMessagePrinted("/lmd clear"))
            end)
        end)
    end)

    describe("Event handling", function()
        describe("ADDON_LOADED", function()
            it("should print loaded message when LazyMD loads", function()
                simulateLazyMDEvent("ADDON_LOADED", "LazyMD")
                assert.is_true(wasMessagePrinted("Loaded"))
            end)

            it("should not print for other addons", function()
                _G.mockState.printedMessages = {}
                simulateLazyMDEvent("ADDON_LOADED", "OtherAddon")
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
                simulateLazyMDEvent("PLAYER_LOGIN")
                -- Should have created both LazyMD and LazyMD Update macros
                local foundLazyMD = false
                local foundLazyMDUpdate = false
                for _, macro in ipairs(_G.mockState.macros) do
                    if macro.name == "LazyMD" then foundLazyMD = true end
                    if macro.name == "LazyMD Update" then foundLazyMDUpdate = true end
                end
                assert.is_true(foundLazyMD)
                assert.is_true(foundLazyMDUpdate)
            end)
        end)
    end)

    describe("Macro body format", function()
        it("should include #showtooltip Misdirection", function()
            _G.mockState.mouseoverUnit = "TestPlayer"
            _G.mockState.isMouseoverPlayer = true
            _G.mockState.isMouseoverFriendly = true
            addon:UpdateMacroToMouseover()
            assert.is_truthy(_G.mockState.macros[1].body:match("#showtooltip Misdirection"))
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

        it("should include @pet fallback for when target is unavailable", function()
            _G.mockState.mouseoverUnit = "TestPlayer"
            _G.mockState.isMouseoverPlayer = true
            _G.mockState.isMouseoverFriendly = true
            addon:UpdateMacroToMouseover()
            assert.is_truthy(_G.mockState.macros[1].body:match("@pet"))
        end)

        it("should cast Misdirection spell", function()
            _G.mockState.mouseoverUnit = "TestPlayer"
            _G.mockState.isMouseoverPlayer = true
            _G.mockState.isMouseoverFriendly = true
            addon:UpdateMacroToMouseover()
            assert.is_truthy(_G.mockState.macros[1].body:match("Misdirection"))
        end)
    end)

    describe("Fallback macro format", function()
        it("should include mouseover, target, pet, and focus fallback chain", function()
            _G.mockState.numMacros = 0
            simulateLazyMDEvent("PLAYER_LOGIN")
            local mainMacro = nil
            for _, macro in ipairs(_G.mockState.macros) do
                if macro.name == "LazyMD" then mainMacro = macro end
            end
            assert.is_truthy(mainMacro)
            assert.is_truthy(mainMacro.body:match("@mouseover,help,nodead"))
            assert.is_truthy(mainMacro.body:match("@target,help,nodead"))
            assert.is_truthy(mainMacro.body:match("@pet,exists,nodead"))
            assert.is_truthy(mainMacro.body:match("@focus,help,nodead"))
            assert.is_truthy(mainMacro.body:match("Misdirection"))
        end)
    end)
end)
