@echo off
rem Installs the addon in each WoW flavor listed below; edit WOW (base install dir) if needed.
set WOW=C:\World of Warcraft
for %%F in (_retail_ _classic_beta_ _forever_) do (
  rem start clean: older installs left other flavor TOCs and MoLib in there
  if exist "%WOW%\%%F\Interface\AddOns\BetterVendorPrice" rmdir /s /q "%WOW%\%%F\Interface\AddOns\BetterVendorPrice"
  xcopy /i /y /s "%~dp0BetterVendorPrice\*.*" "%WOW%\%%F\Interface\AddOns\BetterVendorPrice"
)
