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



SECTION "RandTable", ROM0, ALIGN[8]

RandTable:
db 136,  65,  99,  37, 222,  27,  84,  66, 144, 212, 197, 200, 210,  38,  81, 254
db 190,  59, 126, 155, 107, 206,   6,  68, 150, 192, 152, 142, 106, 104,  35, 157
db 194, 247, 199,  86, 178,  58,  21, 198, 148, 122, 118,  95,   3,  26, 167, 180
db  28, 108, 125,  40,  48, 111, 228, 204, 253,  94, 175,  87, 166, 219, 235, 105
db 218, 103,  74,  54, 135,  77, 134, 187, 146,  55,  17,  15, 153,  80, 100,  22
db  63, 240, 120,  93, 250,  36,   0, 161,   1, 255, 130,  60, 174, 195,  50,  13
db 173, 119, 168,  62, 172, 213,   8, 138,  33, 216, 116, 188, 139, 237,  19, 251
db  82,  25,  89, 203,  39, 232,  45, 154, 242, 202, 223, 170, 229,  14,   5, 227
db  83, 177, 193,  46, 115, 164, 132, 185,   9,  75, 151, 165, 128, 127, 131,  18
db 220, 176, 189,  79, 215, 209, 160,  61, 244,  78, 252, 241,  97,  29,  11, 133
db  64,  20, 163,  57,  10,  91, 201, 238, 114,  88,  98,   4, 117,  92, 109,  71
db  43, 169, 230, 129,  69,  32,  90,  56,  70, 245, 214, 101, 207, 236, 179,  96
db 141, 196,  76, 145, 239, 102,  31,  72, 249, 233, 183, 205,  49,  85, 156, 158
db 113,  52, 181, 184, 171, 140, 191,  12, 221,  16, 182, 143, 112,  47,  24,  51
db  67,  73, 208, 246,  30,  23, 162, 123, 248, 225, 149, 121, 211, 217, 124,  44
db 137,   7, 231, 110, 226, 186, 147, 224,  53,  42, 243,  34, 159,  41,   2, 234
RandTableEnd:



SECTION "Code", ROM0

; [out] a = random number
; [corrupt] h, l
; 20 cycles
rand:
    ldh a, [rand_cursor]    ; 3
    ld l, a                 ; 1
    ldh a, [rand_seed]      ; 3
    add l                   ; 1
    ldh [rand_cursor], a    ; 3
    ld l, a                 ; 1
    ld h, HIGH(RandTable)   ; 2
    ld a, [hl]              ; 2
    ret                     ; 4
    


SECTION "Variables", HRAM

rand_cursor     db
rand_seed       db
