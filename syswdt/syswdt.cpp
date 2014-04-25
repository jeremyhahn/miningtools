/**
 *  The MIT License (MIT)
 *
 *  Copyright (c) 2014 Jeremy Hahn
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 *
 *
 *  Arduino powered System WatchDog Timer (SYSWDT). Uses a transistor switching
 *  circuit to short the POWER pins on a system mainboard when the SYSWDT expires.
 *
 *  CRUDE TEXT SCHEMATIC:
 *  ---------------------
 *                     Base       -> (10k resistor -> syswdt_pin)
 *                   /
 *  NPN Transistor: O - Collector -> (POWER lead 1)
 *                   \
 *                     Emitter    -> (POWER lead 2)
 *
 *  Communication with the SYSWDT timer is handled using Serial via USB. Simply send
 *  the command "syswdt_reset" before "syswdt_timeout" expires to reset the timer.
 *
 *  The Arduino MCU has it's own watchdog built-in. This sketch makes use of it to
 *  guarantee reliability of the Arduino MCU itself. If the built-in WDT expires,
 *  (because the Arduino locks up, etc) the Arduino MCU will reboot itself. The SYSWDT
 *  is independent of the built-in Arduino WDT.
 */

#include <avr/pgmspace.h>
#include <avr/wdt.h>
#include "Arduino.h"

#define DEBUG           0
#define syswdt_pin      40        // Transistor base w/ red LED
#define syswdt_ok_pin   41        // Green LED
#define syswdt_wait_pin 42        // Yellow LED

long syswdt_interval       = 120; // max seconds before expiring syswdt timer
long syswdt_reboot_timeout = 120; // seconds it takes the system to reboot

long syswdt_previous = 0;

void powercycle();
void syswdt_reset();


int main() {

	init();

	setup();

	for (;;)
		loop();

	return 0;
}


void setup() {

	syswdt_interval = syswdt_interval * 1000;

	Serial.begin(115200);

#if DEBUG
	Serial.print("syswdt_interval=");
	Serial.println(syswdt_interval);
	Serial.print("syswdt_reboot_timeout=");
    Serial.println(30);
#endif

    pinMode(syswdt_ok_pin, OUTPUT);
    digitalWrite(syswdt_ok_pin, LOW);

    pinMode(syswdt_wait_pin, OUTPUT);
    digitalWrite(syswdt_wait_pin, LOW);

	pinMode(syswdt_pin, OUTPUT);
	digitalWrite(syswdt_pin, LOW);

	// Startup - simulate pushing the power button (momentarily)
#if DEBUG
	Serial.println("startup");
#endif
	digitalWrite(syswdt_pin, HIGH);
	delay(1000);
	digitalWrite(syswdt_pin, LOW);

	// Wait for the system to boot up.
#if DEBUG
	Serial.println("booting");
#endif
	digitalWrite(syswdt_wait_pin, HIGH);
	delay(syswdt_reboot_timeout * 1000);
	digitalWrite(syswdt_wait_pin, LOW);
	wdt_enable(WDTO_8S);
	syswdt_reset();
}


/**
 * Reset the System WatchDog Timer
 */
void syswdt_reset() {
	digitalWrite(syswdt_ok_pin, HIGH);
	syswdt_previous = millis();
	wdt_reset();
	digitalWrite(syswdt_ok_pin, LOW);
}


/**
 * Listen for WDT reset commands and trigger a powercycle loop
 * if the system watchdog timer expires.
 */
void loop() {

  String cmd = "";
  char character;

  while(Serial.available()) {

      character = Serial.read();
      cmd.concat(character);

      if(cmd.equals("syswdt_reset")) {
    	  syswdt_reset();
    	  delay(10);
    	  Serial.println("OK|SUCCESS");
    	  cmd = "";
      }
      if(character == '\n') {
    	  cmd = "";
      }

      delay(1);
  }

  if((millis() - syswdt_previous) > syswdt_interval) {

#if DEBUG
   Serial.print("millis()=");
   Serial.println(millis());
   Serial.print("syswdt_previous=");
   Serial.println(syswdt_previous);
   Serial.print("syswdt_interval=");
   Serial.println(syswdt_interval);
#endif

	 syswdt_reset();
     powercycle();
     syswdt_reset();
  }

#if DEBUG
	Serial.println("loop");
#endif

  wdt_reset();
  delay(100);
}


/**
 * Powercycle the system. If it doesn't come up before syswdt_reboot_timeout
 * expires, powercycle() will continue being called until another syswdt_reset
 * command is received.
 */
void powercycle() {

    // Shutdown - simulate holding the power button
#if DEBUG
	Serial.println("shutdown");
#endif
	digitalWrite(syswdt_pin, HIGH);
	delay(7000);
	wdt_reset();
	digitalWrite(syswdt_pin, LOW);
	delay(5000);
	wdt_reset();

	// Startup - simulate pushing the power button (momentarily)
#if DEBUG
	Serial.println("startup");
#endif
	digitalWrite(syswdt_pin, HIGH);
	delay(1000);
	digitalWrite(syswdt_pin, LOW);

	// Wait for the system to boot back up.
#if DEBUG
	Serial.println("booting");
#endif
	int i=0;
	while(i < syswdt_reboot_timeout) {
		digitalWrite(syswdt_wait_pin, HIGH);
		wdt_reset();
		delay(1000);
		i++;
	}
	digitalWrite(syswdt_wait_pin, LOW);
}
