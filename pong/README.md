
Alchitry Br Pinout
    A48 - r
    A45 - g
    A42 - b
    A39 - hsync
    A36 - vsync
    A33 - paddleleft_up
    A30 - paddleleft_down
    A27 - paddleright_up
    B48 - paddleright_down

Voltage Conversion 3.7V to ~0.5V (r, g, b)

                                        | VGA Internal
                                        |
    r/g/b (3.7V) ---- v^v^v^ -----------|----v^v^v^---- r/g/b (~0.5V)
                     470 ohms    |      |     75 ohms
                                 |      |
                                 <
                    2200 ohms     > 
                                 <
                                  >
                                 |
                                 |
                                ----
                                 GND