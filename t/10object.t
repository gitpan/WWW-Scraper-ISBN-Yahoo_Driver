#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More tests => 37;
use WWW::Scraper::ISBN;

###########################################################

my $DRIVER          = 'Yahoo';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '0307474275' => [
        [ 'is',     'isbn',         '9780307474278'         ],
        [ 'is',     'isbn10',       '0307474275'            ],
        [ 'is',     'isbn13',       '9780307474278'         ],
        [ 'is',     'ean13',        '9780307474278'         ],
        [ 'is',     'title',        'The DaVinci Code'      ],
        [ 'is',     'author',       'Dan Brown'             ],
        [ 'is',     'publisher',    'Anchor'                ],
        [ 'is',     'pubdate',      undef                   ],
        [ 'is',     'binding',      'Mass Market Paperback' ],
        [ 'is',     'pages',        undef                   ],
        [ 'is',     'width',        undef                   ],
        [ 'is',     'height',       undef                   ],
        [ 'is',     'weight',       undef                   ],
        [ 'like',   'image_link',   qr!949701887_640!       ],
        [ 'like',   'thumb_link',   qr!949701887_640!       ],
        [ 'like',   'book_link',    qr|the-davinci-code|    ]
    ],
    '9780596001735' => [
        [ 'is',     'isbn',         '9780596001735'         ],
        [ 'is',     'isbn10',       '0596001738'            ],
        [ 'is',     'isbn13',       '9780596001735'         ],
        [ 'is',     'ean13',        '9780596001735'         ],
        [ 'is',     'title',        'Perl Best Practices'   ],
        [ 'is',     'author',       'Damian Conway'         ],
        [ 'is',     'publisher',    q|O'Reilly Media|       ],
        [ 'is',     'pubdate',      undef                   ],
        [ 'is',     'binding',      'Paperback'             ],
        [ 'is',     'pages',        undef                   ],
        [ 'is',     'width',        undef                   ],
        [ 'is',     'height',       undef                   ],
        [ 'is',     'weight',       undef                   ],
        [ 'like',   'image_link',   qr!950137797_640!       ],
        [ 'like',   'thumb_link',   qr!950137797_640!       ],
        [ 'like',   'book_link',    qr|perl-best-practices| ]
    ],
);

my $tests = 0;
for my $isbn (keys %tests) { $tests += scalar( @{ $tests{$isbn} } ) + 2 }


###########################################################

my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

SKIP: {
	skip "Can't see a network connection", $tests   if(pingtest($CHECK_DOMAIN));

	$scraper->drivers($DRIVER);

    my $record;

    for my $isbn (keys %tests) {
        eval { $record = $scraper->search($isbn) };
        my $error = $@ || $record->error || '';

        SKIP: {
            skip "Website unavailable", scalar(@{ $tests{$isbn} }) + 2   
                if($error =~ /website appears to be unavailable/);
            skip "Book unavailable", scalar(@{ $tests{$isbn} }) + 2   
                if($error =~ /Failed to find that book/ || !$record->found);

            unless($record && $record->found) {
                diag("error=$error, record error=".$record->error);
            }

            is($record->found,1);
            is($record->found_in,$DRIVER);

            my $fail = 0;
            my $book = $record->book;
            diag("book=[".$book->{book_link}."]");
            for my $test (@{ $tests{$isbn} }) {
                if($test->[0] eq 'ok')          { ok(       $book->{$test->[1]},             ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'is')       { is(       $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'isnt')     { isnt(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'like')     { like(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'unlike')   { unlike(   $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); }

                $fail = 1   unless(defined $book->{$test->[1]} || ($test->[0] ne 'ok' && !defined $test->[2]));
            }

            diag("book=[".Dumper($book)."]")    if($fail);
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

    eval { system($cmd) }; 
    if($@) {                # can't find ping, or wrong arguments?
        diag();
        return 1;
    }

    my $retcode = $? >> 8;  # ping returns 1 if unable to connect
    return $retcode;
}
