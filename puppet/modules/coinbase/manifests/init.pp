class coinbase {

    package { 'coinbase':
        provider => 'gem',
        ensure => installed
    }

    package { 'typhoeus':
        provider => 'gem',
        ensure => installed
    }

    file { "coinbase-zencommand.rb":
        ensure => file,
        path => "/opt/zenoss/libexec/coinbase-zencommand.rb",
        mode => 770,
        source => "puppet:///modules/coinbase/coinbase-zencommand.rb"
    }
}
