for %%x in (_retail_ _classic_ _classic_beta_ _ptr_) do (
echo Installing for %%x
xcopy /i /y BetterVendorPrice\*.* "C:\Program Files (x86)\World of Warcraft\%%x\Interface\Addons\BetterVendorPrice"
)
