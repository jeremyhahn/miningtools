#!/usr/bin/ruby

env = {"DISPLAY" => ":0"}
command = "/usr/bin/aticonfig --adapter=all --odgt"

# stdout, stderr pipes
rout, wout = IO.pipe
rerr, werr = IO.pipe

pid = Process.spawn(env, command, :out => wout, :err => werr)
_, status = Process.wait2(pid)

# close write ends so we could read them
wout.close
werr.close

stdout = rout.readlines

stderr = rerr.readlines

# dispose the read ends of the pipes
rout.close
rerr.close

exit_status = status.exitstatus

# parse gpu temps
adapters = Hash.new
i = 0
stdout.each do |line|
  next if line == "\n" || line[/^Adapter/]
  temp = line[/(\d{2}+.\d{2})/] || 0
  adapters["gpu#{i}"] = temp
  i += 1
end

# format for zencommand
zenresponse = "OK|"
i = 0
adapters.each do |key, value|
  zenresponse += "#{key}=#{value}"
  next if i >= adapters.length
  zenresponse += " "
  i += 1
end
puts zenresponse

exit 0