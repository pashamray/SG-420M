#!/bin/bash
gavrasm -seb Main.asm
if [ "$?" = "0" ]; then
  echo "Shell: No error during assembling"
else
  echo "Shell: Error during assembly"
  nano "Main.err"
fi
