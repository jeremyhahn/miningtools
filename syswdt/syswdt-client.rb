#!/usr/bin/ruby

=begin
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
 *  Arduino powered System WatchDog Timer (SYSWDT) client.
 *
 *  This script sends the command "syswdt_reset" to the Arduino powered
 *  System WatchDog Timer. If the Arduino does not receive the command 
 *  within the configured timeout (2 minutes by default), the system will
 *  be powercycled.
 */
=end

require 'rubygems'
require 'serialport'

if ARGV.size < 1
   STDERR.print <<EOF

System WatchDog Timer (SYSWDT) Client v0.1a

Usage:   #{$0} [serial port]
Example: #{$0} /dev/ttyACM0

EOF
  exit(1)
end

usbdev = ARGV[0]

class SYSWDT

   @usbdev = nil
   @serial = nil

   def initialize(usbdev)
       @usbdev = usbdev
   end

   def connect(idx = 0)

       begin
          @serial = SerialPort.new(@usbdev, 115200, 8, 1, SerialPort::NONE)
          @serial.read_timeout = 2000          
       rescue => e
         
         p e.message
         
          # try connecting to ttyACM0 - ttyACM9 until SYSWDT device is found
          @usbdev = "/dev/ttyACM#{idx}";
          if e.message.include? "No such file or directory"
             p e.messageex
             sleep 1
             if idx < 9
                idx = idx + 1
             else
                idx = 0
             end
             self.connect idx
          end
       end
   end

   def reset()
       @serial.write "syswdt_reset"
       #puts @serial.read
       while sp_char = @serial.getc do
          printf("%c", sp_char)
          break if sp_char == "\n"
       end

   end
end

syswdt = SYSWDT.new(usbdev)
syswdt.connect
syswdt.reset
