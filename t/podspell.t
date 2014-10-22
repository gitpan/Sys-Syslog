#!/usr/bin/perl
use strict;
use Test::More;
plan skip_all => "Pod spelling: for developer interest only :)" unless -d 'releases';
eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD spell" if $@;
set_spell_cmd('aspell -l --lang=en');
add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__END__

SAPER
S�bastien
Aperghis
Tramoni
Christiansen
AnnoCPAN
CPAN
README
TODO
AUTOLOADER
API
arrayref
arrayrefs
hashref
hashrefs
lookup
hostname
loopback
netmask
timestamp
INET
BPF
IP
TCP
tcp
UDP
udp
UUCP
FDDI
Firewire
HDLC
IEEE
IrDA
LocalTalk
PPP
unix
Solaris
IRIX
endianness
failover
Failover
logopts
pathname
syslogd
Syslogging
logmask
AIX
SUSv
Tru
UX
VOS
Kobes
Harnisch
NetInfo
VPN
launchd
