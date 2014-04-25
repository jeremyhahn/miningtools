class wafflepool {

    file { "wafflepool-zencommand.rb":
       ensure => file,
       path => "/opt/zenoss/libexec/wafflepool-zencommand.rb",
       mode => 770,
       source => "puppet:///modules/wafflepool/wafflepool-zencommand.rb"
    }
}
