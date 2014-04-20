class gridseed {

    file { 'cgminer-api-zencommand.rb':
        ensure => file,
        mode => 0770,
        owner => root,
        group => zenoss,
        path => '/opt/zenoss/libexec/cgminer-api-zencommand.rb',
        source => "puppet:///modules/gridseed/cgminer-api-zencommand.rb",
	subscribe => File['/opt/zenoss/libexec']
    }

    file { 'miner.conf':
        path    => '/opt/minepeon/etc/miner.conf',
        ensure  => file,
        source  => "puppet:///modules/gridseed/cgminer.conf"
    }

    file { 'cgminer':
        path    => '/opt/minepeon/bin/cgminer',
        ensure  => file,
        source  => "puppet:///modules/gridseed/cgminer"
    }
}
