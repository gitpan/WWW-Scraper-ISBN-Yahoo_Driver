#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More tests => 23;

###########################################################

	use WWW::Scraper::ISBN;
	my $scraper = WWW::Scraper::ISBN->new();
	isa_ok($scraper,'WWW::Scraper::ISBN');

	$scraper->drivers("Yahoo");
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

	$isbn = '0672320673';
	$record = $scraper->search($isbn);

	SKIP: {
		skip($record->error . "\n",10)	unless($record->found);

		is($record->found,1);
		is($record->found_in,'Yahoo');

		my $book = $record->book;
		is($book->{'isbn'},$isbn);
		is($book->{'isbn13'},undef);
		is($book->{'title'},q|Perl Developer's Dictionary|);
		is($book->{'author'},'Clinton Pierce');
		is($book->{'pubdate'},'07/01/2001');
		is($book->{'publisher'},q!Sams!);
		like($book->{'image_link'},qr!$isbn!);
		like($book->{'thumb_link'},qr!$isbn!);
		like($book->{'book_link'},qr!isbn=$isbn!);
	}

###########################################################

