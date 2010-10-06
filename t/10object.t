#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More tests => 37;
use WWW::Scraper::ISBN;

###########################################################

my $DRIVER          = 'Yahoo';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '0307474275' => [
        [ 'is',     'isbn',         '9780307474278'     ],
        [ 'is',     'isbn10',       '0307474275'        ],
        [ 'is',     'isbn13',       '9780307474278'     ],
        [ 'is',     'ean13',        '9780307474278'     ],
        [ 'is',     'title',        'The DaVinci Code'  ],
        [ 'is',     'author',       'Dan Brown'         ],
        [ 'is',     'publisher',    undef               ],
        [ 'is',     'pubdate',      'March 2009'        ],
        [ 'is',     'binding',      'Paperback'         ],
        [ 'is',     'pages',        '597'               ],
        [ 'is',     'width',        undef               ],
        [ 'is',     'height',       undef               ],
        [ 'is',     'weight',       undef               ],
        [ 'like',   'image_link',   qr!9780307474278!   ],
        [ 'like',   'thumb_link',   qr!9780307474278!   ],
        [ 'like',   'book_link',    qr|the-davinci-code|]
    ],
    '9780596001735' => [
        [ 'is',     'isbn',         '9780596001735'     ],
        [ 'is',     'isbn10',       undef               ],
        [ 'is',     'isbn13',       '9780596001735'     ],
        [ 'is',     'ean13',        '9780596001735'     ],
        [ 'is',     'title',        'Perl Best Practices'   ],
        [ 'is',     'author',       'Damian Conway'     ],
        [ 'is',     'publisher',    undef               ],
        [ 'is',     'pubdate',      'August 2005'       ],
        [ 'is',     'binding',      'Paperback'         ],
        [ 'is',     'pages',        517                 ],
        [ 'is',     'width',        undef               ],
        [ 'is',     'height',       undef               ],
        [ 'is',     'weight',       undef               ],
        [ 'like',   'image_link',   qr!9780596001735!   ],
        [ 'like',   'thumb_link',   qr!9780596001735!   ],
        [ 'like',   'book_link',    qr|perl-best-practices| ]
    ],
);

my $tests = 0;
for my $isbn (keys %tests) { $tests += scalar( @{ $tests{$isbn} } ) + 2 }


###########################################################

my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

SKIP: {
	skip "Can't see a network connection", $tests+1   if(pingtest($CHECK_DOMAIN));

	$scraper->drivers($DRIVER);

    for my $isbn (keys %tests) {
        my $record = $scraper->search($isbn);
        my $error  = $record->error || '';

        SKIP: {
            skip "Website unavailable", scalar(@{ $tests{$isbn} }) + 2   
                if($error =~ /website appears to be unavailable/);

            unless($record->found) {
                diag($record->error);
            }

            is($record->found,1);
            is($record->found_in,$DRIVER);

            my $book = $record->book;
            for my $test (@{ $tests{$isbn} }) {
                if($test->[0] eq 'ok')          { ok(       $book->{$test->[1]},             ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'is')       { is(       $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'isnt')     { isnt(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'like')     { like(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'unlike')   { unlike(   $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); }

            }

            #use Data::Dumper;
            #diag("book=[".Dumper($book)."]");
        }
    }
}

###########################################################

# crude, but it'll hopefully do ;)
sub pingtest {
    my $domain = shift or return 0;
    my $cmd =   $^O =~ /solaris/i                           ? "ping -s $domain 56 1" :
                $^O =~ /dos|os2|mswin32|netware|cygwin/i    ? "ping -n 1 $domain "
                                                            : "ping -c 1 $domain >/dev/null 2>&1";

    system($cmd);
    my $retcode = $? >> 8;
    # ping returns 1 if unable to connect
    return $retcode;
}
