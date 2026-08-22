# Basys-3 Ultrasonic Radar and Laser Turret

This project implements a two-axis ultrasonic scanning and laser-tracking system on a Digilent Basys-3 FPGA. The design is written in synthesizable VHDL and targets the board's 100 MHz clock.

## Features

- Two-axis zigzag scanning with pan and tilt servos
- HC-SR04 ultrasonic distance measurement
- `SCANNING` and `LOCKED` operating states
- Four-digit seven-segment distance display
- Distance-dependent LED and buzzer feedback
- Independent pan/tilt laser-turret aiming with integer lookup tables
- Modular VHDL design with a Basys-3 constraints file

## Project structure

| File | Purpose |
| --- | --- |
| `src/top.vhd` | Connects all modules and controls scanning, target locking, indicators, and the turret. |
| `src/radar.vhd` | Generates the ultrasonic trigger pulse and converts echo duration to distance. |
| `src/servo.vhd` | Produces hobby-servo PWM signals. |
| `src/sevsegdis.vhd` | Multiplexes the four-digit seven-segment display. |
| `src/Laser_Turret_Unit.vhd` | Computes laser-turret pan/tilt commands and controls the laser output. |
| `constraints/constraints.xdc` | Maps the top-level ports to Basys-3 pins. |

## Operating behavior

In `SCANNING`, the sensor platform sweeps horizontally and advances vertically at the end of each horizontal pass. When a valid object is detected between 3 cm and 30 cm, the controller enters `LOCKED`, displays the measured distance, and changes the LED and buzzer feedback according to proximity.

The laser turret uses the measured distance and scanner servo positions to calculate its own pan and tilt targets. It aims at valid targets up to 30 cm away and enables the laser output at distances up to 15 cm.

## Opening in Vivado

1. Create a new RTL project for the Basys-3 board or the `xc7a35tcpg236-1` device.
2. Add every `.vhd` file under `src/` as a design source.
3. Add `constraints/constraints.xdc` as a constraints source.
4. Set `top` as the top-level entity.
5. Run synthesis, implementation, and bitstream generation.

## Hardware notes

- The design expects a 100 MHz system clock.
- Use a suitable external supply for the servos and connect its ground to the Basys-3 ground.
- Confirm the voltage requirements of every connected module before wiring it to the FPGA.
- Never point the laser toward eyes or reflective surfaces.
