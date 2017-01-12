@ECHO OFF
"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "C:\GIT\sg-420m\firmware\src\labels.tmp" -fI -W+ie -C V2E -o "C:\GIT\sg-420m\firmware\src\SG-420M.hex" -d "C:\GIT\sg-420m\firmware\src\SG-420M.obj" -e "C:\GIT\sg-420m\firmware\src\SG-420M.eep" -m "C:\GIT\sg-420m\firmware\src\SG-420M.map" "C:\GIT\sg-420m\firmware\src\Main.asm"
