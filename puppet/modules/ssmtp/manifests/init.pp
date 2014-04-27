class ssmtp {

    package { "ssmtp":
       ensure => present
    }
    ->
    file { "ssmtp.conf":
        ensure => present,
        path => "/etc/ssmtp/ssmtp.conf",
        source => "puppet:///modules/ssmtp/ssmtp.conf"
    }
    ->
    file { "revaliases":
        ensure => present,
        path => "/etc/ssmtp/revaliases",
        source => "puppet:///modules/ssmtp/revaliases"
    }
}
