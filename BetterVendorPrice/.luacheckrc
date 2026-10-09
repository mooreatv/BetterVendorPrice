std = "lua51"
max_line_length = 132
self = false

-- Globals the addon defines.
globals = {
  "BetterVendorPrice",
  "betterVendorPriceSaved",
  "SLASH_BetterVendorPrice1",
  "SlashCmdList",
}

-- WoW API and globals the addon only reads.
read_globals = {
  "C_AddOns",
  "C_Item",
  "C_TooltipInfo",
  "CreateFrame",
  "Enum",
  "GameTooltip",
  "GameTooltip_Hide",
  "GetLocale",
  "IsShiftKeyDown",
  "SetTooltipMoney",
  "Settings",
  "TooltipDataProcessor",
}

ignore = {
  "211/_.*",
  "211/L", -- locale stubs before the packager fills them
  "212/_.*",
}
