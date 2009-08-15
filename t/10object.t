#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More tests => 23;

###########################################################

use WWW::Scraper::ISBN;
my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

SKIP: {
	skip "Can't see a network connection", 21   if(pingtest());

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
		is($book->{'isbn'},$isbn);
		is($book->{'isbn13'},'9780307474278');
		is($book->{'title'},'The Da Vinci Code');
		is($book->{'author'},'Dan Brown');
		is($book->{'pubdate'},'03/31/2009');
		is($book->{'publisher'},'Anchor Books');
		like($book->{'image_link'},qr!$isbn!);
		like($book->{'thumb_link'},qr!$isbn!);
		like($book->{'book_link'},qr!The%20Da%20Vinci%20Code!);

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
		is($book->{'isbn'},'0596001738');
		is($book->{'isbn13'},'9780596001735');
		is($book->{'title'},q|Perl Best Practices|);
		is($book->{'author'},'Damian Conway');
		is($book->{'pubdate'},'08/01/2005');
		is($book->{'publisher'},q!Oreilly & Associates Inc!);
		like($book->{'image_link'},qr!0596001738!);
		like($book->{'thumb_link'},qr!0596001738!);
		like($book->{'book_link'},qr!Perl\%20Best!);

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
