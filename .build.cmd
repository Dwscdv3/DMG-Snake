@echo off
rgbasm -o obj/main.o main.asm
rgblink -d -m bin/snake.map -n bin/snake.sym -o bin/snake.gb obj/main.o
rgbfix -v -p 0 -j -k DW -t snake bin/snake.gb
