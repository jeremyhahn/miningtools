node 'puppetmaster.home.jlan' {
     include jlan
}

node 'fs.home.jlan' {
    include jlan
    include mining_commons
    include profitability
}

node 'mantaray.home.jlan' {
    include jlan 
}

node 'rpi.home.jlan' {
    include jlan
}

node 'zenoss.home.jlan' {
    include jlan
    include mining_commons
    include wafflepool
    include profitability
}

node 'gpuminer01.home.jlan' {
    include jlan
    include gpuminer
    include syswdt
    include watchdog
    include mining_commons
}

node 'gpuminer02.home.jlan' {
    include jlan
    include gpuminer
    include syswdt
    include watchdog
    include mining_commons
}

node 'gridseed01.home.jlan' {
    include jlan
    include gridseed
    include syswdt
    include watchdog
    include mining_commons
}


