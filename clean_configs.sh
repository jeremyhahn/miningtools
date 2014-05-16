#!/bin/bash

sed -i 's/^hostname\s*=\s*.*$/hostname = localhost/g' lib/miningtools.ini
sed -i 's/^port\s*=\s*.*$/port = 0/g' lib/miningtools.ini
sed -i 's/^fqdn\s*=\s*.*$/fqdn = localhost.localdomain/' lib/miningtools.ini
sed -i 's/^alarm_recipient\s*=\s*.*$/alarm_recipient = root@localhost/' lib/miningtools.ini
sed -i 's/^username\s*=\s*.*$/username = *************/' lib/miningtools.ini
sed -i 's/^password\s*=\s*.*$/password = *************/' lib/miningtools.ini
sed -i 's/^notifications\s*=\s*.*$/notifications = root@localhost/' lib/miningtools.ini
sed -i 's/^scrypt_miners\s*=\s*.*$/scrypt_miners = scrypt_miner01.localdomain, scrypt_miner02.localdomain/' lib/miningtools.ini
sed -i 's/^scryptn_miners\s*=\s*.*$/scryptn_miners = scryptn_miner01.localdomain, scryptn_miner02.localdomain/' lib/miningtools.ini
sed -i 's/^apikey=.*$/apikey=**************/g' lib/miningtools.ini
sed -i 's/^secret=.*$/secret=**************/g' lib/miningtools.ini
sed -i 's/^address\s*=.*$/address=**************/g' lib/miningtools.ini

sed -i 's/^hostname\s*=\s*.*$/hostname = localhost/g' puppet/modules/mining_commons/templates/miningtools.ini.erb
sed -i 's/^fqdn\s*=\s*.*$/fqdn = localhost.localdomain/' puppet/modules/mining_commons/templates/miningtools.ini.erb
sed -i 's/^alarm_recipient\s*=\s*.*$/alarm_recipient = root@localhost/' puppet/modules/mining_commons/templates/miningtools.ini.erb

sed -i 's/^port\s*=\s*.*$/port = 25/' puppet/modules/mining_commons/templates/miningtools.ini.erb
sed -i 's/^username\s*=\s*.*$/username = *************/' puppet/modules/mining_commons/templates/miningtools.ini.erb
sed -i 's/^password\s*=\s*.*$/password = *************/' puppet/modules/mining_commons/templates/miningtools.ini.erb
sed -i 's/^notifications\s*=\s*.*$/notifications = *************/' puppet/modules/mining_commons/templates/miningtools.ini.erb
sed -i 's/^miners\s*=\s*.*$/miners = miner01.localdomain, miner02.localdomain, miner02.localdomain/' puppet/modules/mining_commons/templates/miningtools.ini.erb
sed -i 's/^apikey=.*$/apikey=**************/g' puppet/modules/mining_commons/templates/miningtools.ini.erb
sed -i 's/^secret=.*$/secret=**************/g' puppet/modules/mining_commons/templates/miningtools.ini.erb

sed -i 's/^\s*password\s*=>\s.*$/        password => "*************",/' puppet/modules/jlan/manifests/init.pp
sed -i 's/^root:.*$/root:user@domain.com:mail.domain.com:25/g' puppet/modules/ssmtp/files/revaliases

sed -i 's/^root=.*$/root=user@domain.com/g' puppet/modules/ssmtp/files/ssmtp.conf
sed -i 's/^mailhub=.*$/mailhub=mail.domain.com:25/g' puppet/modules/ssmtp/files/ssmtp.conf
sed -i 's/^hostname=.*$/hostname=user@domain.com/g' puppet/modules/ssmtp/files/ssmtp.conf
sed -i 's/^AuthUser=.*$/AuthUser=user@domain.com/g' puppet/modules/ssmtp/files/ssmtp.conf
sed -i 's/^AuthPass=.*$/AuthPass=**************/g' puppet/modules/ssmtp/files/ssmtp.conf

rm -rf puppet/modules/.git
rm puppet/modules/site.pp
rm puppet/modules/gpuminer/files/AMD-APP-SDK-v2.9-lnx64.tgz
rm puppet/modules/gpuminer/files/amd-catalyst-13.12-linux-x86.x86_64.run
rm puppet/modules/gpuminer/files/amd-driver-installer-14.10.1006-x86.x86_64.zip
rm puppet/modules/gpuminer/files/amd-driver-installer-14.10.1006-x86.x86_64.run

