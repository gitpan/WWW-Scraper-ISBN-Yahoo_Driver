#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More tests => 21;

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
		is($book->{'title'},'The Da Vinci Code');
		is($book->{'author'},'Dan Brown');
		is($book->{'pubdate'},'03/01/2003');
		is($book->{'publisher'},'Doubleday');
		like($book->{'image_link'},qr!http://us\.\w+\.yahoofs\.com/shopping/159141/catalog_s_1979399834\.1048116873\.jpg\?rm_____D9a0r3sKy!);
		like($book->{'thumb_link'},qr!http://us\.\w+\.yahoofs\.com/shopping/159141/catalog_s_1979399834\.1048116873\.jpg\?rm_____D9a0r3sKy!);
		like($book->{'book_link'},qr!p:Da%20Vinci%20Code.*1979399834!);
	}

	$isbn = '0672320673';
	$record = $scraper->search($isbn);

	SKIP: {
		skip($record->error . "\n",10)	unless($record->found);

		is($record->found,1);
		is($record->found_in,'Yahoo');

		my $book = $record->book;
		is($book->{'isbn'},$isbn);
		is($book->{'title'},q|Perl Developer's Dictionary|);
		is($book->{'author'},'Clinton Pierce');
		is($book->{'pubdate'},'07/01/2001');
		is($book->{'publisher'},q!Sams!);
		like($book->{'image_link'},qr!http://us\.\w+\.yahoofs\.com/shopping/323875/muzes0672320673\.jpg\?bk_____DNYfT7p0\.!);
		like($book->{'thumb_link'},qr!http://us\.\w+\.yahoofs\.com/shopping/323875/muzes0672320673\.jpg\?bk_____DNYfT7p0\.!);
		like($book->{'book_link'},qr!p:Perl%20Developer%27s%20Dictionary.*1976987277!);
	}

###########################################################

