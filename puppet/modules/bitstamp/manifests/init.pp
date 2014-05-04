class bitstamp {

    package { 'typhoeus':
        provider => 'gem',
        ensure => installed
    }

    file { "bitstamp-zencommand.rb":
        ensure => file,
        path => "/opt/zenoss/libexec/bitstamp-zencommand.rb",
        mode => 770,
        source => "puppet:///modules/bitstamp/bitstamp-zencommand.rb"
    }
}
