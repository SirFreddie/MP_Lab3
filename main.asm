; Empiezo con los vectores de interrupción
.ORG 0x0000
	jmp		start		;dirección de comienzo (vector de reset)  
.ORG 0x0008 
	jmp		_btn_int	;salto atención a rutina de comparación A del timer 0
.ORG 0x001C 
	jmp		_tmr0_int	;salto atención a rutina de comparación A del timer 0


; ---------------------------------------------------------------------------------------
; acá empieza el programa
start:
;configuro los puertos:
;	PB2 PB3 PB4 PB5	- son los LEDs del shield
    ldi		r16,	0xFF
	out		DDRB,	r16			;4 LEDs del shield son salidas
	;OUT		DDRD, r16 ; tweet
	OUT		DDRC, r16
	;SBI		PIND, 3 ; inicializa el tweet apagado
	out		PORTB,	r16			;apago los LEDs

	ldi		r16,	0b00000000	
	out		DDRC,	r16			;3 botones del shield son entradas
;-------------------------------------------------------------------------------------

;Configuro el TMR0 y su interrupcion.
	ldi		r16,	0b00000010	
	out		TCCR0A,	r16			;configuro para que cuente hasta OCR0A y vuelve a cero (reset on compare), ahí dispara la interrupción
	ldi		r16,	0b00000101	
	out		TCCR0B,	r16			;prescaler = 1024
	ldi		r16,	125
	out		OCR0A,	r16			;comparo con 125
	ldi		r16,	0b00000010	
	sts		TIMSK0,	r16			;habilito la interrupción (falta habilitar global)

;-------------------------------------------------------------------------------------

;Configuro el btn y su interrupcion.
	LDI r16, 0b00000010
	STS PCICR, r16 ;habilito el PCINT1
	LDI r16, 0b00001110 
	STS PCMSK1, r16 ;habilito la interrupcion correspondiente a los botones 9, 10, 11

;-------------------------------------------------------------------------------------
;Inicializo algunos registros que voy a usar como variables.
	LDI r24,0x00		;inicializo r24 para un contador genérico
	LDI r26, 0x00 
	LDI r28, 0x00 ;registro que guarda las horas
	LDI r29, 0x00 ;registro que guarda los minutos
	LDI r30, 0x00 ;registro que guardara los segundos
	LDI r31, 0x00 ;registro que guarda los flags
;-------------------------------------------------------------------------------------


;Programa principal ... acá puedo hacer lo que quiero

comienzo:
	sei							;habilito las interrupciones globales(set interrupt flag)

loop1:
	nop
	nop
	nop
	nop
	ori r16, 0xFF
	nop
	nop
	nop
	brne	loop1
loop2:
	nop
	nop
	nop
fin:
	rjmp loop2

;RUTINAS
;-------------------------------------------------------------------------------------

; ------------------------------------------------
; Rutina de atención a la interrupción del Timer0.
; ------------------------------------------------
; recordar que el timer 0 fue configurado para interrumpir cada 125 ciclos (5^3), y tiene un prescaler 1024 = 2^10.
; El reloj de I/O está configurado @ Fclk = 16.000.000 Hz = 2^10*5^3; entonces voy a interrumpir 125 veces por segundo
; esto sale de dividir Fclk por el prescaler y el valor de OCR0A.
; 
; Esta rutina por ahora no hace casi nada, Ud puede ir agregando funcionalidades.
; Por ahora solo: cambia el valor de un LED en la placa, e incrementa un contador en r24.

_tmr0_out:
		OUT SREG, r31				;carga el estado de los flags luego de la interrupcion
	    RETI						;retorno de la rutina de interrupción del Timer0

_tmr0_int:
		IN r31, SREG			;guarda el estado de los flags previo a la interrupcion		
		INC	r24					;cuento cuántas veces entré en la rutina.
		CPI r24, 125			;un segundo
		BRNE _tmr0_out
		SBI	PINB, 2				;toggle LED	
		LDI r24, 0x00
		INC r30					;incremento un segundo
		JMP _tmr0_out

_btn_int:
		IN r31, SREG	;guarda el estado de los flags previo a la interrupcion		
		SBIS PINC, 1	; boton A1
		JMP _btn_A1		; reanuda la interrupcion
		SBIS PINC, 2	; boton A2
		JMP _btn_A2		; pausa la interrupcion
		SBIS PINC, 3	; boton A3
		JMP _btn_A3		; limpia los registros
		JMP _tmr0_out

_btn_A1:
		LDI r16, 0b00000010
		STS TIMSK0, r16 ; habilita nuevamente la interrupcion del timer
		JMP _tmr0_out

_btn_A2:
		LDI r16, 0b00000000
		STS TIMSK0,	r16	; deshabilita la interrupcion del timer
		JMP _tmr0_out

_btn_A3:
		LDI r30, 0x00 ; restablece el timer
		JMP _tmr0_out

