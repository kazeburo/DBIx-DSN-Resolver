package DBIx::DSN::Resolver;

use strict;
use warnings;
use DBI;
use Socket;
use Carp;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    bless {
        resolver => sub { Socket::inet_ntoa(Socket::inet_aton($_[0])) },
        %args,
    }, $class;
}

sub resolv {
    my $self = shift;
    my $dsn = shift;
    return unless $dsn;

    my ($scheme, $driver, $attr_string, $attr_hash, $driver_dsn)
        = DBI->parse_dsn($dsn) 
            or croak "Can't parse DBI DSN '$dsn'";

    my %driver_hash;
    my @driver_hash_keys; #to keep order
    for my $d ( split /;/, $driver_dsn ) {
        my ( $k, $v) = split /=/, $d, 2;
        $driver_hash{$k} = $v;
        push @driver_hash_keys, $k;
    }
    my $host = $driver_hash{host};
    return $dsn unless $host;

    my $ipaddr = $self->{resolver}->($host)
        or croak "Can't resolv host name: $host, $!";
    $driver_hash{host} = $ipaddr;
    
    $driver_dsn = join ';', map { $_.'='.$driver_hash{$_} } @driver_hash_keys;
    $attr_string = defined $attr_string
        ? '('.$attr_string.')'
        : '';
    sprintf "%s:%s%s:%s", $scheme, $driver, $attr_string, $driver_dsn;
}


1;
__END__

=head1 NAME

DBIx::DSN::Resolver - Resolve hostname within dsn string

=head1 SYNOPSIS

  use DBIx::DSN::Resolver;

  my $dsn = 'dbi:mysql:database=mytbl;host=myserver.example'

  my $resolver = DBIx::DSN::Resolver->new();
  $dsn = $resolver->resolv($dsn);

  is $dsn, 'dbi:mysql:database=mytbl;host=10.0.9.41';

=head1 DESCRIPTION

DBIx::DSN::Resolver parses dsn string and resolves hostname within dsn.
This module allows customize the resolver function.

=head1 CUSTOMIZE RESOLVER

use the resolver argument

  use Net::DNS::Lite qw();
  use Socket;

  $Net::DNS::Lite::CACHE = Cache::LRU->new(
    size => 256,
  );
  $Net::DNS::Lite::CACHE_TTL = 5;
  
  my $resolver = DBIx::DSN::Resolver->new(
      resolver => sub { Socket::inet_ntoa(Net::DNS::Lite::inet_aton(@_)) }
  );
  $dsn = $resolver->resolv($dsn);

Default:

  resolver => sub { Socket::inet_ntoa(Socket::inet_aton(@_)) }

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
