#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More tests => 21;

###########################################################

	use WWW::Scraper::ISBN;
	my $scraper = WWW::Scraper::ISBN->new();
	isa_ok($scraper,'WWW::Scraper::ISBN');

	$scraper->drivers("Yahoo");
	my $isbn = "0385504209";
	my $record = $scraper->search($isbn);

	print STDERR $record->error . "\n"	unless($record->found);

	is($record->found,1);
	is($record->found_in,'Yahoo');

	my $book = $record->book;
	is($book->{'isbn'},'0385504209');
	is($book->{'title'},'The Da Vinci Code');
	is($book->{'author'},'Dan Brown');
	is($book->{'pubdate'},'03/01/2003');
	is($book->{'publisher'},'Doubleday');
	is($book->{'image_link'},'http://us.f1.yahoofs.com/shopping/159141/catalog_s_1979399834.1048116873.jpg?rm_____D9a0r3sKy');
	is($book->{'thumb_link'},'http://us.f1.yahoofs.com/shopping/159141/catalog_s_1979399834.1048116873.jpg?rm_____D9a0r3sKy');
	like($book->{'book_link'},qr!p_da-vinci-code_book_1979399834!);

	$isbn = "0672320673";
	$record = $scraper->search($isbn);

	print STDERR $record->error . "\n"	unless($record->found);

	is($record->found,1);
	is($record->found_in,'Yahoo');

	$book = $record->book;
	is($book->{'isbn'},'0672320673');
	is($book->{'title'},q|Perl Developer's Dictionary|);
	is($book->{'author'},'Clinton Pierce');
	is($book->{'pubdate'},'07/01/2001');
	is($book->{'publisher'},q!Sams!);
	is($book->{'image_link'},'http://us.f1.yahoofs.com/shopping/323875/muzes0672320673.jpg?bk_____DNYfT7p0.');
	is($book->{'thumb_link'},'http://us.f1.yahoofs.com/shopping/323875/muzes0672320673.jpg?bk_____DNYfT7p0.');
	like($book->{'book_link'},qr!p_perl-developer-s-dictionary_book_1976987277!);

###########################################################

