GearRenter = LibStub("AceAddon-3.0"):NewAddon("Gear Renter", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

local options = {
  name = "GearRenter",
  handler = GearRenter,
  type = 'group',
  args = {
    enable = {
      type = 'toggle',
      order = 1,
      name = 'Enabled',
      width = 'double',
      desc = 'Enable or disable this addon.',
      get = function(info) return GearRenter.db.profile.enabled end,
      set = function(info, val) if (val) then GearRenter:Enable() else GearRenter:Disable() end end,      
    },
    newline1 = {type = "description", order = 2, name = "\n"},
    alertgroup1 = {
      name = 'Expire alert 1',
      type = 'group',
      inline = true,
      order = 3,
      args = {
        alertEnabled = {
          type = 'toggle',
          order = 1,
          name = 'Enable',
          width = 'double',
          desc = 'This will pop up an alert window when one of your pieces of gear is about to expire.',
          get = function(info) return GearRenter.db.profile.alerts[1].enabled end,
          set = function(info, val) 
            GearRenter:EnableAlert(1, val)
            GearRenter.alerts[1].shown = false
          end,          
        },
        newline2 = {type = "description", order = 2, name = "\n"},
        alertMinutes = {
          type = 'range',
          order = 3,
          name = 'Remaining minutes',
          width = 'double',
          desc = 'The remaining amount of minutes the gear has to be at in order to trigger the alert.',
          min = 5,
          max = 120,
          step = 1,
          get = function(info) return GearRenter.db.profile.alerts[1].minutes end,
          set = function(info, val) 
            GearRenter.db.profile.alerts[1].minutes = val
            GearRenter.alerts[1].shown = false
          end,
        }
      }
    },
    newline1 = {type = "description", order = 4, name = "\n"},
    alertgroup2 = {
      name = 'Expire alert 2',
      type = 'group',
      inline = true,
      order = 5,
      args = {
        alertEnabled = {
          type = 'toggle',
          order = 1,
          name = 'Enable',
          width = 'double',
          desc = 'This will pop up an alert window when one of your pieces of gear is about to expire.',
          get = function(info) return GearRenter.db.profile.alerts[2].enabled end,
          set = function(info, val) 
            GearRenter:EnableAlert(2, val)
            GearRenter.alerts[2].shown = false
          end,          
        },
        newline2 = {type = "description", order = 2, name = "\n"},
        alertMinutes = {
          type = 'range',
          order = 3,
          name = 'Remaining minutes',
          width = 'double',
          desc = 'The remaining amount of minutes the gear has to be at in order to trigger the alert.',
          min = 5,
          max = 120,
          step = 1,
          get = function(info) return GearRenter.db.profile.alerts[2].minutes end,
          set = function(info, val) 
            GearRenter.db.profile.alerts[2].minutes = val
            GearRenter.alerts[2].shown = false
          end,
        }
      }
    },
  },
}

local defaults = {
  profile = {
    enabled = true,
    alerts = {
      {
        enabled = true,
        minutes = 30
      },
      {
        enabled = true,
        minutes = 15
      }
    }
  }
}

function slice(list, index) 
  return { select(index, unpack(list)) } 
end

function GearRenter:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("GearRenterDB", defaults)
  local parent = LibStub("AceConfig-3.0"):RegisterOptionsTable("GearRenter", options, {"GearRenter", "gr"})
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions("GearRenter", "GearRenter")
  profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
  LibStub("AceConfig-3.0"):RegisterOptionsTable("GearRenter.profiles", profiles)
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions("GearRenter.profiles", "Profiles", "GearRenter")

  self.queue = {}
  self.alerts = {
    {
      shown = false,
      enteringWorld = 0
    },
    {
      shown = false,
      enteringWorld = 0
    }
  }

  StaticPopupDialogs["GEAR_RENTER_ALERT"] = {
    text = "Your PVP gear will expire in |cffffff00%d|r minutes!",
    button1 = "Ok",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    sound = 'levelup2',
    preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
  }

  -- self.machine = self.statemachine.create({
  --   initial = 'none',
  --   events = {
  --     {name = 'start', from = {'none', 'started', 'sold', 'bought', 'equipped'}, to = 'started'},
  --     {name = 'sell', from = 'started', to = 'sold'},
  --     {name = 'buy', from = 'sold', to = 'bought'},
  --     {name = 'equip', from = 'bought', to = 'equipped'},
  --     --{name = 'stop', from = {'none', 'started', 'sold', 'bought', 'equipped'}, to = 'none'}
  --   },
  --   callbacks = {
  --     onstart = function(self, event, from, to) 
  --       --GearRenter:Print('start')
  --       GearRenter.machine:sell()
  --     end,
  --     onsell = function(self, event, from, to) 
  --       --GearRenter:Print('sell')
  --       GearRenter:NextQueue()
  --     end,
  --     onbuy = function(self, event, from, to) 
  --       --GearRenter:Print('buy')
  --       GearRenter:NextQueue()
  --     end,
  --     onequip = function(self, event, from, to) 
  --       --GearRenter:Print('equip')
  --       GearRenter:NextQueue()
  --     end,
  --   }
  -- })
end

function GearRenter:NextQueue()
  if #self.queue > 0 then
    item = self.queue[1]
    if item == nil then
      return
    end

    func = item[1]
    args = slice(item, 2)

    -- if func == ContainerRefundItemPurchase then
    --  GearRenter:Print("ContainerRefundItemPurchase")
    -- elseif func == BuyMerchantItem then
    --  GearRenter:Print("BuyMerchantItem")
    -- elseif func == EquipItemByName then
    --  GearRenter:Print("EquipItemByName")
    -- end

    ret = func(unpack(args))
    if ret then
      table.remove(self.queue, 1)
      return true
    end
  else
    -- self.machine:set('none')
  end

  return false
end

function GearRenter:OnEnable()
  --self:RegisterEvent("UNIT_INVENTORY_CHANGED")
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  self:RegisterChatCommand("rebuy", "Rebuy")
  -- self:RegisterEvent("BAG_UPDATE_DELAYED")

  --GearRenterFrame:SetParent(MerchantFrame)
  GearRenterFrame:Show()

  for i=1,#self.db.profile.alerts do
    self:EnableAlert(i, self.db.profile.alerts[i].enabled)
  end

  self.db.profile.enabled = true
end

function GearRenter:OnDisable()
  self:UnregisterChatCommand("rebuy")
  self:UnregisterEvent("PLAYER_ENTERING_WORLD")
  --self:UnregisterEvent("UNIT_INVENTORY_CHANGED")

  --GearRenterFrame:SetParent(nil)
  GearRenterFrame:Hide()

  for i=1,#self.db.profile.alerts do
    self:EnableAlert(i, false)
  end

  self.db.profile.enabled = false
end

function GearRenter:EnableAlert(which, enabled)
  self.db.profile.alerts[which].enabled = enabled

  if enabled then
    if self.expiresTimer == nil then
      self.expiresTimer = self:ScheduleRepeatingTimer("CheckExpires", 5)
    end
  else
    if not self.db.profile.alerts[1].enabled and self.db.profile.alerts[1].enabled then
      self:CancelTimer(self.expiresTimer)
      self.expiresTimer = nil
    end
  end
end

-- function GearRenter:BAG_UPDATE_DELAYED()
--   self:Print("CALLLLEEEDDDD")
-- end

-- function GearRenter:UNIT_INVENTORY_CHANGED(event, unitID)
--   self:ScheduleTimer(function()
--     if self.machine:is('started') then
--       self.machine:sell()  
--     elseif self.machine:is('sold') then
--       self.machine:buy()
--     elseif self.machine:is('bought') then
--       self.machine:equip()
--     elseif self.machine:is('equipped') then
--       self.machine:start()
--     end
--   end, 0.5)
-- end

function GearRenter:PLAYER_ENTERING_WORLD()
  local instanceType = select(2, IsInInstance())

  if instanceType ~= "arena" then
    for i=1,#self.alerts do
      if self.alerts[i].enteringWorld > 0 then
        self:Alert(i, self.alerts[i].enteringWorld)
        self.alerts[i].enteringWorld = 0
      end
    end
  end
end

function GearRenter:CheckExpires()
  lowestSecs = nil
  which = 1
  for slotID=1,18 do
    _, _, refundSec, _, _ = GetContainerItemPurchaseInfo(-2, slotID, true)

    if self.db.profile.alerts[1].enabled and not self.alerts[1].shown and refundSec ~= nil and refundSec <= ((self.db.profile.alerts[1].minutes+1)*60) then
      if lowestSecs == nil or refundSec < lowestSecs then
        lowestSecs = refundSec
        which = 1
      end
    end

    if self.db.profile.alerts[2].enabled and not self.alerts[2].shown and refundSec ~= nil and refundSec <= ((self.db.profile.alerts[2].minutes+1)*60) then
      if lowestSecs == nil or refundSec < lowestSecs then
        lowestSecs = refundSec
        which = 2
      end
    end
  end

  if lowestSecs ~= nil then
    self:Alert(which, lowestSecs)
  else
    --self:Print("reset?")
    --self.alerts[which].shown = false
  end
end

function GearRenter:Alert(which, secs)
  if not self.alerts[which].shown then
    local instanceType = select(2, IsInInstance())
    if instanceType == "arena" then
      --self:Print("Gear is expiring!")
      self.alerts[which].enteringWorld = secs
    else
      StaticPopup_Show("GEAR_RENTER_ALERT", secs / 60)
      self.alerts[which].shown = true
    end
  end
end

function GearRenter:Rebuy_OnClick()
  self:Rebuy()
end

function GearRenter:Rebuy()
  if not MerchantFrame:IsShown() then
    self:Print("Not at a merchant.")
    return
  end

  local merchCurrencies = {GetMerchantCurrencies()}
  local currencies = {}
  for _, currency in ipairs(merchCurrencies) do
    if currency ~= CONQUEST_CURRENCY and currency ~= HONOR_CURRENCY then
      self:Print("This merchant is not a conquest or honor vendor.")
      return
    end
    name, _, _, _, _, _, _ = GetCurrencyInfo(currency)
    currencies[name] = currency
  end

  -- Cancel the timer if it is still going on from before.
  self:CancelTimer(self.repeatTimer)

  self.queue = {}
  for slotID=1,18 do
    money, itemCount, refundSec, currecycount, hasEnchants = GetContainerItemPurchaseInfo(-2, slotID, true)
    _, currencyQuantity, currencyName = GetContainerItemPurchaseCurrency(-2, slotID, 1, true)    
    if currencies[currencyName] ~= nil and not(refundSec == nil) and refundSec > 0 and not hasEnchants then
      currentPlayerCurrency = select(2, GetCurrencyInfo(currencies[currencyName]))
      _, equippedIlvl = GetAverageItemLevel()

      local itemID = GetInventoryItemID("player", slotID)
      _, itemLink, _, _, _, _, _, _, _, _, _ = GetItemInfo(itemID)   
      itemID = string.match(itemLink, "item:(%d+)")     

      for x=1,GetMerchantNumItems() do
        --local item, _, _, _, _, _, _ = GetMerchantItemInfo(x)
        local link = GetMerchantItemLink(x)
        local id = string.match(link, "item:(%d+)")  
        if itemID == id then
          --self:Print(string.format("Selling/buying/equipping %s", itemName))
          table.insert(self.queue, {function(slotID) 
            ContainerRefundItemPurchase(-2, slotID)
            return true
          end, slotID})
          table.insert(self.queue, {function(currentPlayerCurrency, currencyName)
            amount = select(2, GetCurrencyInfo(currencies[currencyName]))
            if currentPlayerCurrency < amount then
              return true
            end

            return false
          end, currentPlayerCurrency, currencyName})
          table.insert(self.queue, {function(index)
            BuyMerchantItem(index, 1)
            return true
          end, x})
          table.insert(self.queue, {function(currentPlayerCurrency, currencyName)
            amount = select(2, GetCurrencyInfo(currencies[currencyName]))
            if amount == currentPlayerCurrency then
              return true
            end

            return false
          end, currentPlayerCurrency, currencyName})
          --table.insert(self.queue, {EquipItemByName, link})
          -- table.insert(self.queue, {function(link, slotID)
          --   EquipItemByName(link, slotID)
          --   -- PickupItem(link)
          --   -- EquipCursorItem(slotID)
          --   -- AutoEquipCursorItem()
          --   return true
          -- end, link, slotID})
          table.insert(self.queue, {function(link, slotID, equippedIlvl)
            --truth = GetInventoryItemID("player", slotID) ~= nil
            -- Testing for the average item level seems to be more consistent
            -- than actually looking if there is something in the slot. All
            -- the APIs that get slot info seem to indicate that an item
            -- is in the slot when there isn't any.
            _, ilvl = GetAverageItemLevel()
            truth = (ilvl == equippedIlvl) and GetInventoryItemID("player", slotID) ~= nil
            if truth then
              GearRenter:Print("equipped")
              return truth
            end

            EquipItemByName(link, slotID)
            return truth
          end, link, slotID, equippedIlvl})
        end
      end
    end
  end
  
  -- self.machine:start()

  table.insert(self.queue, {function()
    for i=1,#self.alerts do
      self.alerts[i].shown = false
      self.alerts[i].enteringWorld = 0
    end
    return true
  end})

  GearRenterProgressFrame:Show();
  GearRenterProgressBar:SetMinMaxValues(0, 1)
  GearRenterProgressBar:SetValue(0)
  local queueLen = #self.queue;

  self.repeatTimer = self:ScheduleRepeatingTimer(function()
    self:NextQueue()

    local progress = 1 - (#self.queue/queueLen)
    GearRenterProgressBar:SetValue(progress)
    GearRenterProgressBarText:SetText("Renting "..floor(progress * 100).."%")

    if #self.queue <= 0 then
      self:CancelTimer(self.repeatTimer)
      GearRenterProgressFrame:Hide();
    end
  end, 0.3)
end
