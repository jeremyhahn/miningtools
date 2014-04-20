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
require 'time_difference'

if ARGV.size < 1
   STDERR.print <<EOF

System WatchDog Timer (SYSWDT) Client v0.1a

Usage:   #{$0} [serial port] [interval]
Example: #{$0} /dev/ttyACM0 10 (reset syswdt every 10 seconds)

EOF
  exit(1)
end

usbdev = ARGV[0]
syswdt_interval = ARGV[1].to_i

class SYSWDT

   @is_connected = false
   @usbdev = nil
   @interval = nil
   @serial = nil
   @last_reset = nil

   def initialize(usbdev, interval)
       @usbdev = usbdev
       @interval = interval
       @last_reset = Time.now
   end

   def connected
       return @is_connected
   end

   def connect(idx = 0)

       return if @is_connected

       @usbdev = "/dev/ttyACM#{idx}";

       begin
          @serial = SerialPort.new(@usbdev, 115200, 8, 1, SerialPort::NONE)
          @is_connected = true
       rescue => e
          # try connecting to ttyACM0 - ttyACM9 until SYSWDT device is found
          if e.message.include? "No such file or directory"
             p e.message
             sleep 1
             if idx < 9
                idx = idx + 1
             else
                idx = 0
             end
             self.connect idx
          end

          puts e.message
       end
       
       puts "Connected to #{@usbdev}"
       self.run
       
   end

   def reset()
      if TimeDifference.between(@last_reset, Time.now).in_seconds > @interval
	        @serial.write "syswdt_reset"
          @last_reset = Time.now
      end
   end

   def run()

       while @is_connected do

         begin
  
           self.reset
           while sp_char = @serial.getc do
              printf("%c", sp_char)
              if sp_char == "\n"
                break
              end
              self.reset
           end
  
         rescue => e
  
            puts e.message
            puts e.backtrace
  
            if e.message.include? "Input/output error"
               @is_connected = false
               self.connect
            end
  
         end

         sleep 0.25

       end

       self.connect
   end

end

syswdt = SYSWDT.new(usbdev, syswdt_interval)
syswdt.connect

