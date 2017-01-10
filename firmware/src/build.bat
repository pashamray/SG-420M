SET avrtooldir="c:\Program Files\Atmel\AVR Tools"
SET avrasmdir="AvrAssembler"
SET avrtoolinc="Appnotes"

SET target=SG-420M
SET source=Main.asm

del %target%.map
del %target%.lst

%avrtoolbin%\avrasm2.exe -fI  -o %target%.hex -d %target%.obj -e %target%.eep -I "." -I %avrtoolinc% -l %target%.lst  %source%

PAUSE