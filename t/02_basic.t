use strict;
use Test::More;
use Socket;
use DBIx::DSN::Resolver;

my $r = DBIx::DSN::Resolver->new();
ok($r);

like $r->resolv("dbi:mysql:database=mytbl;host=google.com"),
    qr/^dbi:mysql:database=mytbl;host=[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/;
is $r->resolv("dbi:mysql:database=mytbl;host=127.0.0.1"),
    'dbi:mysql:database=mytbl;host=127.0.0.1';
is $r->resolv("dbi:mysql:database=mytbl"),
    'dbi:mysql:database=mytbl';

eval {
    $r->resolv("dbi:mysql:database=mytbl;host=foo.nonexistent"),
};
ok($@);

eval {
    $r->resolv("bi:mysql:database=mytbl"),
};
ok($@);

like $r->resolv("dbi:mysql:database=mytbl;host=google.com;port=3306"),
    qr/^dbi:mysql:database=mytbl;host=[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+;port=3306$/;
is $r->resolv("dbi:mysql(RaiseError=>1,PrintError=>0):database=mytbl;host=127.0.0.1"),
    'dbi:mysql(RaiseError=>1,PrintError=>0):database=mytbl;host=127.0.0.1';
is $r->resolv("dbi:mysql():database=mytbl;host=127.0.0.1"),
    'dbi:mysql():database=mytbl;host=127.0.0.1';


my $r2 = DBIx::DSN::Resolver->new(
    resolver => sub { "10.9.4.1" }
);
ok($r2);
is $r2->resolv("dbi:mysql:database=mytbl;host=foo.bar.baz"),
    'dbi:mysql:database=mytbl;host=10.9.4.1';

done_testing;

#BEGIN { use_ok 'DBIx::DSN::Resolver' }
