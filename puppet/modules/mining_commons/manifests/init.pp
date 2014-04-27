class mining_commons {

   file { ['/opt/miningtools', '/opt/miningtools/lib']:
        ensure => "directory",
        mode => 770,
	owner => root,
	group => zenoss
    }
    ->
    file { '/opt/zenoss/libexec/lib':
        ensure => 'link',
        target => '/opt/miningtools/lib',
    }

    file { 'cgminer-api-zencommand.rb':
        ensure => file,
        mode => 0770,
        owner => root,
        group => zenoss,
        path => '/opt/zenoss/libexec/cgminer-api-zencommand.rb',
        source => "puppet:///modules/mining_commons/cgminer-api-zencommand.rb",
        subscribe => File['/opt/zenoss/libexec']
    }

    file { 'CGMinerAPI.rb':
        ensure => file,
        mode => 0770,
        owner => root,
        group => zenoss,
        path => '/opt/miningtools/lib/CGMinerAPI.rb',
        source => "puppet:///modules/mining_commons/CGMinerAPI.rb",
        subscribe => File['/opt/miningtools/lib']
    }

    file { 'Mailer.rb':
        ensure => file,
        mode => 0770,
        owner => root,
        group => zenoss,
        path => '/opt/miningtools/lib/Mailer.rb',
        source => "puppet:///modules/mining_commons/Mailer.rb",
        subscribe => File['/opt/miningtools/lib']
    }

    file { 'RubyINI.rb':
        ensure => file,
        mode => 0770,
        owner => root,
        group => zenoss,
        path => '/opt/miningtools/lib/RubyINI.rb',
        source => "puppet:///modules/mining_commons/RubyINI.rb",
        subscribe => File['/opt/miningtools/lib']
    }

    file { 'miningtools.ini':
        ensure => file,
        mode => 0770,
        owner => root,
        group => zenoss,
        path => '/opt/miningtools/lib/miningtools.ini',
        content => template("mining_commons/miningtools.ini.erb"),
        subscribe => File['/opt/miningtools/lib']
    }
}
