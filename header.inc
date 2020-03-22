; Copyright (C) 2020  Dwscdv3 <dwscdv3@hotmail.com>
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <https://www.gnu.org/licenses/>.



INCLUDE "hardware.inc"



LEFT            EQU 1
UP              EQU 2
RIGHT           EQU 3
DOWN            EQU 4

INITIAL_LENGTH  EQU 4
BOARD_WIDTH     EQU 18
BOARD_HEIGHT    EQU 14
BOARD_SIZE      EQU BOARD_WIDTH * BOARD_HEIGHT
SPEED           EQU 30

SPRITE_FOOD     EQU 11



SECTION "SystemVariables", HRAM

VBlankFlag      db
JoypadState     db
FrameCount      db



SECTION "Variables", HRAM

direction       db
prevDirection   db
head            db
tail            db
length          db
food            db



SECTION "Framebuffer", WRAM0, ALIGN[8]

board           ds 256
scoreDigits     ds 3
