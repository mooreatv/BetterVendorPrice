@echo off
rem Installs the addon in the WoW Forever beta; edit WOW below if needed.
set WOW=C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns
rem start clean: older installs left other flavor TOCs and MoLib in there
if exist "%WOW%\BetterVendorPrice" rmdir /s /q "%WOW%\BetterVendorPrice"
xcopy /i /y /s "%~dp0BetterVendorPrice\*.*" "%WOW%\BetterVendorPrice"
