#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More tests => 37;

###########################################################

use WWW::Scraper::ISBN;
my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

SKIP: {
	skip "Can't see a network connection", 36   if(pingtest());

	$scraper->drivers("Yahoo");

    ## Extract with an ISBN 10 value

	my $isbn = '0307474275';
	my $record = $scraper->search($isbn);

    unless($record->found) {
		diag($record->error);
    } else {
		is($record->found,1);
		is($record->found_in,'Yahoo');

		my $book = $record->book;
		is($book->{'isbn'},         '9780307474278'         ,'.. isbn found');
		is($book->{'isbn10'},       $isbn                   ,'.. isbn10 found');
		is($book->{'isbn13'},       '9780307474278'         ,'.. isbn13 found');
		is($book->{'ean13'},        '9780307474278'         ,'.. ean13 found');
		is($book->{'title'},        'The DaVinci Code'      ,'.. title found');
		is($book->{'author'},       'Dan Brown'             ,'.. author found');
		is($book->{'pubdate'},      'March 2009'            ,'.. pubdate found');
		is($book->{'publisher'},    undef                   ,'.. publisher found'); # no longer provided
		like($book->{'image_link'}, qr!9780307474278!);
		like($book->{'thumb_link'}, qr!9780307474278!);
		like($book->{'book_link'},  qr!the-davinci-code!i);
		is($book->{'binding'},      'Paperback'             ,'.. binding found');
		is($book->{'pages'},        597                     ,'.. pages found');
		is($book->{'width'},        undef                   ,'.. width found');
		is($book->{'height'},       undef                   ,'.. height found');
		is($book->{'weight'},       undef                   ,'.. weight found');

        #use Data::Dumper;
        #diag("book=[".Dumper($book)."]");
	}

    ## Extract with an ISBN 13 value

    $isbn = '9780596001735';
	$record = $scraper->search($isbn);

    unless($record->found) {
		diag($record->error);
    } else {
		is($record->found,1);
		is($record->found_in,'Yahoo');

		my $book = $record->book;
		is($book->{'isbn'},         $isbn                   ,'.. isbn found');
		is($book->{'isbn10'},       undef                   ,'.. isbn10 found');    # not provided by default
		is($book->{'isbn13'},       '9780596001735'         ,'.. isbn13 found');
		is($book->{'ean13'},        '9780596001735'         ,'.. ean13 found');
		is($book->{'title'},        'Perl Best Practices'   ,'.. title found');
		is($book->{'author'},       'Damian Conway'         ,'.. author found');
		is($book->{'pubdate'},      'August 2005'           ,'.. pubdate found');
		is($book->{'publisher'},    undef                   ,'.. publisher found'); # no longer provided
		like($book->{'image_link'}, qr!9780596001735!);
		like($book->{'thumb_link'}, qr!9780596001735!);
		like($book->{'book_link'},  qr!perl-best-practices!i);
		is($book->{'binding'},      'Paperback'             ,'.. binding found');
		is($book->{'pages'},        517                     ,'.. pages found');
		is($book->{'width'},        undef                   ,'.. width found');
		is($book->{'height'},       undef                   ,'.. height found');
		is($book->{'weight'},       undef                   ,'.. weight found');

        #use Data::Dumper;
        #diag("book=[".Dumper($book)."]");
	}
}

###########################################################

# crude, but it'll hopefully do ;)
sub pingtest {
  system("ping -q -c 1 www.google.com >/dev/null 2>&1");
  my $retcode = $? >> 8;
  # ping returns 1 if unable to connect
  return $retcode;
}
