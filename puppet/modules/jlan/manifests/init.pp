class jlan {

    include ntp
    include ssh
    include snmp
    include zenoss

    case $kernelversion {
        "2.6.32": { $ruby_pkg = "ruby1.9.1-full" }
        default: { $ruby_pkg = "ruby1.9.3" }
    }

    package { "$ruby_pkg":
        ensure => present
    }

    file { 'motd':
        ensure => file,
	force => true,
        path => '/etc/motd',
        content => template('jlan/motd.erb')
    }
}
