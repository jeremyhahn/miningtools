class ssh {

   ssh_authorized_key { 'mail@jeremyhahn.com':
	ensure => present,
	key => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDJ19LzFDi1uGU+LEA6ZN15D3sYH3az+3dbGqHU8nyMwsW6jLG7yIgcE2oUjxxPE64YFy/txO8Tn9zwWN2n9xQ5xsSPyLGbJj1oK9HME2/fy68bh8/nDWUJo95ssrAvV3OV0f4BzMOI6UJ8j0fSqjYrdWZmr4teRgZ2dNdKt/06MU8u2h8VFEV7uR2i3j41tjZAqmF5fn2CJsnlLLnndvWt0H6gLDUc3WT+dGHhbzu6cXczivERd/2r4tWkYpLDuCfFrM856It8w1Tlba+UoV3QJMi9Q4kbiigtj3ZX2jlid5Yy43EcVoondDiD/h3+AZnLyiaCNW+4pr6xvhFDmkiT',
	type => 'ssh-rsa',
	user => 'root'
    }

    case $operatingsystem {
        centos, redhat: {
          $service_name = 'sshd'
        }
        debian, ubuntu: {
          $service_name = 'ssh'
        }
    }

    package { 'openssh-server':
      ensure => present,
      before => File['/etc/ssh/sshd_config'],
    }
 
    file { '/etc/ssh/sshd_config':
	ensure => file,
	mode => 600,
	source => 'puppet:///modules/ssh/sshd_config'
    }

    service { 'ssh':
        name => $service_name,
	ensure => running,
	enable => true,
	subscribe => File['/etc/ssh/sshd_config']
    }
}

include ssh

