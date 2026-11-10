local import = ...

local Constants = {}

Constants.Version = "1.0.0"

Constants.Fonts = {
	Regular = Font.fromEnum(Enum.Font.BuilderSans),
	Medium = Font.fromEnum(Enum.Font.BuilderSansMedium),
	SemiBold = Font.fromEnum(Enum.Font.BuilderSansBold),
	Bold = Font.fromEnum(Enum.Font.BuilderSansExtraBold),
}

Constants.Durations = {
	Hover = 0.12,
	Press = 0.10,
	Toggle = 0.18,
	Dropdown = 0.20,
	Window = 0.25,
	Tab = 0.18,
	Theme = 0.20,
	Notification = 0.25,
}

Constants.Metrics = {
	WindowRadius = 14,
	ControlRadius = 8,
	PopupRadius = 10,
	TopBarHeight = 56,
	SidebarWidth = 236,
	SidebarCompactWidth = 188,
	CompactBreakpoint = 760,
	MinWindowSize = Vector2.new(480, 320),
	ScreenFraction = 0.96,
	SearchHeight = 38,
	NavItemHeight = 38,
	NavHeaderHeight = 30,
	PagePadding = 28,
	PageHeaderHeight = 72,
	RowHeight = 50,
	RowPadding = 12,
	ControlHeight = 34,
	ToggleWidth = 46,
	ToggleHeight = 26,
	OptionHeight = 32,
	PopupMaxOptions = 6,
	PopupPadding = 4,
	NotificationWidth = 320,
	NotificationMax = 5,
}

Constants.TextSizes = {
	Title = 20,
	PageTitle = 22,
	Body = 15,
	Small = 13,
	Header = 15,
	Control = 14,
}

return Constants
