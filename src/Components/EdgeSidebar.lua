local RunService   = game:GetService("RunService")
local Creator      = require(script.Parent.Parent.Creator)
local ThemeManager = require(script.Parent.Parent.Themes.Manager)
local Tween        = require(script.Parent.Parent.Utils.Tween)
local Spring       = require(script.Parent.Parent.Utils.Spring)

local CLIP_W   = 40
local INNER_W  = 48
local INNER_OX = -8
local BTN_SZ   = 36
local CORNER   = 10
local GAP_TOP  = 8


local EdgeSidebar = {}
EdgeSidebar.__index = EdgeSidebar

function EdgeSidebar.new(screenGui, anchorY, height)
	local self    = setmetatable({}, EdgeSidebar)
	self._entries = {}
	self._shown   = false

	local t = ThemeManager.CurrentTheme

	local clipper = Creator.New("Frame", {
		Name                   = "EdgeSidebarClip",
		AnchorPoint            = Vector2.new(0, 0),
		Position               = UDim2.fromOffset(0, anchorY),
		Size                   = UDim2.fromOffset(CLIP_W, height),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		ClipsDescendants       = true,
		ZIndex                 = 8,
		Parent                 = screenGui,
	})

	local inner = Creator.New("Frame", {
		Name                   = "EdgeSidebarInner",
		Position               = UDim2.fromOffset(INNER_OX, 0),
		Size                   = UDim2.fromOffset(INNER_W, height),
		BackgroundColor3       = t.Panel,
		BackgroundTransparency = 0,
		BorderSizePixel        = 0,
		ZIndex                 = 8,
		ThemeTag               = { BackgroundColor3 = "Panel" },
		Parent                 = clipper,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, CORNER) }),
		Creator.New("UIStroke", {
			Thickness       = 1,
			Color           = t.BorderBright,
			Transparency    = 0.55,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag        = { Color = "BorderBright" },
		}),
		Creator.New("UIListLayout", {
			SortOrder           = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding             = UDim.new(0, 4),
		}),
		Creator.New("UIPadding", {
			PaddingTop    = UDim.new(0, GAP_TOP),
			PaddingBottom = UDim.new(0, GAP_TOP),
			PaddingLeft   = UDim.new(0, INNER_W - CLIP_W),
		}),
	})

	self._clipper = clipper
	self._inner   = inner
	self._height  = height
	self._anchorY = anchorY

	local hiddenX  = -CLIP_W
	local shownX   = 0
	local sprX     = Spring.new(hiddenX, 22, 0.82)
	self._sprX     = sprX
	self._hiddenX  = hiddenX
	self._shownX   = shownX

	local conn = RunService.Heartbeat:Connect(function(dt)
		sprX:Step(dt)
		local x = math.round(sprX.Position)
		clipper.Position = UDim2.fromOffset(x, self._anchorY)
	end)
	self._conn = conn

	self:_AddRestoreButton()

	return self
end

function EdgeSidebar:_AddRestoreButton()
	local t  = ThemeManager.CurrentTheme
	local btn = Creator.New("TextButton", {
		Name                   = "RestoreBtn",
		LayoutOrder            = 0,
		Size                   = UDim2.fromOffset(BTN_SZ - 4, BTN_SZ - 4),
		BackgroundColor3       = t.Accent,
		BackgroundTransparency = 0.70,
		Text                   = "▶",
		TextSize               = 9,
		FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
		TextColor3             = t.Accent,
		AutoButtonColor        = false,
		BorderSizePixel        = 0,
		ZIndex                 = 9,
		ThemeTag               = { BackgroundColor3 = "AccentMuted", TextColor3 = "Accent" },
		Parent                 = self._inner,
	}, { Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }) })

	btn.MouseEnter:Connect(function()
		Tween.Play(btn, Tween.Fast, { BackgroundTransparency = 0.40 })
	end)
	btn.MouseLeave:Connect(function()
		Tween.Play(btn, Tween.Fast, { BackgroundTransparency = 0.70 })
	end)

	self._restoreBtn    = btn
	self._restoreSignal = btn.MouseButton1Click
end

function EdgeSidebar:OnRestore(fn)
	self._restoreConn = self._restoreSignal:Connect(fn)
end

function EdgeSidebar:AddEntry(entry)
	table.insert(self._entries, entry)
	local t     = ThemeManager.CurrentTheme
	local order = #self._entries + 1

	local btn = Creator.New("TextButton", {
		Name                   = "SideBtn_" .. entry.Id,
		LayoutOrder            = order,
		Size                   = UDim2.fromOffset(BTN_SZ - 4, BTN_SZ - 4),
		BackgroundColor3       = t.ControlBg,
		BackgroundTransparency = 0.80,
		Text                   = entry.Icon,
		TextSize               = 11,
		FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
		TextColor3             = t.SubText,
		AutoButtonColor        = false,
		BorderSizePixel        = 0,
		ZIndex                 = 9,
		ThemeTag               = { BackgroundColor3 = "ControlBg", TextColor3 = "SubText" },
		Parent                 = self._inner,
	}, { Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }) })

	btn.MouseEnter:Connect(function()
		Tween.Play(btn, Tween.Fast, { BackgroundTransparency = 0.40, TextColor3 = ThemeManager.CurrentTheme.Text })
	end)
	btn.MouseLeave:Connect(function()
		Tween.Play(btn, Tween.Fast, { BackgroundTransparency = 0.80, TextColor3 = ThemeManager.CurrentTheme.SubText })
	end)
	btn.MouseButton1Click:Connect(function()
		entry.OnClick()
	end)
end

function EdgeSidebar:Show()
	self._shown = true
	self._sprX:SetTarget(self._shownX)
	self._clipper.Visible = true
end

function EdgeSidebar:Hide()
	self._shown = false
	self._sprX:SetTarget(self._hiddenX)
end

function EdgeSidebar:Reposition(anchorY, height)
	self._anchorY = anchorY
	self._height  = height
	self._clipper.Size = UDim2.fromOffset(CLIP_W, height)
	self._inner.Size   = UDim2.fromOffset(INNER_W, height)
end

function EdgeSidebar:Destroy()
	self._conn:Disconnect()
	if self._restoreConn then self._restoreConn:Disconnect() end
	self._clipper:Destroy()
end

return EdgeSidebar
