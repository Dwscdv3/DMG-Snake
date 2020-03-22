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



SECTION "Code", ROM0

; [in] a = binary integer
; [out] a = 10^0 place
; [out] b = 10^1 place
; [out] c = 10^2 place
; 94 cycles (worst case)
toDecimal:
    ld b, 0         ; 2
    ld c, 0         ; 2
.hundreds
    cp 100          ; 1
    jr c, .tens     ; 3|2
    sub 100         ;   1
    inc c           ;   1
    jr .hundreds    ;   3
.tens
    cp 10           ; 1
    ret c           ; 5|2
    sub 10          ;   1
    inc b           ;   1
    jr .tens        ;   3
