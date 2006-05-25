#!/usr/bin/perl -Tw

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}

use strict;
use Config;
use File::Spec;
use Test::More;

# check that the module is at least available
plan skip_all => "Sys::Syslog was not build" 
  unless $Config{'extensions'} =~ /\bSyslog\b/;

# we also need Socket
plan skip_all => "Socket was not build" 
  unless $Config{'extensions'} =~ /\bSocket\b/;

my $tests;
plan tests => $tests;

BEGIN { $tests = 1 }
# ok, now loads them
eval 'use Socket';
use_ok('Sys::Syslog', ':standard', ':extended', ':macros');

BEGIN { $tests += 1 }
# check that the documented functions are correctly provided
can_ok( 'Sys::Syslog' => qw(openlog syslog syslog setlogmask setlogsock closelog) );


BEGIN { $tests += 1 }
# check the diagnostics
# setlogsock()
eval { setlogsock() };
like( $@, qr/^Invalid argument passed to setlogsock; must be 'stream', 'unix', 'tcp', 'udp' or 'inet'/, 
    "calling setlogsock() with no argument" );

BEGIN { $tests += 3 }
# syslog()
eval { syslog() };
like( $@, qr/^syslog: expecting argument \$priority/, 
    "calling syslog() with no argument" );

eval { syslog(undef) };
like( $@, qr/^syslog: expecting argument \$priority/, 
    "calling syslog() with one undef argument" );

eval { syslog('') };
like( $@, qr/^syslog: expecting argument \$format/, 
    "calling syslog() with one empty argument" );

BEGIN { $tests += 1 }
# setlogsock()
eval { setlogsock() };
like( $@, qr/^Invalid argument passed to setlogsock; must be 'stream', 'unix', 'tcp', 'udp' or 'inet'/, 
    "calling setlogsock() with no argument" );

my $test_string = "uid $< is testing Perl $] syslog(3) capabilities";
my $r = 0;

BEGIN { $tests += 8 }
# try to open a syslog using a Unix or stream socket
SKIP: {
    skip "can't connect to Unix socket: _PATH_LOG unavailable", 8
      unless -e Sys::Syslog::_PATH_LOG();

    # The only known $^O eq 'svr4' that needs this is NCR MP-RAS,
    # but assuming 'stream' in SVR4 is probably not that bad.
    my $sock_type = $^O =~ /^(solaris|irix|svr4|powerux)$/ ? 'stream' : 'unix';

    eval { setlogsock($sock_type) };
    is( $@, '', "setlogsock() called with '$sock_type'" );
    TODO: {
        local $TODO = "minor bug";
        ok( $r, "setlogsock() should return true: '$r'" );
    }

    # open syslog with a "local0" facility
    SKIP: {
        # openlog()
        $r = eval { openlog('perl', 'ndelay', 'local0') } || 0;
        skip "can't connect to syslog", 6 if $@ =~ /^no connection to syslog available/;
        is( $@, '', "openlog() called with facility 'local0'" );
        ok( $r, "openlog() should return true: '$r'" );

        # syslog()
        $r = eval { syslog('info', "$test_string by connecting to a $sock_type socket") } || 0;
        is( $@, '', "syslog() called with level 'info'" );
        ok( $r, "syslog() should return true: '$r'" );

        # closelog()
        $r = eval { closelog() } || 0;
        is( $@, '', "closelog()" );
        ok( $r, "closelog() should return true: '$r'" );
    }
}


