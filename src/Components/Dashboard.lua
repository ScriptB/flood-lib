--!strict
local Players          = game:GetService("Players")
local Creator          = require(script.Parent.Parent.Creator)
local ThemeManager     = require(script.Parent.Parent.Themes.Manager)

local AVATAR_SZ = 52
local THUMB_TYPE = Enum.ThumbnailType.HeadShot
local THUMB_SZ   = Enum.ThumbnailSize.Size100x100

local Dashboard = {}
Dashboard.__index = Dashboard

function Dashboard.new(parent: Frame): any
	local self = setmetatable({}, Dashboard)

	local t = ThemeManager.CurrentTheme

	local page = Creator.New("Frame", {
		Name                   = "DashboardPage",
		Size                   = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Visible                = true,
		Parent                 = parent,
	})

	local headerRow = Creator.New("Frame", {
		Name                   = "HeaderRow",
		Size                   = UDim2.new(1, -24, 0, AVATAR_SZ),
		Position               = UDim2.fromOffset(12, 16),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Parent                 = page,
	}, {
		Creator.New("UIListLayout", {
			FillDirection       = Enum.FillDirection.Horizontal,
			VerticalAlignment   = Enum.VerticalAlignment.Center,
			SortOrder           = Enum.SortOrder.LayoutOrder,
			Padding             = UDim.new(0, 12),
		}),
	})

	local avatarFrame = Creator.New("Frame", {
		Name                   = "AvatarFrame",
		LayoutOrder            = 1,
		Size                   = UDim2.fromOffset(AVATAR_SZ, AVATAR_SZ),
		BackgroundColor3       = t.ControlBg,
		BackgroundTransparency = 0,
		BorderSizePixel        = 0,
		ThemeTag               = { BackgroundColor3 = "ControlBg" },
		Parent                 = headerRow,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Creator.New("UIStroke", {
			Thickness       = 1.5,
			Color           = t.Accent,
			Transparency    = 0.60,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag        = { Color = "Accent" },
		}),
	})

	local avatarImg = Creator.New("ImageLabel", {
		Name                   = "AvatarImg",
		Size                   = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image                  = "",
		ZIndex                 = 2,
		Parent                 = avatarFrame,
	}, { Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	local textCol = Creator.New("Frame", {
		Name                   = "TextCol",
		LayoutOrder            = 2,
		Size                   = UDim2.new(1, -(AVATAR_SZ + 12), 0, AVATAR_SZ),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Parent                 = headerRow,
	}, {
		Creator.New("UIListLayout", {
			SortOrder           = Enum.SortOrder.LayoutOrder,
			VerticalAlignment   = Enum.VerticalAlignment.Center,
			Padding             = UDim.new(0, 3),
		}),
	})

	Creator.New("TextLabel", {
		Name                   = "WelcomeLabel",
		LayoutOrder            = 1,
		AutomaticSize          = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text                   = "WELCOME",
		TextSize               = 8,
		FontFace               = Font.fromEnum(Enum.Font.Gotham),
		TextColor3             = t.SubText,
		TextXAlignment         = Enum.TextXAlignment.Left,
		ThemeTag               = { TextColor3 = "SubText" },
		Parent                 = textCol,
	})

	local nameLbl = Creator.New("TextLabel", {
		Name                   = "NameLabel",
		LayoutOrder            = 2,
		AutomaticSize          = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text                   = "...",
		TextSize               = 16,
		FontFace               = Font.fromEnum(Enum.Font.GothamBold),
		TextColor3             = t.Text,
		TextXAlignment         = Enum.TextXAlignment.Left,
		ThemeTag               = { TextColor3 = "Text" },
		Parent                 = textCol,
	})

	local divider = Creator.New("Frame", {
		Name                   = "Divider",
		Position               = UDim2.fromOffset(12, AVATAR_SZ + 28),
		Size                   = UDim2.new(1, -24, 0, 1),
		BackgroundColor3       = t.Border,
		BackgroundTransparency = 0.40,
		BorderSizePixel        = 0,
		ThemeTag               = { BackgroundColor3 = "Border" },
		Parent                 = page,
	})
	_ = divider

	local contentArea = Creator.New("ScrollingFrame", {
		Name                       = "ContentArea",
		Position                   = UDim2.fromOffset(0, AVATAR_SZ + 38),
		Size                       = UDim2.new(1, 0, 1, -(AVATAR_SZ + 38)),
		BackgroundTransparency     = 1,
		BorderSizePixel            = 0,
		ScrollBarThickness         = 3,
		ScrollBarImageColor3       = t.Border,
		AutomaticCanvasSize        = Enum.AutomaticSize.Y,
		CanvasSize                 = UDim2.fromScale(0, 0),
		ThemeTag                   = { ScrollBarImageColor3 = "Border" },
		Parent                     = page,
	}, {
		Creator.New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding   = UDim.new(0, 8),
		}),
		Creator.New("UIPadding", {
			PaddingLeft   = UDim.new(0, 12),
			PaddingRight  = UDim.new(0, 12),
			PaddingTop    = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
	})

	self._page        = page
	self._contentArea = contentArea
	self._nameLbl     = nameLbl
	self._avatarImg   = avatarImg

	task.spawn(function()
		local player = Players.LocalPlayer
		if not player then return end
		nameLbl.Text = player.DisplayName
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, THUMB_TYPE, THUMB_SZ)
		end)
		if ok and img then
			avatarImg.Image = img
		end
	end)

	return self
end

function Dashboard:GetPage(): Frame
	return self._page
end

function Dashboard:GetContentArea(): ScrollingFrame
	return self._contentArea
end

function Dashboard:SetVisible(visible: boolean)
	self._page.Visible = visible
end

function Dashboard:Destroy()
	self._page:Destroy()
end

return Dashboard
