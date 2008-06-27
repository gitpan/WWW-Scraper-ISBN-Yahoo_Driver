#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More tests => 23;

###########################################################

	use WWW::Scraper::ISBN;
	my $scraper = WWW::Scraper::ISBN->new();
	isa_ok($scraper,'WWW::Scraper::ISBN');

	$scraper->drivers("Yahoo");


    ## Extract with an ISBN 10 value

	my $isbn = '0385504209';
	my $record = $scraper->search($isbn);

	SKIP: {
		skip($record->error . "\n",10)	unless($record->found);

		is($record->found,1);
		is($record->found_in,'Yahoo');

		my $book = $record->book;
		is($book->{'isbn'},$isbn);
		is($book->{'isbn13'},'9780385504201');
		is($book->{'title'},'The Da Vinci Code');
		is($book->{'author'},'Dan Brown');
		is($book->{'pubdate'},'03/01/2003');
		is($book->{'publisher'},'Doubleday');
		like($book->{'image_link'},qr!$isbn!);
		like($book->{'thumb_link'},qr!$isbn!);
		like($book->{'book_link'},qr!isbn=$isbn!);
	}


    ## Extract with an ISBN 13 value

    $isbn = '9780672320675';
	$record = $scraper->search($isbn);

	SKIP: {
		skip($record->error . "\n",10)	unless($record->found);

		is($record->found,1);
		is($record->found_in,'Yahoo');

		my $book = $record->book;
		is($book->{'isbn'},'0672320673');
		is($book->{'isbn13'},'9780672320675');
		is($book->{'title'},q|Perl Developer's Dictionary|);
		is($book->{'author'},'Clinton Pierce');
		is($book->{'pubdate'},'07/01/2001');
		is($book->{'publisher'},q!Sams!);
		like($book->{'image_link'},qr!0672320673!);
		like($book->{'thumb_link'},qr!0672320673!);
		like($book->{'book_link'},qr!Perl\%20Developer!);
	}

###########################################################

