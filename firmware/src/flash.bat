SET avrtooldir=c:\progra~2\atmel\avrtoo~1
SET avrflashdir=%avrtooldir%\stk500

SET target=SG-420M

%avrflashdir%\stk500.exe -dATmega8 -ms -e -fC92F -EFF -FC92F -GFF -pf -vf -if%target%.hex -lFC -LFC

PAUSE
