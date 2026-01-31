-- LazyPI Settings Panel
-- Configuration UI for specialization priorities

local addonName, addon = ...

-- Settings frame reference
local settingsFrame = nil
local specSliders = {}

-- Create the main settings frame
local function CreateSettingsFrame()
    if settingsFrame then
        return settingsFrame
    end

    -- Main frame
    local frame = CreateFrame("Frame", "LazyPISettingsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(700, 600)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)

    -- Backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("LazyPI - Power Infusion Target Priority")

    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)

    -- Enable checkbox
    local enableCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    enableCheck:SetPoint("TOPLEFT", 25, -50)
    enableCheck.text = enableCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enableCheck.text:SetPoint("LEFT", enableCheck, "RIGHT", 5, 0)
    enableCheck.text:SetText("Enable LazyPI")
    enableCheck:SetScript("OnClick", function(self)
        LazyPIDB.enabled = self:GetChecked()
        if LazyPIDB.enabled then
            addon:UpdateBestTarget()
        end
    end)
    enableCheck:SetScript("OnShow", function(self)
        self:SetChecked(LazyPIDB.enabled)
    end)

    -- Auto-update checkbox
    local autoUpdateCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    autoUpdateCheck:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT", 0, 0)
    autoUpdateCheck.text = autoUpdateCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    autoUpdateCheck.text:SetPoint("LEFT", autoUpdateCheck, "RIGHT", 5, 0)
    autoUpdateCheck.text:SetText("Auto-update macro when group changes")
    autoUpdateCheck:SetScript("OnClick", function(self)
        LazyPIDB.autoUpdateMacro = self:GetChecked()
    end)
    autoUpdateCheck:SetScript("OnShow", function(self)
        self:SetChecked(LazyPIDB.autoUpdateMacro)
    end)

    -- Include self checkbox
    local includeSelfCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    includeSelfCheck:SetPoint("TOPLEFT", autoUpdateCheck, "BOTTOMLEFT", 0, 0)
    includeSelfCheck.text = includeSelfCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    includeSelfCheck.text:SetPoint("LEFT", includeSelfCheck, "RIGHT", 5, 0)
    includeSelfCheck.text:SetText("Include self as potential target (for Shadow Priests)")
    includeSelfCheck:SetScript("OnClick", function(self)
        LazyPIDB.includeSelf = self:GetChecked()
        addon:UpdateBestTarget()
    end)
    includeSelfCheck:SetScript("OnShow", function(self)
        self:SetChecked(LazyPIDB.includeSelf)
    end)

    -- Update button
    local updateButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    updateButton:SetSize(120, 25)
    updateButton:SetPoint("TOPLEFT", 350, -55)
    updateButton:SetText("Update Macro")
    updateButton:SetScript("OnClick", function()
        addon:RequestGroupInspect()
        C_Timer.After(1, function()
            addon:UpdateBestTarget()
            addon:Print("Macro updated!")
        end)
    end)

    -- Reset button
    local resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetButton:SetSize(120, 25)
    resetButton:SetPoint("LEFT", updateButton, "RIGHT", 10, 0)
    resetButton:SetText("Reset Defaults")
    resetButton:SetScript("OnClick", function()
        StaticPopup_Show("LAZYPI_RESET_CONFIRM")
    end)

    -- Instructions
    local instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instructions:SetPoint("TOPLEFT", 25, -135)
    instructions:SetWidth(650)
    instructions:SetJustifyH("LEFT")
    instructions:SetText("Set priority values for each specialization (0-100). Higher values = higher priority for Power Infusion. Specs with priority 0 will never be targeted.")

    -- Scroll frame for spec list
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -160)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 50)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(640, 1)  -- Height will be set dynamically
    scrollFrame:SetScrollChild(scrollChild)

    -- Create spec priority controls
    local yOffset = 0
    local columnWidth = 310
    local rowHeight = 28

    for classIndex, class in ipairs(addon.ClassOrder) do
        local classColor = addon.ClassColors[class]
        local className = addon.ClassNames[class]
        local specs = addon:GetSpecsByClass()[class]

        if specs and #specs > 0 then
            -- Class header
            local classHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            classHeader:SetPoint("TOPLEFT", 5, -yOffset)
            classHeader:SetTextColor(classColor.r, classColor.g, classColor.b)
            classHeader:SetText(className)

            yOffset = yOffset + 25

            -- Spec sliders (2 columns)
            for i, spec in ipairs(specs) do
                local column = ((i - 1) % 2)
                local xOffset = column * columnWidth

                if column == 0 and i > 1 then
                    yOffset = yOffset + rowHeight
                end

                -- Spec label
                local label = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                label:SetPoint("TOPLEFT", xOffset + 10, -yOffset)
                label:SetWidth(80)
                label:SetJustifyH("LEFT")
                label:SetText(spec.name)

                -- Role indicator
                local roleIcon = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                roleIcon:SetPoint("LEFT", label, "RIGHT", 2, 0)
                if spec.role == "TANK" then
                    roleIcon:SetText("|cFF0000FF[T]|r")
                elseif spec.role == "HEALER" then
                    roleIcon:SetText("|cFF00FF00[H]|r")
                else
                    roleIcon:SetText("|cFFFF0000[D]|r")
                end

                -- Slider
                local slider = CreateFrame("Slider", "LazyPISlider" .. spec.specID, scrollChild, "OptionsSliderTemplate")
                slider:SetPoint("LEFT", label, "RIGHT", 35, 0)
                slider:SetWidth(120)
                slider:SetMinMaxValues(0, 100)
                slider:SetValueStep(5)
                slider:SetObeyStepOnDrag(true)
                slider.specID = spec.specID

                -- Remove default text
                _G[slider:GetName() .. "Low"]:SetText("0")
                _G[slider:GetName() .. "High"]:SetText("100")
                _G[slider:GetName() .. "Text"]:SetText("")

                -- Value display
                local valueText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                valueText:SetPoint("LEFT", slider, "RIGHT", 10, 0)
                valueText:SetWidth(30)
                slider.valueText = valueText

                slider:SetScript("OnValueChanged", function(self, value)
                    value = math.floor(value)
                    self.valueText:SetText(value)
                    addon:SetSpecPriority(self.specID, value)
                end)

                slider:SetScript("OnShow", function(self)
                    local priority = addon:GetSpecPriority(self.specID) or 0
                    self:SetValue(priority)
                    self.valueText:SetText(math.floor(priority))
                end)

                specSliders[spec.specID] = slider
            end

            -- Move to next row after last spec if odd number
            if #specs % 2 == 1 then
                yOffset = yOffset + rowHeight
            else
                yOffset = yOffset + rowHeight
            end

            yOffset = yOffset + 10  -- Spacing between classes
        end
    end

    -- Set scroll child height
    scrollChild:SetHeight(yOffset + 20)

    -- Current target display at bottom
    local targetLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    targetLabel:SetPoint("BOTTOMLEFT", 25, 20)
    targetLabel:SetText("Current Best Target:")

    local targetValue = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    targetValue:SetPoint("LEFT", targetLabel, "RIGHT", 10, 0)
    frame.targetValue = targetValue

    -- Update target display
    frame:SetScript("OnShow", function(self)
        self:UpdateTargetDisplay()
    end)

    function frame:UpdateTargetDisplay()
        if addon.bestTarget then
            local specInfo = addon.SpecInfo[addon.bestTarget.specID]
            local specName = specInfo and specInfo.name or "Unknown"
            local classColor = specInfo and addon.ClassColors[specInfo.class] or { r = 1, g = 1, b = 1 }
            self.targetValue:SetTextColor(classColor.r, classColor.g, classColor.b)
            self.targetValue:SetText(addon.bestTarget.name .. " (" .. specName .. ", Priority: " .. addon.bestTarget.priority .. ")")
        else
            self.targetValue:SetTextColor(0.5, 0.5, 0.5)
            self.targetValue:SetText("None")
        end
    end

    -- Refresh sliders when shown
    frame:SetScript("OnShow", function(self)
        for specID, slider in pairs(specSliders) do
            local priority = addon:GetSpecPriority(specID) or 0
            slider:SetValue(priority)
            slider.valueText:SetText(math.floor(priority))
        end
        self:UpdateTargetDisplay()
    end)

    frame:Hide()
    settingsFrame = frame

    return frame
