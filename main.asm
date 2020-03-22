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



INCLUDE "header.inc"



SECTION "VectorTable", ROM0[$0]

SECTION "INT40", ROM0[$40]
    jp VBlankInterrupt
    
SECTION "INT48", ROM0[$48]
    reti
    
SECTION "INT50", ROM0[$50]
    reti
    
SECTION "INT58", ROM0[$58]
    reti
    
SECTION "INT60", ROM0[$60]
    jp JoypadInterrupt
    


SECTION "Entry", ROM0[$100]
    jp Entry
    nop
    


INCLUDE "memory.asm"
INCLUDE "math.asm"
INCLUDE "rand.asm"



SECTION "Code", ROM0

Entry:
.initRAM
    xor a
    ldh [FrameCount], a
    ldh [rand_seed], a
    ldh [rand_cursor], a
.configureInterrupts
    ld a, P1F_GET_DPAD
    ldh [rP1], a
    ld a, IEF_VBLANK | IEF_HILO
    ldh [rIE], a
    ei
.waitForVBlank
    halt
    nop
.screenOff
    ld a, LCDCF_OFF
    ld [rLCDC], a
.loadTileset
    ld de, _VRAM
    ld hl, Tileset
    ld bc, TilesetEnd - Tileset
    call memcpy
.loadBGMap
    ld de, _SCRN0
    ld hl, BGMap
    ld bc, BGMapEnd - BGMap
    call memcpy
.screenOnAndConfigureDisplay
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BG8000
    ld [rLCDC], a
.useStandardPalette
    ld a, %11100100
    ld [rBGP], a
.soundOff
    ld a, AUDENA_OFF
    ld [rAUDENA], a
.waitForSeed
    halt
    nop
    ldh a, [rand_seed]
    or a
    jr z, .waitForSeed
    
InitGame:
.initStack
    ld sp, $DFFF
.initVariables
    xor a
    ldh [FrameCount], a
    ld a, RIGHT
    ldh [direction], a
    ldh [prevDirection], a
    ld a, BOARD_SIZE / 2 + BOARD_WIDTH / 2 - INITIAL_LENGTH + 1
    ldh [tail], a
    ld a, BOARD_SIZE / 2 + BOARD_WIDTH / 2
    ldh [head], a
    ld a, INITIAL_LENGTH
    ldh [length], a
    ld hl, scoreDigits
    ld [hl], 12
    inc l
    ld [hl], 12
    inc l
    ld [hl], 16
.initBoard
    xor a
    ld bc, BOARD_SIZE
    ld hl, board
    call memset
    ld a, $FF   ; Pad to 256 bytes with $FF to simplify food generation
    REPT 4
        ld [hl+], a
    ENDR
.initSnake
    ld hl, board + BOARD_SIZE / 2 + BOARD_WIDTH / 2 - INITIAL_LENGTH + 1
    ld [hl], 9  ; Tail to Left
    inc l
    ld [hl], 1  ; Left to Right
    inc l
    ld [hl], 1
    inc l
    ld [hl], 7  ; Right to Head
.initFood
    call NewFood
    
Main:
.waitForVBlank
    halt
    nop
.checkIsVBlankInterrupt
    ldh a, [VBlankFlag]
    or a
    jr z, Main
    xor a
    ldh [VBlankFlag], a
    
    call Draw
    call Input
    call Game
    
    jr Main
    
Draw:
    ; Switch to H-Blank interrupt
    ld a, IEF_LCDC
    ldh [rIE], a
    ld a, STATF_MODE00
    ldh [rSTAT], a
.drawScore
    ld de, scoreDigits
    ld hl, _SCRN0 + SCRN_X_B - 3
    ld a, [de]
    ld [hl+], a
    inc e
    ld a, [de]
    ld [hl+], a
    inc e
    ld a, [de]
    ld [hl+], a
.drawBoard
    ld de, board
    ld hl, _SCRN0 + SCRN_VX_B * 3 + 1  ; (0, 0) of the game area
    ld c, BOARD_HEIGHT
    inc c
    jr .y_start
.y_loop
    ld b, BOARD_WIDTH
    inc b
    jr .x_start
.x_loop
    ; Halt if VRAM is not writable currently
    ldh a, [rSTAT]      ; 3
    and STATF_BUSY      ; 2
    jr z, .noHalt       ; 3|2
    halt
    nop
.noHalt
    ld a, [de]      ; 2
    inc e           ; 1
    ld [hl+], a     ; 2
.x_start
    dec b
    jr nz, .x_loop
.x_end
    ld a, l
    add SCRN_VX_B - BOARD_WIDTH
    jr nc, .noCarry
    inc h
.noCarry
    ld l, a
