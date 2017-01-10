cd "c:\Projects\Proj_Spetspribor\Measuring\SG-420M\AVR\"
c:
del "c:\Projects\Proj_Spetspribor\Measuring\SG-420M\AVR\sg-420m.map"
del "c:\Projects\Proj_Spetspribor\Measuring\SG-420M\AVR\sg-420m.lst"
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm2.exe" -fI  -o "c:\Projects\Proj_Spetspribor\Measuring\SG-420M\AVR\sg-420m.hex" -d "c:\Projects\Proj_Spetspribor\Measuring\SG-420M\AVR\sg-420m.obj" -e "c:\Projects\Proj_Spetspribor\Measuring\SG-420M\AVR\sg-420m.eep" -I "c:\Projects\Proj_Spetspribor\Measuring\SG-420M\AVR" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\Appnotes" -l "c:\Projects\Proj_Spetspribor\Measuring\SG-420M\AVR\sg-420m.lst"  "C:\Projects\Proj_Spetspribor\Measuring\SG-420M\AVR\Main.asm"
