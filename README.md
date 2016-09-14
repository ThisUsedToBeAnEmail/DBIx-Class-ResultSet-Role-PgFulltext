# NAME

DBIx::Class::Role::ResultSet::PgFulltext - PostgreSQL Fulltext searching

# VERSION

Version 0.01

# SYNOPSIS

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

You can optionally pass some search args - normalisation and a row limit

    $rs->pgfulltext_search( $query, { normalisation => { rank => 1, log_unique_words => 1 }, rows => 10 } );

# Description

Full Text Searching (or just text search) provides the capability to identify natural-language documents that satisfy a query, 
and optionally to sort them by relevance to the query. The most common type of search is to find all documents containing given 
query terms and return them in order of their similarity to the query. Notions of query and similarity are very flexible and 
depend on the specific application. The simplest search considers query as a set of words and similarity as the frequency 
of query words in the document.

Textual search operators have existed in databases for years. PostgreSQL has ~, ~\*, LIKE, and ILIKE operators for textual 
data types, but they lack many essential properties required by modern information systems:

There is no linguistic support, even for English. Regular expressions are not sufficient because they cannot easily handle 
derived words, e.g., satisfies and satisfy. You might miss documents that contain satisfies, although you probably would like 
to find them when searching for satisfy. It is possible to use OR to search for multiple derived forms, but this is tedious 
and error-prone (some words can have several thousand derivatives).

They provide no ordering (ranking) of search results, which makes them ineffective when thousands of matching documents are found.

They tend to be slow because there is no index support, so they must process all documents for every search.

Full text indexing allows documents to be preprocessed and an index saved for later rapid searching. Preprocessing includes:

Parsing documents into tokens. It is useful to identify various classes of tokens, e.g. numbers, words, complex words, email addresses, 
so that they can be processed differently. In principle token classes depend on the specific application, but for most purposes it is adequate 
to use a predefined set of classes. PostgreSQL uses a parser to perform this step. A standard parser is provided, and custom parsers can be 
created for specific needs.

Converting tokens into lexemes. A lexeme is a string, just like a token, but it has been normalized so that different forms of the same word 
are made alike. For example, normalization almost always includes folding upper-case letters to lower-case, and often involves removal of suffixes 
(such as s or es in English). This allows searches to find variant forms of the same word, without tediously entering all the possible variants. 
Also, this step typically eliminates stop words, which are words that are so common that they are useless for searching. (In short, then, 
tokens are raw fragments of the document text, while lexemes are words that are believed useful for indexing and searching.) PostgreSQL uses 
dictionaries to perform this step. Various standard dictionaries are provided, and custom ones can be created for specific needs.

Storing preprocessed documents optimized for searching. For example, each document can be represented as a sorted array of normalized lexemes. 
Along with the lexemes it is often desirable to store positional information to use for proximity ranking, so that a document that contains a more "dense" 
region of query words is assigned a higher rank than one with scattered query words.

# pgfulltext\_search

## Column Weights

TODO add mechanism to override column weights

currently they are set as the default 

    {D-weight, C-weight, B-weight, A-weight}
    { D-0.1, C-0.2, B-0.4, A-1.0 }

## Normalisation Options

The default pgfulltext\_search has no normalisation applied.

    log_length - divides the rank by 1 + the logarithm of the document length,
    length - divides the rank by the document length,
    harmonic_distance - divides the rank by the mean harmonic distance between extents (this is implemented only by ts_rank_cd)
    unique_words - divides the rank by the number of unique words in document
    log_unique_words - divides the rank by 1 + the logarithm of the number of unique words in document
    rank - divides the rank by itself + 1

## Dictionaries 

Dictionaries are used to eliminate words that should not be considered in a search (stop words), and to normalize 
words so that different derived forms of the same word will match.

The default dictionary is english, this is a Moo Attribute so you can override in your resultset class it's simple

Here's an example on how to create a Ispell dictionary.

A little bit of psql...

    CREATE TEXT SEARCH DICTIONARY english_ispell (
        TEMPLATE = ispell,
        DictFile = english,
        AffFile = english,
        StopWords = english
    );

And then set the attribute

    has '+dictionary' => (
        default => 'english_ispell'
    );

## Highlighting Results

TODO

# AUTHOR

LNATION, `<thisusedtobeanemail at gmail.com>`

# BUGS

Please report any bugs or feature requests to `bug-dbix-class-role-resultset-pgfulltext at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dbix-Class-Role-ResultSet-PgFulltext](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dbix-Class-Role-ResultSet-PgFulltext).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dbix::Class::Role::ResultSet::PgFulltext

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dbix-Class-Role-ResultSet-PgFulltext](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dbix-Class-Role-ResultSet-PgFulltext)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Dbix-Class-Role-ResultSet-PgFulltext](http://annocpan.org/dist/Dbix-Class-Role-ResultSet-PgFulltext)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Dbix-Class-Role-ResultSet-PgFulltext](http://cpanratings.perl.org/d/Dbix-Class-Role-ResultSet-PgFulltext)

- Search CPAN

    [http://search.cpan.org/dist/Dbix-Class-Role-ResultSet-PgFulltext/](http://search.cpan.org/dist/Dbix-Class-Role-ResultSet-PgFulltext/)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2016 LNATION.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

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
