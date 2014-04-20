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

class CGMinerAPI

  @@supported_metrics = ["mhs_av", "mhs_5s"]
  @@selected_metric = nil
  @@alarm_hashrate = nil
  @@log = nil

  def initialize(hostname, port, selected_metric, alarm_hashrate, log)
      socket = TCPSocket.open(hostname, port)
      socket.write "summary"
      @response = socket.read
      socket.close
      @@selected_metric = selected_metric
      @@alarm_hashrate = alarm_hashrate.to_f
      @@log = log
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
             email_and_exit 0, value, true
          else
            email_and_exit 10002, value
          end
       end
       @@log.truncate 0
       @@log.close
       exit 0
    end
  end

  def summary()

    pieces = @response.split("|")
    summary = pieces[1]
    summary_pieces = summary.split(",")

    summary_pieces.each do |metric|
      parse metric
    end
  end

  def email_and_exit(code, value = 0, warn = false)

    if warn

       message = <<MESSAGE
Date: #{Time.new}
From: root <root@localhost>
To: Jeremy Hahn <mail@jeremyhahn.com>
Subject: CGMiner WatchDog

The CGMiner WatchDog has detected the following warning. Allowing grace period of 1 interval.

Alarm Hashrate: #{@@alarm_hashrate}
#{@@selected_metric}: #{value}

MESSAGE
    else   

      message = <<MESSAGE
Date: #{Time.new}
From: root <root@localhost>
To: Jeremy Hahn <mail@jeremyhahn.com>
Subject: CGMiner WatchDog

The CGMiner WatchDog has failed with exit code #{code}. The server is being rebooted.

Alarm Hashrate: #{@@alarm_hashrate}
#{@@selected_metric}: #{value}

MESSAGE

    end

    smtp = Net::SMTP.new 'mail.makeabyte.com', 587
    smtp.enable_starttls
    smtp.start("mail.makeabyte.com", "mail@jeremyhahn.com", "*************", :login) do
      smtp.send_message(message, "root@localhost", "mail@jeremyhahn.com")
    end

    @@log.close
    exit code
  end
end

hostname = "localhost"
port = 4028
selected_metric = "mhs_5s"
alarm_hashrate = "2.5"
tmpfile_path = "/tmp/cgminer_watchdog"
logfile_path = "/var/log/syslog"

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

cgminer = CGMinerAPI.new hostname, port, selected_metric, alarm_hashrate, tmpfile
cgminer.summary
cgminer.email_and_exit 10003
