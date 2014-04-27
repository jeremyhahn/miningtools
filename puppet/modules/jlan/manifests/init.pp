class jlan {

    include ntp
    include ssh
    include snmp
    include ssmtp

    if $operatingsystem == 'centos' or $operatingsystem == 'redhat' {
       $ruby_pkg = "ruby"
    }
    else {
      case $kernelversion {
         "2.6.32": { $ruby_pkg = "ruby1.9.1-full" }
         default: { $ruby_pkg = "ruby1.9.3" }
      }
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

    user { 'zenoss':
	ensure => present,
        password => "*************",
	groups => ['root', 'dialout']
    }

    file { ['/home/zenoss', '/opt/zenoss', '/opt/zenoss/libexec']:
        ensure => "directory",
	owner => "root",
	group => "zenoss",
	mode => 770
    }
}