end

-- Reset confirmation dialog
StaticPopupDialogs["LAZYPI_RESET_CONFIRM"] = {
    text = "Are you sure you want to reset all priorities to defaults?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        for specID, info in pairs(addon.SpecInfo) do
            LazyPIDB.specPriorities[specID] = info.defaultPriority
        end
        addon:Print("Priorities reset to defaults!")
        addon:UpdateBestTarget()

        -- Refresh sliders
        if settingsFrame and settingsFrame:IsShown() then
            for specID, slider in pairs(specSliders) do
                local priority = addon:GetSpecPriority(specID) or 0
                slider:SetValue(priority)
                slider.valueText:SetText(math.floor(priority))
            end
            settingsFrame:UpdateTargetDisplay()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

-- Open settings panel
function addon:OpenSettings()
    local frame = CreateSettingsFrame()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

-- Register with Interface Options (modern API)
local function RegisterSettings()
    local category = Settings.RegisterCanvasLayoutCategory(CreateSettingsFrame(), "LazyPI")
    Settings.RegisterAddOnCategory(category)
    addon.settingsCategory = category
end

-- Try to register settings when addon loads
local settingsFrame = CreateFrame("Frame")
settingsFrame:RegisterEvent("PLAYER_LOGIN")
settingsFrame:SetScript("OnEvent", function()
    -- Delayed registration to ensure all systems are ready
    C_Timer.After(1, function()
        if Settings and Settings.RegisterCanvasLayoutCategory then
            pcall(RegisterSettings)
        end
    end)
end)