BEGIN { $tests += 20 * 6 }
# try to open a syslog using all the available connection methods
for my $sock_type (qw(stream unix inet tcp udp console)) {
    SKIP: {
        # setlogsock() called with an arrayref
        $r = eval { setlogsock([$sock_type]) } || 0;
        skip "can't use '$sock_type' socket", 20 unless $r;
        is( $@, '', "setlogsock() called with ['$sock_type']" );
        ok( $r, "setlogsock() should return true: '$r'" );

        # setlogsock() called with a single argument
        $r = eval { setlogsock($sock_type) } || 0;
        skip "can't use '$sock_type' socket", 18 unless $r;
        is( $@, '', "setlogsock() called with '$sock_type'" );
        ok( $r, "setlogsock() should return true: '$r'" );

        # openlog() without option NDELAY
        $r = eval { openlog('perl', '', 'local0') } || 0;
        skip "can't connect to syslog", 16 if $@ =~ /^no connection to syslog available/;
        is( $@, '', "openlog() called with facility 'local0' and without option 'ndelay'" );
        ok( $r, "openlog() should return true: '$r'" );

        # openlog() with the option NDELAY
        $r = eval { openlog('perl', 'ndelay', 'local0') } || 0;
        skip "can't connect to syslog", 14 if $@ =~ /^no connection to syslog available/;
        is( $@, '', "openlog() called with facility 'local0' with option 'ndelay'" );
        ok( $r, "openlog() should return true: '$r'" );

        # syslog() with negative level, should fail
        $r = eval { syslog(-1, "$test_string by connecting to a $sock_type socket") } || 0;
        like( $@, '/^syslog: invalid level\/facility: /', "syslog() called with level -1" );
        ok( !$r, "syslog() should return false: '$r'" );

        # syslog() with levels "info" and "notice" (as a strings), should fail
        $r = eval { syslog('info,notice', "$test_string by connecting to a $sock_type socket") } || 0;
        like( $@, '/^syslog: too many levels given: notice/', "syslog() called with level 'info,notice'" );
        ok( !$r, "syslog() should return false: '$r'" );

        # syslog() with facilities "local0" and "local1" (as a strings), should fail
        $r = eval { syslog('local0,local1', "$test_string by connecting to a $sock_type socket") } || 0;
        like( $@, '/^syslog: too many facilities given: local1/', "syslog() called with level 'info,notice'" );
        ok( !$r, "syslog() should return false: '$r'" );

        # syslog() with level "info" (as a string), should pass
        $r = eval { syslog('info', "$test_string by connecting to a $sock_type socket (errno=%m)") } || 0;
        is( $@, '', "syslog() called with level 'info' (string)" );
        ok( $r, "syslog() should return true: '$r'" );

        # syslog() with level "info" (as a macro), should pass
        $r = eval { syslog(LOG_INFO(), "$test_string by connecting to a $sock_type socket (errno=%m)") } || 0;
        is( $@, '', "syslog() called with level 'info' (macro)" );
        ok( $r, "syslog() should return true: '$r'" );

        # syslog() with facility "kern" (as a string), should fail
        #$r = eval { syslog('kern', "$test_string by connecting to a $sock_type socket") } || 0;
        #like( $@, '/^syslog: invalid level/facility: kern/', "syslog() called with facility 'kern'" );
        #ok( !$r, "syslog() should return false: '$r'" );

        # syslog() with facility "kern" (as a macro), should fail
        #$r = eval { syslog(LOG_KERN, "$test_string by connecting to a $sock_type socket") } || 0;
        #like( $@, '/^syslog: invalid level/facility: 0/', "syslog() called with facility 'kern'" );
        #ok( !$r, "syslog() should return false: '$r'" );

        SKIP: {
            skip "skipping closelog() tests for 'console'", 2 if $sock_type eq 'console';
            # closelog()
            $r = eval { closelog() } || 0;
            is( $@, '', "closelog()" );
            ok( $r, "closelog() should return true: '$r'" );
        }
    }
}


BEGIN { $tests += 10 }
# setlogsock() with "stream" and an undef path
$r = eval { setlogsock("stream", undef ) } || '';
is( $@, '', "setlogsock() called, with 'stream' and an undef path" );
ok( $r, "setlogsock() should return true: '$r'" );

# setlogsock() with "stream" and an empty path
$r = eval { setlogsock("stream", '' ) } || '';
is( $@, '', "setlogsock() called, with 'stream' and an empty path" );
ok( !$r, "setlogsock() should return false: '$r'" );

# setlogsock() with "stream" and /dev/null
$r = eval { setlogsock("stream", '/dev/null' ) } || '';
is( $@, '', "setlogsock() called, with 'stream' and '/dev/null'" );
ok( $r, "setlogsock() should return true: '$r'" );

# setlogsock() with "stream" and a non-existing file
$r = eval { setlogsock("stream", 'test.log' ) } || '';
is( $@, '', "setlogsock() called, with 'stream' and 'test.log' (file does not exist)" );
ok( !$r, "setlogsock() should return false: '$r'" );

# setlogsock() with "stream" and a local file
SKIP: {
    my $logfile = "test.log";
    open(LOG, ">$logfile") or skip "can't create file '$logfile': $!", 2;
    close(LOG);
    $r = eval { setlogsock("stream", $logfile ) } || '';
    is( $@, '', "setlogsock() called, with 'stream' and '$logfile' (file exists)" );
    ok( $r, "setlogsock() should return true: '$r'" );
    unlink($logfile);
}


BEGIN { $tests += 3 + 4 * 3 }
# setlogmask()
{
    my $oldmask = 0;

    $oldmask = eval { setlogmask(0) } || 0;
    is( $@, '', "setlogmask() called with a null mask" );
    $r = eval { setlogmask(0) } || 0;
    is( $@, '', "setlogmask() called with a null mask (second time)" );
    is( $r, $oldmask, "setlogmask() must return the same mask as previous call");

    my @masks = (
        LOG_MASK(LOG_ERR()), 
        ~LOG_MASK(LOG_INFO()), 
        LOG_MASK(LOG_CRIT()) | LOG_MASK(LOG_ERR()) | LOG_MASK(LOG_WARNING()), 
    );

    for my $newmask (@masks) {
        $r = eval { setlogmask($newmask) } || 0;
        is( $@, '', "setlogmask() called with a new mask" );
        is( $r, $oldmask, "setlogmask() must return the same mask as previous call");
        $r = eval { setlogmask(0) } || 0;
        is( $@, '', "setlogmask() called with a null mask" );
        is( $r, $newmask, "setlogmask() must return the new mask");
        setlogmask($oldmask);
    }
}
