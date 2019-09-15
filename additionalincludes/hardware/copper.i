
COP_END_DATA		= $fffffffe	; Wait for end-of-display
COP_WAITBLIT_DATA	= $00010000	; Wait for blitter to be idle


COP_MOVE:       macro
                dc.w (\1)&$1fe,\2
                endm

COP_WAITLINE:   macro
                dc.w ((\1)<<8)+4+1,$fffe
                endm

COP_WAITRAST:   macro
                dc.w ((\1)<<8)+((\2)&$fe)+1,$fffe
                endm

COP_WAITBLIT:   macro
                dc.l COP_WAITBLIT_DATA
                endm

COP_END:        macro
                dc.l COP_END_DATA
                endm
