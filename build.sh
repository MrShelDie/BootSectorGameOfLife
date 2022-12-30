#!/bin/bash
nasm -f bin game_of_life.asm -o game_of_life.img 
qemu-system-x86_64 -drive file=game_of_life.img,format=raw
