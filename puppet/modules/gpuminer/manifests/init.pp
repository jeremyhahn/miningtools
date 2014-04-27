class gpuminer {

     package { ['libncurses5-dev', 'libcurl4-openssl-dev', 'build-essential', 'libxrandr2',
               'pkg-config', 'libtool', 'xorg', 'xdm', 'linux-headers-2.6.32-5-amd64',
               'autoconf', 'libudev-dev', 'git', 'screen']:
        ensure => present
    }

    file { 'xdm-config' :
        path => '/etc/X11/xdm/xdm-config',
	ensure => file,
	source => 'puppet:///modules/gpuminer/xdm-config'
    }

    file { '/etc/sgminer.conf':
        path    => '/etc/sgminer.conf',
        ensure  => file,
        source  => 'puppet:///modules/gpuminer/sgminer.conf'
    }

    file { 'sgminer':
        path    => '/etc/init.d/sgminer',
        ensure  => file,
        mode => 770,
        source  => 'puppet:///modules/gpuminer/sgminer.init'
    }
 
    service { 'sgminer':
	ensure => running,
	enable => true,
        hasstatus => true,
	subscribe => File['/etc/sgminer.conf']
    }

    file { 'aticonfig-api-zencommand.rb':
        ensure => file,
        mode => 0770,
        owner => root,
        group => zenoss,
        path => '/opt/zenoss/libexec/aticonfig-zencommand.rb',
        source => "puppet:///modules/gpuminer/aticonfig-zencommand.rb",
        subscribe => File['/opt/zenoss/libexec']
    }
}
