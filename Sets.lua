GearRenterSets = LibStub("AceAddon-3.0"):NewAddon("Gear Renter Sets", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

local Slots = {
    [1] = "HeadSlot",
    [3] = "ShoulderSlot",
    [15] = "BackSlot",
    [5] = "ChestSlot",
    [9] = "WristSlot",
    [10] = "HandsSlot",
    [6] = "WaistSlot",
    [7] = "LegsSlot",
    [8] = "FeetSlot",
    [16] = "MainHandSlot",
    [17] = "SecondaryHandSlot",
}
local iSlots = { 1, 3, 15, 5, 9, 10, 6, 7, 8, 16, 17 }

function GearRenterSets:Initialize()
    self.db = {
      sets = {}
    }

    --self.tooltip = CreateFrame("GameTooltip", "GearRenterSetsTooltip", UIParent, "GameTooltipTemplate")

    self.frame = GearRenterSets:Create()
    self:UpdateTree(self.frame.tree)
    if self.db.selected and self.db.sets[self.db.selected] then
        self.frame.tree:SelectByValue(self.db.selected)
    elseif next(self.db.sets) then
        self.db.selected = next(self.db.sets)
        self.frame.tree:SelectByValue(self.db.selected)
    else
        self.db.selected = nil
        self:UpdateRightPanel()
    end
    
    SLASH_GearRenterSets1 = "/trs";
    SLASH_GearRenterSets2 = "/GearRenterSets";
    SlashCmdList["GearRenterSets"] = GearRenterSets.SlashCmd
end

function GearRenterSets:SaveCurrent()
    local t = {}
    for slotID in pairs(Slots) do
        local isTransmogrified, canTransmogrify, cannotTransmogrifyReason,
            hasPending, hasUndo, srcItemID, texture = GetTransmogrifySlotInfo(slotID)
        if isTransmogrified then
            t[slotID] = srcItemID
            if hasUndo then t[slotID] = false end
        end
    end
    return t
end

function GearRenterSets:PickupItemByID(itemID, in_bank)
    local container, slot = self:FindItemByID(itemID, in_bank)
    if container then
        PickupContainerItem(container, slot);
        return true
    end
    return false
end

local itemTable = {}

function GearRenterSets:LoadSet(setName)
    
end

function GearRenterSets:SaveSet()
    local label = self.frame.top.label
    local name = label:GetText()
    if not name or name == "" then return end
    self.db.sets[name] = self:SaveCurrent()
    self.db.selected = name
    self:UpdateTree()
    self.frame.tree:SelectByValue(name)
end

function GearRenterSets:DeleteSet(name)
    if not name or name == "" then name = self.db.selected end
    self.db.sets[name] = nil
    if self.db.selected == name then
        local newset = next(self.db.sets)
        if newset then
            self.frame.tree:SelectByValue(newset)
        else
            self:UpdateRightPanel()
        end
        self.db.selected = newset
    end
    self:UpdateTree()
end


function GearRenterSets.SlashCmd(msg)
    GearRenterSets.frame:Show()
end

function GearRenterSets:UpdateTree()
    local sets = self.db.sets
    local treegroup = self.frame.tree
    local t = {}
    for name,set in pairs(sets) do
        local iconItemID = set[3] or select(2, next(set))
        local icon = GetItemIcon(iconItemID)
        table.insert(t, { value = name, text = name, icon = icon })
    end
    treegroup:SetTree(t)
end

function GearRenterSets:UpdateRightPanel(group)
    if group then self.db.selected = group end
    local rpane = self.frame.rpane
    local set
    if self.db.selected and self.db.sets[self.db.selected]  then
        -- self.frame.tree:SelectByValue(self.db.selected)
        set = self.db.sets[self.db.selected] 
        self.frame.top.label:SetText(self.db.selected)
    else
        self.frame.top.label:SetText("NewSet1")
        set = {}
    end
    for slotID, label in pairs(rpane.itemlabels) do
        if set[slotID] == nil then
            label:SetImage("Interface\\Icons\\Spell_Shadow_SacrificialShield")
            label:SetText("None")
            label:SetColor(0.5,0.5,0.5)
        elseif set[slotID] == false then
            label:SetImage("Interface\\Icons\\INV_Enchant_EssenceCosmicGreater")
            label:SetText("<Undo>")
            label:SetColor(0.2,0.8,0.2)
        else
            local itemID = set[slotID]
            local name, link, quality, _, _, _, _, _, _, texture = GetItemInfo(itemID) 
            label.itemLink = link
            label:SetImage(texture)
            label:SetText(name)
            label:SetColor(GetItemQualityColor(quality or 1))

            label:SetScript("OnEnter", Item_OnEnter)
            label:SetScript("OnLeave", Item_OnLeave)
            label.UpdateTooltip = Item_OnEnter
        end
    end

end


function GearRenterSets:Create()
    local AceGUI = LibStub("AceGUI-3.0")
    -- Create a container frame
    local Frame = AceGUI:Create("Frame")
    Frame:SetTitle("GearRenter Sets")
    Frame:SetWidth(500)
    Frame:SetHeight(440)
    Frame:EnableResize(false)
    -- f:SetStatusText("Status Bar")
    Frame:SetLayout("Flow")

    local topgroup = AceGUI:Create("SimpleGroup")
    topgroup:SetFullWidth(true)
    -- topgroup:SetHeight(0)
    topgroup:SetLayout("Flow")
    Frame:AddChild(topgroup)
    Frame.top = topgroup

    local setname = AceGUI:Create("EditBox")
    setname:SetWidth(240)
    setname:SetText("NewSet1")
    setname:DisableButton(true)
    topgroup:AddChild(setname)
    topgroup.label = setname

    local setcreate = AceGUI:Create("Button")
    setcreate:SetText("Save")
    setcreate:SetWidth(100)
    setcreate:SetCallback("OnClick", function(self) GearRenterSets:SaveSet() end)
    setcreate:SetCallback("OnEnter", function() Frame:SetStatusText("Create new/overwrite existing set") end)
    setcreate:SetCallback("OnLeave", function() Frame:SetStatusText("") end)
    topgroup:AddChild(setcreate)

    local btn4 = AceGUI:Create("Button")
    btn4:SetWidth(100)
    btn4:SetText("Delete")
    btn4:SetCallback("OnClick", function() GearRenterSets:DeleteSet() end)
    topgroup:AddChild(btn4)
    -- Frame.rpane:AddChild(btn4)
    -- Frame.rpane.deletebtn = btn4


    local treegroup = AceGUI:Create("TreeGroup") -- "InlineGroup" is also good
    treegroup:SetFullWidth(true)
    treegroup:SetTreeWidth(150, false)
    treegroup:SetLayout("Flow")
    treegroup:SetFullHeight(true) -- probably?
    treegroup:SetCallback("OnGroupSelected", function(self, event, group) GearRenterSets:UpdateRightPanel(group) end)
    Frame:AddChild(treegroup)
    Frame.rpane = treegroup
    Frame.tree = treegroup


    local btn1 = AceGUI:Create("Button")
    btn1:SetWidth(130)
    btn1:SetText("Equip")
    btn1:SetCallback("OnClick", function() GearRenterSets:LoadSet() end)
    btn1:SetDisabled(true)
    Frame.rpane:AddChild(btn1)
    Frame.rpane.equipbtn = btn1

    local itemsgroup = AceGUI:Create("InlineGroup")
    itemsgroup:SetWidth(300)
    itemsgroup:SetFullHeight(true)
    itemsgroup:SetLayout("List")
    itemsgroup.labels = {}
    Frame.rpane:AddChild(itemsgroup)

    for _,k in pairs(iSlots) do
        local label = AceGUI:Create("Label")
        label:SetText('test')
        label:SetWidth(280)
        label.label:SetWordWrap(false) 
        label:SetImage("Interface\\Icons\\spell_holy_resurrection")
        itemsgroup:AddChild(label)
        itemsgroup.labels[k] = label
    end
    Frame.rpane.itemlabels = itemsgroup.labels

    Frame:Hide()

    return Frame
end


local function Item_OnEnter(self)   
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    if ( self.pointType == ARENA_POINTS ) then
        GameTooltip:SetText(ARENA_POINTS, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
        GameTooltip:AddLine(TOOLTIP_ARENA_POINTS, nil, nil, nil, 1);
        GameTooltip:Show();
    elseif ( self.pointType == HONOR_POINTS ) then
        GameTooltip:SetText(HONOR_POINTS, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
        GameTooltip:AddLine(TOOLTIP_HONOR_POINTS, nil, nil, nil, 1);
        GameTooltip:Show();
    elseif ( self.pointType == "Beta" ) then
        GameTooltip:SetText(self.itemLink, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
        GameTooltip:Show();
    else
        GameTooltip:SetHyperlink(self.itemLink);
    end
    
    ResetCursor()
end

local function Item_OnLeave(self)
    GameTooltip:Hide()
    ResetCursor()
end
