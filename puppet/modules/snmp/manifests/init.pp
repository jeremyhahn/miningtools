class snmp {

    case $operatingsystem {
        centos, redhat: {
          $package_name = 'net-snmp'
        }
        debian, ubuntu: {
          $package_name = 'snmpd'
        }
    }


    package { 'snmpd':
      name => $package_name,
      ensure => installed,
    }

    file { '/etc/snmp/snmpd.conf':
      path    => '/etc/snmp/snmpd.conf',
      ensure  => file,
      require => Package['snmpd'],
      source  => "puppet:///modules/snmp/snmpd.conf"
    }

    file { 'snmpd':
      path    => '/etc/default/snmpd',
      ensure  => file,
      source  => "puppet:///modules/snmp/snmpd"
    }

    service { 'snmpd':
      ensure    => running,
      enable    => true,
      hasstatus => true,
      subscribe => File['/etc/snmp/snmpd.conf'],
    }
}
