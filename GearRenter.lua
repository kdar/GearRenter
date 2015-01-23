GearRenter = LibStub("AceAddon-3.0"):NewAddon("Gear Renter", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local LibDialog = LibStub("LibDialog-1.0")

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
    alertHeader = {
      order = 3, 
      type = "header",
      name = "Alerts",
    },
    alertgroup1 = {
      name = 'Expire alert 1',
      type = 'group',
      inline = true,
      order = 4,
      args = {
        alertEnabled = {
          type = 'toggle',
          order = 1,
          name = 'Enable alert 1',
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
    newline3 = {type = "description", order = 5, name = "\n"},
    alertgroup2 = {
      name = 'Expire alert 2',
      type = 'group',
      inline = true,
      order = 6,
      args = {
        alertEnabled = {
          type = 'toggle',
          order = 1,
          name = 'Enable alert 2',
          width = 'double',
          desc = 'This will pop up an alert window when one of your pieces of gear is about to expire.',
          get = function(info) return GearRenter.db.profile.alerts[2].enabled end,
          set = function(info, val) 
            GearRenter:EnableAlert(2, val)
            GearRenter.alerts[2].shown = false
          end,          
        },
        newline4 = {type = "description", order = 2, name = "\n"},
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
    newline5 = {type = "description", order = 7, name = "\n"},
    progressHeader = {
      order = 8, 
      type = "header",
      name = "Progress bar",
    },
    progressgroup1 = {
      name = '',
      type = 'group',
      inline = true,
      order = 9,
      args = {
        progressLock = {
          type = 'toggle',
          order = 1,
          name = 'Lock progress',
          desc = 'Lock or unlock the progress bar.',
          get = function(info) return GearRenter.db.profile.progress.locked end,
          set = function(info, val) 
            if val then
              GearRenterProgressFrame:Hide()
              GearRenter:LockProgress()
            else
              GearRenterProgressFrame:Show()
              GearRenter:UnlockProgress()
            end
          end,  
        },
        progressResetPosition = {
          name = 'Reset position',
          type = 'execute',
          order = 2,
          func = function() GearRenter.ResetProgressPos() end
        }
      }
    },
    newline6 = {type = "description", order = 10, name = "\n"},
    timerHeader = {
      order = 11, 
      type = "header",
      name = "Timer",
    },
    timerEnable = {
      type = 'toggle',
      order = 12,
      name = 'Enable timer',
      desc = 'Enables or disables the timer.',
      get = function(info) return GearRenter.db.profile.timer.enabled end,
      set = function(info, val) 
        if (val) then 
          GearRenter:EnableTimer()
        else 
          GearRenter:DisableTimer()
        end 
      end,  
    },
    timerLock = {
      type = 'toggle',
      order = 13,
      name = 'Lock timer',
      desc = 'Lock or unlock the timer bar.',
      get = function(info) return GearRenter.db.profile.timer.locked end,
      set = function(info, val) 
        if val then
          GearRenter:LockTimer()
        else
          GearRenter:UnlockTimer()
        end
      end,  
    },
    timerResetPosition = {
      name = 'Reset position',
      type = 'execute',
      order = 14,
      func = function() GearRenter.ResetTimerPos() end
    }
  },
}

local defaults = {
  profile = {
    enabled = true,
    progress = {
      locked = true,
      position = {
        from = "TOP",
        to = "TOP",
        x = 0,
        y = -160
      }
    },
    timer = {
      enabled = false,
      locked = true,
      position = {
        from = "TOP",
        to = "TOP",
        x = 0,
        y = -100
      }
    },
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

  self.fetchTooltip = CreateFrame("GAMETOOLTIP", "fetchTooltip")

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

  GearRenterTimerFrameBarText:SetText("Timer")
  GearRenterTimerFrameBar:SetStatusBarColor(0, 0.7, 1.0, 1.0)
  self:SetBarFrameSize(GearRenterTimerFrame, 150, 20)

  GearRenterProgressFrame:SetUserPlaced(true)
  GearRenterUtil.applyDragFunctionality(GearRenterProgressFrame, GearRenter.db.profile.progress.position, defaults.profile.progress.position)
  GearRenterTimerFrame:SetUserPlaced(true)
  GearRenterUtil.applyDragFunctionality(GearRenterTimerFrame, GearRenter.db.profile.timer.position, defaults.profile.timer.position)

  LibDialog:Register("GearRenterSellChoice", {
    hide_on_escape = true,
    text = "This merchant is not a conquest or honor vendor.\n\nWould you like to:",
    checkboxes = {
      {
        label = "Sell all refundable conquest gear",
        get_value = function(self, data)
          return data.sellConquest
        end,
        set_value = function(self, value, data, mouseButton, down) 
          if mouseButton == "LeftButton" then
            data.sellConquest = not data.sellConquest
          end
        end
      },
      {
        label = "Try to sell all refundable honor gear",
        get_value = function(self, data)
          return data.sellHonor
        end,
        set_value = function(self, value, data, mouseButton, down) 
          if mouseButton == "LeftButton" then
            data.sellHonor = not data.sellHonor
          end
        end
      }
    },
    buttons = {
      {
        text = "Do It!",
        on_click = function(dialog, data)
          GearRenter:SellToGenericVendor(data.sellConquest, data.sellHonor)
          return false
        end
      },
      {
        text = "Cancel"
      }
    }
  })

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

function GearRenter:RunQueue(countFn, total)
  table.insert(self.queue, {function()
    for i=1,#self.alerts do
      self.alerts[i].shown = false
      self.alerts[i].enteringWorld = 0
    end

    self:TimerTick()

    return true
  end})

  GearRenterProgressFrame:Show();
  GearRenterProgressFrameBar:SetMinMaxValues(0, 1)
  GearRenterProgressFrameBar:SetValue(0)
  local queueLen = #self.queue;

  self.rentTimer = self:ScheduleRepeatingTimer(function()
    self:NextQueue()

    local progress = 1 - (#self.queue/queueLen)
    GearRenterProgressFrameBar:SetValue(progress)
    GearRenterProgressFrameBarText:SetText("Renting "..countFn().."/"..total.." - "..floor(progress * 100).."%")

    if #self.queue <= 0 then
      self:CancelTimer(self.rentTimer)
      GearRenterProgressFrame:Hide();
    end
  end, 0.1)
end

function GearRenter:NextQueue()
  if #self.queue > 0 then
    item = self.queue[1]
    if item == nil then
      return
    end

    func = item[1]
    args = slice(item, 2)

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
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  self:RegisterChatCommand("rebuy", "Rebuy")

  GearRenterFrame:Show()

  for i=1,#self.db.profile.alerts do
    self:EnableAlert(i, self.db.profile.alerts[i].enabled)
  end

  if self.db.profile.timer.enabled then
    self:EnableTimer()
  else
    self:DisableTimer()
  end

  if GearRenter.db.profile.progress.locked then
    self:LockProgress()
  else
    self:UnlockProgress()
  end

  if GearRenter.db.profile.timer.locked then
    self:LockTimer()
  else
    self:UnlockTimer()
  end

  self.db.profile.enabled = true
end

function GearRenter:OnDisable()
  self:UnregisterChatCommand("rebuy")
  self:UnregisterEvent("PLAYER_ENTERING_WORLD")

  GearRenterFrame:Hide()

  for i=1,#self.db.profile.alerts do
    self:EnableAlert(i, false)
  end

  self:DisableTimer()

  self.db.profile.enabled = false
end

function GearRenter:ResetProgressPos()
  GearRenterProgressFrame:ClearAllPoints()
  --GearRenterProgressFrame:SetPoint("TOP", "UIParent", "TOP", 0, -160)
  GearRenterProgressFrame:reset()
end

function GearRenter:ResetTimerPos()
  GearRenterTimerFrame:ClearAllPoints()
  --GearRenterTimerFrame:SetPoint("TOP", "UIParent", "TOP", 0, -100)
  GearRenterTimerFrame:reset()
end

function GearRenter:SetBarFrameSize(frame, width, height)
  name = frame:GetName()
  frame:SetSize(width, height)
  _G[name.."Bar"]:SetSize(width, height)
  _G[name.."BarText"]:SetSize(width-10, height+8)
  _G[name.."BarBorder"]:SetSize(width+8, height+4)
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

function GearRenter:LockProgress()
  GearRenter.db.profile.progress.locked = true
  --GearRenterProgressFrame:EnableMouse(false)
  GearRenterProgressFrame:lock()
end

function GearRenter:UnlockProgress()
  GearRenter.db.profile.progress.locked = false
  --GearRenterProgressFrame:EnableMouse(true)  
  GearRenterProgressFrame:unlock()
end

function GearRenter:EnableTimer()
  self.db.profile.timer.enabled = true
  GearRenterTimerFrame:Show()

  self.timerTimer = self:ScheduleRepeatingTimer(self.TimerTick, 30)
  self:ScheduleTimer(self.TimerTick, 3)
end

function GearRenter:DisableTimer()
  self.db.profile.timer.enabled = false
  GearRenterTimerFrame:Hide()

  self:CancelTimer(self.timerTimer)
end

function GearRenter:TimerTick()
  if GearRenter.db.profile.timer.enabled == false then
    return
  end

  lowestSecs = nil
  for slotID=1,18 do
    -- This forces the purchase info to actually load. If you don't do this,
    -- the purchase info will sometimes come back empty. I'm not sure if
    -- there is a cleaner API to do this.
    GearRenter.fetchTooltip:SetInventoryItem("player", slotID)
    _, _, refundSec, _, _ = GetContainerItemPurchaseInfo(-2, slotID, true)
    if refundSec ~= nil and (lowestSecs == nil or refundSec < lowestSecs) then
      lowestSecs = refundSec
    end
  end

  if lowestSecs ~= nil then
    GearRenterTimerFrame:Show();
    GearRenterTimerFrameBar:SetMinMaxValues(0, 7200)
    GearRenterTimerFrameBar:SetValue(lowestSecs)      
    GearRenterTimerFrameBarText:SetText(string.format("Rent: %.2d:%.2d", lowestSecs/(60*60), lowestSecs/60%60))
  end
end

function GearRenter:LockTimer()
  GearRenter.db.profile.timer.locked = true
  GearRenterTimerFrame:lock()
end

function GearRenter:UnlockTimer()
  GearRenter.db.profile.timer.locked = false
  GearRenterTimerFrame:unlock()
end

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
  local isHonorConquestVendor = false
  for _, currency in ipairs(merchCurrencies) do
    if currency == CONQUEST_CURRENCY or currency == HONOR_CURRENCY then
      name, _, _, _, _, _, _ = GetCurrencyInfo(currency)
      currencies[name] = currency
      isHonorConquestVendor = true
    end
  end

  if not isHonorConquestVendor then
    LibDialog:Spawn("GearRenterSellChoice", {})
    return
  end

  -- Cancel the timer if it is still going on from before.
  self:CancelTimer(self.rentTimer)

  self.queue = {}
  itemRentCount = 0
  itemRentTotal = 0
  for slotID=1,18 do
    _, _, refundSec, _, hasEnchants = GetContainerItemPurchaseInfo(-2, slotID, true)
    _, currencyQuantity, currencyName = GetContainerItemPurchaseCurrency(-2, slotID, 1, true)    
    if currencies[currencyName] ~= nil and not(refundSec == nil) and refundSec > 0 and not hasEnchants then
      itemRentTotal = itemRentTotal + 1

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
          table.insert(self.queue, {function(slotID)
            return GetInventoryItemID("player", slotID) == nil
          end, slotID})
          table.insert(self.queue, {function(index)
            BuyMerchantItem(index, 1)
            return true
          end, x})
          table.insert(self.queue, {function(itemID)
            found = false
            for bag=0, NUM_BAG_SLOTS do
              for bagSlot=1, GetContainerNumSlots(bag) do
                if GetContainerItemID(bag, bagSlot) == tonumber(itemID) then
                  found = true
                end
              end
            end

            return found
          end, itemID})
          table.insert(self.queue, {function(link, slotID)
            if GetInventoryItemID("player", slotID) ~= nil then
              itemRentCount = itemRentCount + 1
              return true
            end

            EquipItemByName(link, slotID)
            return false
          end, link, slotID})
        end
      end
    end
  end
  
  -- self.machine:start()

  self:RunQueue(function() return itemRentCount end, itemRentTotal)
end

function GearRenter:SellToGenericVendor(sellConquest, sellHonor)
  if not MerchantFrame:IsShown() then
    self:Print("Not at a merchant.")
    return
  end

  if not sellConquest and not sellHonor then
    return
  end

  -- Cancel the timer if it is still going on from before.
  self:CancelTimer(self.rentTimer)

  self.queue = {}
  itemSellCount = 0
  itemSellTotal = 0
  for slotID=1,18 do
    _, _, refundSec, _, hasEnchants = GetContainerItemPurchaseInfo(-2, slotID, true)
    _, currencyQuantity, currencyName = GetContainerItemPurchaseCurrency(-2, slotID, 1, true)    
    if ((sellConquest and currencyName == "Conquest Points") or (sellHonor and currencyName == "Honor Points")) and 
        not(refundSec == nil) and refundSec > 0 and not hasEnchants then
      itemSellTotal = itemSellTotal + 1

      table.insert(self.queue, {function(slotID) 
        ContainerRefundItemPurchase(-2, slotID)
        return true
      end, slotID})
      table.insert(self.queue, {function(slotID)
        if GetInventoryItemID("player", slotID) == nil then
          itemSellCount = itemSellCount + 1
          return true
        end

        return false 
      end, slotID})
    end
  end
  
  self:RunQueue(function() return itemSellCount end, itemSellTotal)
end