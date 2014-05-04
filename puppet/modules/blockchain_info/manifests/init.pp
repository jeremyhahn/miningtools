class blockchain_info {

    package { 'typhoeus':
        provider => 'gem',
        ensure => installed
    }

    file { "blockchain-info-zencommand.rb":
        ensure => file,
        path => "/opt/zenoss/libexec/blockchain-info-zencommand.rb",
        mode => 770,
        source => "puppet:///modules/blockchain_info/blockchain-info-zencommand.rb"
    }
}