.y_start
    dec c
    jr nz, .y_loop
    
    ; Restore normal interrupt
    ld a, IEF_VBLANK | IEF_HILO
    ldh [rIE], a
    ret
    
Input:
.readDPad
    ld a, P1F_GET_DPAD
    ldh [rP1], a
    REPT 6
        ldh a, [rP1]
    ENDR
    cpl
    and %00001111
    swap a
.storeJoypadState
    ldh [JoypadState], a
    ret
    
; Direction
;   WallCheck
;   regX = newHead
; SelfAteCheck
; FoodCheck
; BodifyPreviousHead
; 
Game:
    call InputHandler
.checkForNextMove
    ldh a, [FrameCount]
    sub SPEED
    ret c
    ldh [FrameCount], a
    
.directionSpecific      ; = 12 (short jump table)
    ldh a, [direction]  ; 3
    add a               ; 1
    xor b               ; 1
    ld c, a             ; 1
    ld hl, .jumpTable   ; 3
    add hl, bc          ; 2
    ldh a, [head]
    ld e, a
    jp hl               ; 1
.jumpTable
    db $40, $40     ; Exception
    jr .left
    jr .up
    jr .right
    jr .down
    
; a, e = index of the head
.left
.left_checkGameOver             ; = 76
    sub BOARD_WIDTH             ; 2   (14x)
    jr nc, .left_checkGameOver  ; 3|2 (14x + 1)
    add BOARD_WIDTH             ; 2
    jp z, GameOver              ; 4|3
.left_returnNewHeadPosition
    dec e
    jr .endDirectionSpecific
    
.up
.up_checkGameOver
    cp BOARD_WIDTH
    jp c, GameOver
.up_returnNewHeadPosition
    sub BOARD_WIDTH
    ld e, a
    jr .endDirectionSpecific
    
.right
.right_checkGameOver
    sub BOARD_WIDTH
    jr nc, .right_checkGameOver
    add BOARD_WIDTH
    cp BOARD_WIDTH - 1
    jp z, GameOver
.right_returnNewHeadPosition
    inc e
    jr .endDirectionSpecific
    
.down
.down_checkGameOver
    cp BOARD_SIZE - BOARD_WIDTH
    jp nc, GameOver
.down_returnNewHeadPosition
    add BOARD_WIDTH
    ld e, a
    jr .endDirectionSpecific
    
; e = index of the new head
.endDirectionSpecific
    ld a, e
    ld hl, food
    cp [hl]
    jr nz, .notFood
.isFood
    call Eat
    jr .moveHead
.notFood
    ld h, HIGH(board)
    ld l, e
    ld a, [hl]
    or a
    jr z, .notBody
.isBody
    ld a, e
    ld hl, tail
    cp [hl]
.notTail     ; Body includes tail
    jp nz, GameOver
.isTail
.notBody
.moveTail
    push de
    call MoveTail
    pop de
.moveHead
    call BodifyPreviousHead
.updateHeadPointer
    ld a, e
    ldh [head], a
.setNewHead
    ldh a, [direction]
    call GetCounterDirection
    add 6
    ld h, HIGH(board)
    ld l, e
    ld [hl], a
.updatePrevDirection
    ldh a, [direction]
    ldh [prevDirection], a
    ret
    
; [corrupt] a, b, c, d, h, l
BodifyPreviousHead:
    ldh a, [head]
    ld h, HIGH(board)
    ld l, a
    ldh a, [direction]
    ld c, a
    ldh a, [prevDirection]
    call GetCounterDirection
.mul5
    ld b, a
    add a
    add a
    add b
    
    add c
    ld d, a
    ld b, HIGH(SpriteMapping)
    ld c, a
    ld a, [bc]
    ld [hl], a
    ret
    
; [in] a = direction
; [out] a = counter direction
GetCounterDirection:
    dec a
    add 2
.mod4_loop
    sub 4
    jr nc, .mod4_loop
    add 5
    ret
    
; [corrupt] a, b
; 39 cycles (worst case)
InputHandler:
    ldh a, [JoypadState] ; 3
    bit PADB_RIGHT, a    ; 2
    jr nz, .right        ; 3|2
    bit PADB_LEFT, a     ;   2
    jr nz, .left         ;   3|2
    bit PADB_UP, a       ;     2
    jr nz, .up           ;     3|2
    bit PADB_DOWN, a     ;       2
    jr nz, .down         ;       3|2
    jr .noChange         ;         3
.right
    ldh a, [direction]   ; 3
    cp LEFT              ; 2
    jr z, .noChange      ; 3|2
    ld a, RIGHT          ;   2
    jr .changeDirection  ;   3
.left
    ldh a, [direction]
    cp RIGHT
    jr z, .noChange
    ld a, LEFT
    jr .changeDirection
