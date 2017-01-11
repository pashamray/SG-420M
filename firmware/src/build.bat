SET avrtooldir=c:\progra~2\atmel\avrtoo~1
SET avrasmdir=%avrtooldir%\avrass~1
SET avrincdir=%avrasmdir%\appnotes

SET target=SG-420M
SET source=main.asm

del %target%.map
del %target%.lst

%avrasmdir%\avrasm2.exe -fI -o %target%.hex -d %target%.obj -e %target%.eep -I "." -I "%avrincdir%" -l %target%.lst -D lcdtype="1602" %source%

PAUSE