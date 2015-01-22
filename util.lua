GearRenterUtil = {}

--apply drag functionality to any frame
GearRenterUtil.applyDragFunctionality = function(self, config, default)
  --save the default position
  -- local getPoint = function(self)
  --   local pos = {}
  --   pos.a1, pos.af, pos.a2, pos.x, pos.y = self:GetPoint()
  --   if pos.af and pos.af:GetName() then pos.af = pos.af:GetName() end
  --   return pos
  -- end
  -- self.defaultPosition = getPoint(self)
  --the drag frame
  local df = CreateFrame("Frame",nil,self)
  --df:SetAllPoints(self)
  df:SetPoint("CENTER", self, 0, 0)
  df:SetSize(self:GetWidth()+30, self:GetHeight()+30)
  df:SetFrameStrata("HIGH")
  df:SetHitRectInsets(0,0,0,0)
  df:SetScript("OnDragStart", function(self) 
    self:GetParent():StartMoving() 
  end)
  df:SetScript("OnDragStop", function(self) 
    self:GetParent():StopMovingOrSizing() 

    config.from, _, config.to, config.x, config.y = self:GetPoint()
  end)
  --dragframe texture
  local t = df:CreateTexture(nil,"OVERLAY",nil,6)
  t:SetAllPoints(df)
  t:SetTexture(0,1,0)
  t:SetAlpha(0.2)
  --stuff
  df.texture = t
  df:Hide()
  self.dragframe = df
  self:SetClampedToScreen(true)
  self:SetMovable(true)
  self:SetUserPlaced(true)
  --helper functions
  --unlock
  local unlock = function(self)
    if not self:IsUserPlaced() then return end
    self.dragframe:Show()
    self.dragframe:EnableMouse(true)
    self.dragframe:RegisterForDrag("LeftButton")
    self.dragframe:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:AddLine(self:GetParent():GetName(), 0, 1, 0.5, 1, 1, 1)
      GameTooltip:AddLine("Drag the frame to move it.", 1, 1, 1, 1, 1, 1)
      GameTooltip:Show()
    end)
    self.dragframe:SetScript("OnLeave", function() GameTooltip:Hide() end)
  end
  --lock
  local lock = function(self)
    if not self:IsUserPlaced() then return end
    self.dragframe:Hide()
    self.dragframe:EnableMouse(false)
    self.dragframe:RegisterForDrag(nil)
    self.dragframe:SetScript("OnEnter", nil)
    self.dragframe:SetScript("OnLeave", nil)
  end
  --reset position
  local reset = function(self)
    self:ClearAllPoints()
    self:SetPoint(default.from, UIParent, default.to, default.x, default.y)

    -- if self.defaultPosition then
    --   self:ClearAllPoints()
    --   local pos = self.defaultPosition
    --   if pos.af and pos.a2 then
    --     self:SetPoint(pos.a1 or "CENTER", pos.af, pos.a2, pos.x or 0, pos.y or 0)
    --   elseif pos.af then
    --     self:SetPoint(pos.a1 or "CENTER", pos.af, pos.x or 0, pos.y or 0)
    --   else
    --     self:SetPoint(pos.a1 or "CENTER", pos.x or 0, pos.y or 0)
    --   end
    -- else
    --   self:SetPoint("CENTER",0,0)
    -- end
  end
  self.unlock = unlock
  self.lock = lock
  self.reset = reset
end
