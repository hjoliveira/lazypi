-- LazyPI Settings Panel
-- Configuration UI with priority list and up/down arrows

local addonName, addon = ...

-- Settings frame reference
local settingsFrame = nil
local specRows = {}

-- Move a spec up or down in the priority list
local function MoveSpec(specID, direction)
    local order = LazyPIDB.specPriorityOrder
    local currentIndex = nil

    for i, id in ipairs(order) do
        if id == specID then
            currentIndex = i
            break
        end
    end

    if not currentIndex then return end

    local newIndex = currentIndex + direction
    if newIndex < 1 or newIndex > #order then return end

    -- Swap positions
    order[currentIndex], order[newIndex] = order[newIndex], order[currentIndex]

    -- Update display and macro
    addon:RefreshSettingsUI()
    addon:UpdateBestTarget()
end

-- Refresh the settings UI to reflect current order
function addon:RefreshSettingsUI()
    if not settingsFrame or not settingsFrame:IsShown() then return end

    local scrollChild = settingsFrame.scrollChild
    local rowHeight = 24
    local yOffset = 0

    -- Hide all existing rows first
    for _, row in pairs(specRows) do
        row:Hide()
    end

    -- Recreate rows in current priority order
    for i, specID in ipairs(LazyPIDB.specPriorityOrder) do
        local specInfo = addon.SpecInfo[specID]
        if specInfo then
            local row = specRows[specID]

            if not row then
                -- Create new row frame
                row = CreateFrame("Frame", nil, scrollChild)
                row:SetSize(360, rowHeight)

                -- Rank number
                row.rank = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.rank:SetPoint("LEFT", 5, 0)
                row.rank:SetWidth(30)
                row.rank:SetJustifyH("RIGHT")

                -- Spec name with class color
                row.specName = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.specName:SetPoint("LEFT", 45, 0)
                row.specName:SetWidth(180)
                row.specName:SetJustifyH("LEFT")

                -- Up button
                row.upBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                row.upBtn:SetSize(24, 20)
                row.upBtn:SetPoint("LEFT", row.specName, "RIGHT", 10, 0)
                row.upBtn:SetText("\226\150\178")  -- Unicode up triangle
                row.upBtn.specID = specID
                row.upBtn:SetScript("OnClick", function(self)
                    MoveSpec(self.specID, -1)
                end)

                -- Down button
                row.downBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                row.downBtn:SetSize(24, 20)
                row.downBtn:SetPoint("LEFT", row.upBtn, "RIGHT", 5, 0)
                row.downBtn:SetText("\226\150\188")  -- Unicode down triangle
                row.downBtn.specID = specID
                row.downBtn:SetScript("OnClick", function(self)
                    MoveSpec(self.specID, 1)
                end)

                specRows[specID] = row
            end

            -- Update row content
            local classColor = addon.ClassColors[specInfo.class]
            row.rank:SetText(i .. ".")
            row.specName:SetText(specInfo.name .. " " .. addon.ClassNames[specInfo.class])
            row.specName:SetTextColor(classColor.r, classColor.g, classColor.b)

            -- Enable/disable buttons based on position
            row.upBtn:SetEnabled(i > 1)
            row.downBtn:SetEnabled(i < #LazyPIDB.specPriorityOrder)

            -- Position and show row
            row:SetPoint("TOPLEFT", 10, -yOffset)
            row:Show()

            yOffset = yOffset + rowHeight
        end
    end

    -- Update scroll child height
    scrollChild:SetHeight(yOffset + 20)

    -- Update target display
    settingsFrame:UpdateTargetDisplay()
end

-- Create the main settings frame
local function CreateSettingsFrame()
    if settingsFrame then
        return settingsFrame
    end

    -- Main frame
    local frame = CreateFrame("Frame", "LazyPISettingsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(420, 550)
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
    title:SetText("LazyPI - Priority List")

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

    -- Update button
    local updateButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    updateButton:SetSize(120, 25)
    updateButton:SetPoint("TOPLEFT", 25, -85)
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
    instructions:SetPoint("TOPLEFT", 25, -120)
    instructions:SetWidth(370)
    instructions:SetJustifyH("LEFT")
    instructions:SetText("Use the arrows to reorder specs. Higher in the list = higher priority for Power Infusion.")

    -- Scroll frame for spec list
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -145)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 50)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(360, 1)  -- Height will be set dynamically
    scrollFrame:SetScrollChild(scrollChild)
    frame.scrollChild = scrollChild

    -- Current target display at bottom
    local targetLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    targetLabel:SetPoint("BOTTOMLEFT", 25, 20)
    targetLabel:SetText("Current Best Target:")

    local targetValue = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    targetValue:SetPoint("LEFT", targetLabel, "RIGHT", 10, 0)
    frame.targetValue = targetValue

    -- Update target display function
    function frame:UpdateTargetDisplay()
        if addon.bestTarget then
            local specInfo = addon.SpecInfo[addon.bestTarget.specID]
            local specName = specInfo and specInfo.name or "Unknown"
            local classColor = specInfo and addon.ClassColors[specInfo.class] or { r = 1, g = 1, b = 1 }
            self.targetValue:SetTextColor(classColor.r, classColor.g, classColor.b)
            self.targetValue:SetText(addon.bestTarget.name .. " (" .. specName .. ")")
        else
            self.targetValue:SetTextColor(0.5, 0.5, 0.5)
            self.targetValue:SetText("None")
        end
    end

    -- Refresh on show
    frame:SetScript("OnShow", function(self)
        addon:RefreshSettingsUI()
    end)

    frame:Hide()
    settingsFrame = frame

    return frame
end

-- Reset confirmation dialog
StaticPopupDialogs["LAZYPI_RESET_CONFIRM"] = {
    text = "Are you sure you want to reset priorities to defaults?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        -- Copy default order
        LazyPIDB.specPriorityOrder = {}
        for i, specID in ipairs(addon.DefaultPriorityOrder) do
            LazyPIDB.specPriorityOrder[i] = specID
        end
        addon:Print("Priorities reset to defaults!")
        addon:UpdateBestTarget()
        addon:RefreshSettingsUI()
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
local settingsLoader = CreateFrame("Frame")
settingsLoader:RegisterEvent("PLAYER_LOGIN")
settingsLoader:SetScript("OnEvent", function()
    -- Delayed registration to ensure all systems are ready
    C_Timer.After(1, function()
        if Settings and Settings.RegisterCanvasLayoutCategory then
            pcall(RegisterSettings)
        end
    end)
end)
