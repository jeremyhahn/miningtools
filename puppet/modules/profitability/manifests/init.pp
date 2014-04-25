class profitability {

    file { "profitability-zencommand.rb":
         ensure => file,
         path => "/opt/zenoss/libexec/profitability-zencommand.rb",
         mode => 770,
         source => "puppet:///modules/profitability/profitability-zencommand.rb"
    }
}
