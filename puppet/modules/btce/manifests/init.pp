class btce {

    package { "typhoeus":
        provider => "gem",
        ensure => installed
    }

    file { "btce-zencommand.rb":
        ensure => file,
        path => "/opt/zenoss/libexec/btce-zencommand.rb",
        mode => 770,
        source => "puppet:///modules/btce/btce-zencommand.rb"
    }
}
