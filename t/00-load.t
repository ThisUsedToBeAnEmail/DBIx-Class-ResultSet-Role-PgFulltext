#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::Role::ResultSet::PgFulltext' ) || print "Bail out!\n";
}

diag( "Testing DBIx::Class::Role::ResultSet::PgFulltext $DBIx::Class::Role::ResultSet::PgFulltext::VERSION, Perl $], $^X" );
