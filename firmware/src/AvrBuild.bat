@ECHO OFF
"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "C:\project\sg-420m\firmware\src\labels.tmp" -fI -W+ie -C V2E -o "C:\project\sg-420m\firmware\src\SG-420M.hex" -d "C:\project\sg-420m\firmware\src\sg-420m.obj" -e "C:\project\sg-420m\firmware\src\SG-420M.eep" -m "C:\project\sg-420m\firmware\src\SG-420M.map" "C:\project\sg-420m\firmware\src\Main.asm"