.up
    ldh a, [direction]
    cp DOWN
    jr z, .noChange
    ld a, UP
    jr .changeDirection
.down
    ldh a, [direction]
    cp UP
    jr z, .noChange
    ld a, DOWN
    jr .changeDirection
.changeDirection
    ldh [direction], a   ; 3
.noChange
    ret                  ; 4
    
; [out] de, hl = Address of new tail
; [corrupt] a, b, c
; √
MoveTail:
    ldh a, [tail]
    ld d, HIGH(board)
    ld e, a
    ld h, d
    ld l, e
    ld a, [hl]  ; Retrieve tile index of old tail
    ld [hl], 0  ; Clear old tail
    sub 7       ; Convert tile index to direction
    add a
    xor b
    ld c, a
    ld hl, .jumpTable
    add hl, bc
    jp hl
.jumpTable
    jr .left
    jr .up
    jr .right
    jr .down
.left
    dec e
    ld c, 5 * RIGHT
    jr .endSwitch
.up
    ld a, e
    sub BOARD_WIDTH
    ld e, a
    ld c, 5 * DOWN
    jr .endSwitch
.right
    inc e
    ld c, 5 * LEFT
    jr .endSwitch
.down
    ld a, e
    add BOARD_WIDTH
    ld e, a
    ld c, 5 * UP
    jr .endSwitch
.endSwitch
    ; b = 0
    ; c = start point of comparision
    ; de = address of the new tail
.storeNewTailIndex
    ld a, e
    ldh [tail], a
.setNewTail
    ld hl, SpriteMapping
    add hl, bc
    ld a, [de]
    ld b, 6
    jr .findIndex
.findIndex_loop
    inc b
    inc l
.findIndex
    cp [hl]
    jr nz, .findIndex_loop
.findIndex_end
    ld a, b
    ld [de], a
    ret
    
; [corrupt] a, b, c, h, l
; √
Eat:
    call NewFood
    ld hl, length
    inc [hl]
    call UpdateScore
    ret
    
; [corrupt] a, h, l
; 10 cycles + 35 cycles per generate
; √
; TODO: Optimization needed in endgame
NewFood:
    call rand               ; 6 +20
    ld h, HIGH(board)       ; 2
    ld l, a                 ; 1
    ld a, [hl]              ; 2
    or a                    ; 1
    jr nz, NewFood          ; 3|2
    ld a, l                 ;   1
    ldh [food], a           ;   3
    ld [hl], SPRITE_FOOD    ;   3
    ret                     ;   4
    
; [corrupt] a, b, c, h, l
; 121 cycles (worst case)
; √
UpdateScore:
    ldh a, [length]         ; 3
    call toDecimal          ; 6 +94 (worst case)
    ld hl, scoreDigits + 2  ; 3     position of the most right digit
    add 12                  ; 1     12 = Digit 0's index in tileset
    ld [hl-], a             ; 2
    ld a, b                 ; 1
    add 12                  ; 1
    ld [hl-], a             ; 2
    ld a, c                 ; 1
    add 12                  ; 1
    ld [hl-], a             ; 2
    ret                     ; 4
    
GameOver:
    ; TODO
    jp InitGame
    
VBlankInterrupt:
    push af
    ld a, 1
    ldh [VBlankFlag], a
    ldh a, [FrameCount]
    inc a
    ldh [FrameCount], a
    pop af
    reti
    
JoypadInterrupt:
    push af
    ldh a, [rDIV]
    or a
    jr z, .skip
    ldh [rand_seed], a
.skip
    pop af
    reti
    


SECTION "Data", ROM0

; 512 B
Tileset:
INCBIN "tileset.bin"
TilesetEnd:

; 576 B
BGMap:
db  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 11, 12, 12, 16,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 22, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 29,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 25,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 29,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 25,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 29,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 25,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 29,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 25,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 29,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 25,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 29,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 25,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 29,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 25,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 29,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 25,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 29,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 25,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 29,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 25,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 29,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 25,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 29,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 25,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 29,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 25,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 29,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 25,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 28, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 26,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
BGMapEnd:



SECTION "Data_SpriteMapping", ROM0, ALIGN[5]

; 25 B
SpriteMapping:
;                 end lft  tp  rt btm
; from tail to      -   7   8   9  10
; from left to      7   -   4   1   3
; from top to       8   4   -   5   2
; from right to     9   1   5   -   6
; from bottom to   10   3   2   6   - 
db  0,  7,  8,  9, 10
db  7,  0,  4,  1,  3
db  8,  4,  0,  5,  2
db  9,  1,  5,  0,  6
db 10,  3,  2,  6,  0
SpriteMappingEnd:
