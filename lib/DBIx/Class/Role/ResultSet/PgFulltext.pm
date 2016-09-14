package DBIx::Class::Role::ResultSet::PgFulltext;

use Moo::Role;
use Carp qw(croak);

has normalisation_ops => (
    is => 'ro',
    lazy => 1,
    default => sub {
        return {
            log_length => 1,
            length  => 2,
            harmonic_distance => 4,
            unique_words => 8,
            log_unique_words => 16,
            rank => 32,
        };
    }
);

has dictionary => (
    is => 'ro',
    lazy => 1,
    default => q{english_nostop},
);

has column_spec => (
    is => 'rw',
    lazy => 1,
    builder => '_build_column_spec',
);

sub _build_column_spec {
    my ($self) = shift;
   
    my $columns = $self->result_source->columns_info;
    my @column_spec;
    foreach my $name (keys %{$columns}){
        if (my $weight = $columns->{$name}->{pgfulltext}) {
            push @column_spec, { name => $name, weight => $weight };
        }
    
    }

    croak "No pgfulltext column spec found in result class"
        unless @column_spec;

    return \@column_spec;
}

has ts_query => (
    is => 'rw',
    default => sub {
        my $self = shift;
        return sprintf("plainto_tsquery('%s', ?)", $self->dictionary),
    }
);

has ts_vector => (
    is => 'ro',
    lazy => 1,
    builder => '_build_ts_vector',
);

sub _build_ts_vector {
    my $self = shift;
    
    my @vectors;
    foreach my $field (@{$self->column_spec}){
        push @vectors, sprintf(
            q{setweight(to_tsvector('%s', COALESCE(%s, '')), '%s')},
            $self->dictionary,
            $field->{name},
            $field->{weight} || 'A',
        );
    }

    return sprintf('( %s )', join(" || ' ' || ", @vectors));
}

sub pgfulltext_search {
    my ($self, $search_term, $args) = @_;
    
    $args ||= {};
    
    my $column_spec = $self->column_spec;
    my $ts_query = $self->ts_query;
    my $ts_vector = $self->ts_vector;
    
    my $normalisation = $args->{normalisation} 
        ? $self->_normalisation(0, $args)
        : 0;
    
    my $rank = [
        sprintf('ts_rank_cd(%s, %s, %s)', $ts_vector, $ts_query, $normalisation),
            [ ts_query => $search_term ],
    ];

    my %where = (
        -and => [
            \[ $ts_query . ' @@ ' . $ts_vector, [ ts_query => $search_term ] ]
        ],
    );

    my %attributes = (
        order_by => { -desc => \$rank },
    );
    
    if (my $rows = $args->{rows}) {
        $attributes{rows} = $rows;
    }

    return $self->search_rs(\%where, \%attributes);
}

sub _normalisation {
    my ($self, $normalisation, $args) = @_;
    
    foreach my $normalise ( keys $self->normalisation_ops ) {
        if ( $args->{normalisation}->{$normalise} ) {
            $normalisation |= $self->normalisation_ops->{$normalise}
        }
    }
    return $normalisation;
}

1;

=head1 NAME

DBIx::Class::Role::ResultSet::PgFulltext - PostgreSQL Fulltext searching

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

specify which columns in your result class you would like to fulltext search.

    package MyApp::Schema::Result::Test;
    
    extends 'DBIx::Class::Core';
    
    __PACKAGE__->table('test');
    
    __PACKAGE__->add_columns(
        "id",
        { data_type => "integer", is_auto_increment => 1, is_nullable => 0  },
        "title",
        { data_type => "text", pgfulltext => 'A' },
        "content",
        { data_type => "text", pgfulltext => 'B' },
        "content",
        { data_type => "text", pgfulltext => 'C' },
    );

Inherit the role in the resultset
    
    package MyApp::Schema::ResultSet::Test;

    with 'Dbix::Class::Role::ResultSet::PgFulltext';

Then you can fulltext search the resultset

    $rs->pgfulltext_search( $query );

You can optionally pass some search args into pg - normalisation and a row limit

    $rs->pgfulltext_search( $query, { normalisation => { rank => 1, log_unique_words => 1 }, rows => 10 } );

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-role-resultset-pgfulltext at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dbix-Class-Role-ResultSet-PgFulltext>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dbix::Class::Role::ResultSet::PgFulltext


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dbix-Class-Role-ResultSet-PgFulltext>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dbix-Class-Role-ResultSet-PgFulltext>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dbix-Class-Role-ResultSet-PgFulltext>

=item * Search CPAN

L<http://search.cpan.org/dist/Dbix-Class-Role-ResultSet-PgFulltext/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 LNATION.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Dbix::Class::Role::ResultSet::PgFulltext
