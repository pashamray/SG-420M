#!/bin/bash
avrdude -c stk500v2 -P /dev/ttyUSB0 -p m8 -Uflash:w:hex/sg-420m.hex:a
