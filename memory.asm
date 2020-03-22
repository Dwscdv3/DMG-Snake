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

; [in] a = byte value
; [in] bc = byte count
; [in] hl = dest address
; [corrupt] bc, hl
memset:
    inc c
    inc b
    jr .start
.loop:
    ld [hl+], a
.start:
    dec c
    jr nz, .loop
    dec b
    jr nz, .loop
ret

; [in] bc = byte count
; [in] de = dest address
; [in] hl = src address
; [corrupt] bc, de, hl
memcpy:
    inc c
    inc b
    jr .start
.loop:
    ld a, [hl+]
    ld [de], a
    inc de
.start:
    dec c
    jr nz, .loop
    dec b
    jr nz, .loop
ret
