class coinsolver {

    file { "coinsolver-zencommand.rb":
       ensure => file,
       path => "/opt/zenoss/libexec/coinsolver-zencommand.rb",
       mode => 770,
       source => "puppet:///modules/coinsolver/coinsolver-zencommand.rb"
    }
}

