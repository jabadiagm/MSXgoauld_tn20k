cls
vlib work
vcom ..\scc_interpo.vhd
if errorlevel 1 goto error_handler
vcom tb.vhd
if errorlevel 1 goto error_handler
vsim -t ns tb -do all.do
goto end

:error_handler
pause

:end
