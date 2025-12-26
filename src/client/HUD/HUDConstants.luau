--!strict
--[[
    HUDConstants

    Shared styling constants for all HUD components.
    Mobile-first: phone, touchscreen, small screen priority.
]]

local HUDConstants = {}

--------------------------------------------------------------------------------
-- SPACING & LAYOUT (Mobile-first: generous touch targets)
--------------------------------------------------------------------------------

HUDConstants.Spacing = {
	-- Screen edge margins (comfortable thumb reach)
	ScreenPadding = 16,

	-- Internal padding within containers
	ContainerPadding = 12,

	-- Gap between elements
	ElementGap = 8,

	-- Small gap for tight layouts
	SmallGap = 4,
}

--------------------------------------------------------------------------------
-- SIZES (Mobile-first: minimum 44px touch targets)
--------------------------------------------------------------------------------

HUDConstants.Sizes = {
	-- Corner radius for containers
	CornerRadius = 10,

	-- Smaller corner radius for nested elements
	CornerRadiusSmall = 6,

	-- Icon sizes
	IconSmall = 20,
	IconMedium = 24,
	IconLarge = 36,

	-- Touch target minimum (iOS/Android guideline: 44pt)
	TouchTarget = 48,

	-- Minimum interactive element size
	MinTouchSize = 44,

	-- Stats bar dimensions
	StatBarHeight = 10,
	StatBarWidth = 160,
}

--------------------------------------------------------------------------------
-- COLORS
--------------------------------------------------------------------------------

HUDConstants.Colors = {
	-- Backgrounds
	ContainerBackground = Color3.fromRGB(0, 0, 0),
	ContainerBackgroundTransparency = 0.5,

	SlotDefault = Color3.fromRGB(40, 40, 40),
	SlotSelected = Color3.fromRGB(80, 120, 180),
	SlotHover = Color3.fromRGB(60, 60, 60),
	SlotEmpty = Color3.fromRGB(30, 30, 30),

	-- Text
	TextPrimary = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(200, 200, 200),
	TextMuted = Color3.fromRGB(150, 150, 150),

	-- Stats bars
	Hunger = Color3.fromRGB(255, 170, 50),
	Thirst = Color3.fromRGB(50, 150, 255),
	Health = Color3.fromRGB(80, 200, 80),

	-- Warning colors
	WarningLow = Color3.fromRGB(255, 200, 50),
	WarningCritical = Color3.fromRGB(255, 80, 80),
}

--------------------------------------------------------------------------------
-- ANIMATION
--------------------------------------------------------------------------------

HUDConstants.Animation = {
	-- Standard tween duration
	TweenTime = 0.3,
	TweenTimeFast = 0.15,
	TweenTimeSlowly = 0.5,

	-- Default easing
	EasingStyle = Enum.EasingStyle.Quad,
	EasingDirection = Enum.EasingDirection.Out,
}

--------------------------------------------------------------------------------
-- FONTS (Mobile-first: minimum 14px for readability)
--------------------------------------------------------------------------------

HUDConstants.Fonts = {
	Primary = Enum.Font.GothamBold,
	Secondary = Enum.Font.Gotham,

	-- Minimum readable on small screens
	SizeSmall = 12,
	SizeMedium = 16,
	SizeLarge = 20,
	SizeTitle = 28,

	-- For overlaid text on bars
	SizeOverlay = 11,
}

return HUDConstants
