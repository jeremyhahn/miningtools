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
 *  This script is called by the Linux WatchDog (softdog) service. If the hashrate
 *  falls below the specified alarm rate, the scripts aborts with a non-zero
 *  exit code, signaling watchdog to reboot the system.
 */
=end

require 'socket'
require 'net/smtp'
require_relative 'lib/RubyINI'
require_relative 'lib/Mailer'

class CGMinerWatchdog

  @@supported_metrics = ["mhs_av", "mhs_5s"]
  @@selected_metric = nil
  @@alarm_hashrate = nil
  @@log = nil
  @@hostname = nil
  @@mailer_hostname = nil
  @@mailer_port = nil
  @@mailer_starttls = false
  @@mailer_username = nil
  @@mailer_password = nil

  def initialize(ini, log)
      @@log = log
      @@hostname = ini.local.hostname
      @@selected_metric = ini.watchdog.selected_metric
      @@alarm_hashrate = ini.watchdog.alarm_hashrate.to_f
      @@alarm_recipient = ini.watchdog.alarm_recipient
      @@mailer_hostname = ini.smtp.hostname
      @@mailer_port = ini.smtp.port.to_i
      @@mailer_starttls = ini.smtp.starttls
      @@mailer_username = ini.smtp.username
      @@mailer_password = ini.smtp.password
      socket = TCPSocket.open(ini.cgminer.hostname, ini.cgminer.port)
      socket.write "summary"
      @response = socket.read
      socket.close     
  end

  def parse(metric)
    metric_pieces = metric.split("=")
    name = metric_pieces[0].downcase.sub(/ /, "_").sub(/%/, "")
    return if !@@supported_metrics.include? name
    value = metric_pieces[1].to_f
    email_and_exit 10001 if value.nil?
    if name == @@selected_metric
       if value < @@alarm_hashrate
          flag = @@log.read(1)
          if flag.nil?
             @@log.write "1"
             @@log.close
             email_warning_and_exit 0, value
          else
             email_error_and_exit 10002, value
          end
       end
       @@log.truncate 0
       @@log.close
       exit 0
    end
  end

  def test()
    pieces = @response.split("|")
    summary = pieces[1]
    summary_pieces = summary.split(",")
    summary_pieces.each do |metric|
      parse metric
    end
  end

  def email_warning_and_exit(code, value = 0)
    message = <<MESSAGE
The CGMiner WatchDog has detected the following warning. Allowing grace period of 1 interval.

Alarm Hashrate: #{@@alarm_hashrate}
#{@@selected_metric}: #{value}
MESSAGE
    email_and_exit code, "CGMiner Watchdog Warning", message
  end

  def email_error_and_exit(code, value = 0)
    message = <<MESSAGE
The CGMiner WatchDog has failed with exit code #{code}. The server is being rebooted.

Alarm Hashrate: #{@@alarm_hashrate}
#{@@selected_metric}: #{value}
MESSAGE
     email_and_exit code, "CGMiner Watchdog Failure", message
  end

  def email_and_exit(code, subject, message)
    mailer = Mailer.new @@mailer_hostname, @@mailer_port
    params = {
      :from => "cgminer-watchdog@#{@@hostname}",
      :to => @@alarm_recipient,
      :subject => subject,
      :message => message,
      :username => @@mailer_username,
      :password => @@mailer_password,
      :starttls => @@mailer_starttls
    }
    mailer.send params
    exit code
  end

end

ini = RubyINI.load("/opt/miningtools/lib/miningtools.ini")
tmpfile_path = ini.watchdog.tmpfile
logfile_path = ini.watchdog.logfile

log = File.open(logfile_path, "a")
tmpfile = nil

if !File.exists? tmpfile_path
   tmpfile = File.new(tmpfile_path, "w")
   log << "[WatchDog] Initialized\n"
   exit 0
else
   tmpfile = File.open(tmpfile_path, "r+")
end

log << "[WatchDog] Feeding cgminer watchdog\n"
log.close

cgminer_watchdog = CGMinerWatchdog.new ini, tmpfile
cgminer_watchdog.test

tmpfile.close
cgminer_watchdog.email_error_and_exit 10003


