class zenoss {

      user { 'zenoss':
	ensure => present,
	password => '$1$Q5NDIs6t$gy7hZvFiVWWp6Ja57dxBD/',
	groups => ['root', 'dialout']
      }

      file { ['/home/zenoss', '/opt/zenoss', '/opt/zenoss/libexec']:
        ensure => "directory",
	owner => "zenoss",
	group => "zenoss",
	mode => 770
      }
}
