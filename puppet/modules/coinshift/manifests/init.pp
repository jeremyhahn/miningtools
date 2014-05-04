class coinshift {

    file { "coinshift-zencommand.rb":
       ensure => file,
       path => "/opt/zenoss/libexec/coinshift-zencommand.rb",
       mode => 770,
       source => "puppet:///modules/coinshift/coinshift-zencommand.rb"
    }
}

