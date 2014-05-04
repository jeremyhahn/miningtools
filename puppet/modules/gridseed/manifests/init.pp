class gridseed {

    package { ['screen', 'mailutils']:
        ensure => present
    }

    file { 'cgminer.conf':
        path    => '/opt/miningtools/cgminer.conf',
        ensure  => file,
        source  => "puppet:///modules/gridseed/cgminer.conf"
    }

    file { 'cgminer':
        path    => '/opt/miningtools/cgminer',
        ensure  => file,
        source  => "puppet:///modules/gridseed/cgminer"
    }

    file { 'cgminer.init':
        path    => '/etc/init.d/cgminer',
        ensure  => file,
        mode => 700,
        source  => "puppet:///modules/gridseed/cgminer.init"
    }

    service { 'cgminer':
        ensure => running,
        enable => true,
        hasstatus => true,
        subscribe => File['cgminer.conf']
    }

    file { 'mathkernel':
        path    => '/etc/init.d/mathkernel',
        ensure  => file,
        mode => 770,
        source  => "puppet:///modules/gridseed/mathkernel"
    }
}
