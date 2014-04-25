class syswdt {

      file { 'syswdt-client':
        ensure => file,
        mode => 0777,
        path => '/opt/zenoss/libexec/syswdt-client',
        source => "puppet:///modules/syswdt/syswdt-client-$architecture",
	subscribe => File['/opt/zenoss/libexec']
      }
}
