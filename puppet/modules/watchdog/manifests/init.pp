class watchdog {

    package { 'watchdog':
        ensure => present
    }

    file { 'watchdog.conf':
        path    => '/etc/watchdog.conf',
        ensure  => file,
        content  => template('watchdog/watchdog.conf.erb')
    }

    file { '/etc/default/watchdog':
        path    => '/etc/default/watchdog',
        ensure  => file,
        content  => template('watchdog/watchdog.default.erb')
    }

    file { ['/opt/miningtools']:
        ensure => 'directory',
	owner => 'root',
	group => 'root',
	mode => 770
    }
    ->
    file { 'cgminer-watchdog.ini':
        ensure => file,
        path => '/opt/miningtools/cgminer-watchdog.ini',
        content => template('watchdog/cgminer-watchdog.ini.erb')
    }
    ->
    file { 'RubyINI.rb':
        path => '/opt/miningtools/RubyINI.rb',
        ensure => file,
        mode => 770,
        source => 'puppet:///modules/watchdog/RubyINI.rb'
    }
    ->
    file { 'cgminer-watchdog.rb':
        path => '/opt/miningtools/cgminer-watchdog.rb',
	ensure => file,
	mode => 770,
	source => 'puppet:///modules/watchdog/cgminer-watchdog.rb'
    }

    service { 'watchdog':
	ensure => running,
	enable => true,
        hasstatus => true,
	subscribe => File['/etc/watchdog.conf']
    }
}
