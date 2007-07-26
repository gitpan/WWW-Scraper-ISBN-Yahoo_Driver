package WWW::Scraper::ISBN::Yahoo_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.06';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::Yahoo_Driver - Search driver for Yahoo Books online catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from the Yahoo Books online catalog.

=cut

#--------------------------------------------------------------------------

###########################################################################
#Library Modules                                                          #
###########################################################################

use WWW::Scraper::ISBN::Driver;
use WWW::Mechanize;
use Template::Extract;

###########################################################################
#Constants                                                                #
###########################################################################

use constant	YAHOO	=> 'http://books.yahoo.com';
use constant	SEARCH	=> 'http://search.shopping.yahoo.com/search?p=';

#--------------------------------------------------------------------------

###########################################################################
#Inheritence		                                                      #
###########################################################################

@ISA = qw(WWW::Scraper::ISBN::Driver);

###########################################################################
#Interface Functions                                                      #
###########################################################################

=head1 METHODS

=over 4

=item C<search()>

Creates a query string, then passes the appropriate form fields to the Yahoo
Books server.

The returned page should be the correct catalog page for that ISBN. If not the
function returns zero and allows the next driver in the chain to have a go. If
a valid page is returned, the following fields are returned via the book hash:

  isbn
  isbn13 (if available)
  title
  author
  pubdate
  publisher
  book_link
  image_link
  thumb_link (same as image_link)

The book_link and image_link refer back to the Yahoo Books website. 

=back

=cut

sub search {
	my $self = shift;
	my $isbn = shift;
	$self->found(0);
	$self->book(undef);

	my $extract = Template::Extract->new;
	my $mechanize = WWW::Mechanize->new;
	$mechanize->agent_alias( 'Windows Mozilla' );

	$mechanize->get( YAHOO );
    return $self->handler("Yahoo! book website appears to be unavailable.")
	    unless($mechanize->success());

	# Yahoo now has a encoded search form on the front page.

	my $template = <<HERE;
<form name="s"[% ... %]action="[% action %]">[% ... %]
HERE

    my $data = $extract->extract($template, $mechanize->content());
	my $search = "$data->{action}?p=$isbn&did=56;f=isbn;mid=1";
	$mechanize->get( $search );
	return $self->handler("Failed to find that book on Yahoo! book website.")
	    unless($mechanize->success());

	# The Results page
    my $content = $mechanize->content();
#print STDERR "\n# content1=[\n$content\n]\n";
    my ($code) = $content =~ /href="(http[^"]+:isbn=$isbn;[^"]+)"/is;
#print STDERR "\n# code=[$code]\n";
	return $self->handler("Could not extract data from Yahoo! Books result page.")
		unless(defined $code);

	$mechanize->get( $code );
	return	unless($mechanize->success());
    my $html = $mechanize->content();

#print STDERR "\n# content2=[\n$html\n]\n";

	# The Book page
	my $template1 = <<END;
<h1>[% title %]</h1>[% ... %]
<h2 class=yshp_product_page><b><a[% ... %]>[% author %]</a></b></h2>[% ... %]
<div class="viewlrg"><a href="[% ... %]" onclick="window.open('[% image_link %]'[% ... %]); return false;"><img src="[% thumb_link %]"[% ... %]
<b>Publisher:</b></span> [% publisher %] ([% pubdate %])<br><span[% ... %]
><b>ISBN:</b></span> [% isbn %]</span>[% ... %]<b>ISBN13:</b></span> [% isbn13 %]</span>[% ... %]
END

    my $template2 = <<END;
<h1>[% title %]</h1>[% ... %]
<h2 class=yshp_product_page><b><a[% ... %]>[% author %]</a></b></h2>[% ... %]
<div class="viewlrg"><a href="[% ... %]" onclick="window.open('[% image_link %]'[% ... %]); return false;"><img src="[% thumb_link %]"[% ... %]
<b>Publisher:</b></span> [% publisher %] ([% pubdate %])<br><span[% ... %]
><b>ISBN:</b></span> [% isbn %]</span>[% ... %]
END

    $template = ($html =~ /ISBN13:/s) ? $template1 : $template2;
	$data = $extract->extract($template, $html);

	return $self->handler("Could not extract data from Yahoo! Books book page.")
		unless(defined $data);

	$data->{author} =~ s!</?a[^>]*>!!g;	# remove anchor tags

	my $bk = {
		'isbn'			=> $data->{isbn},
		'isbn13'		=> $data->{isbn13},
		'author'		=> $data->{author},
		'title'			=> $data->{title},
		'book_link'		=> $code,
		'image_link'	=> $data->{image_link},
		'thumb_link'	=> $data->{thumb_link},
		'publisher'		=> $data->{publisher},
		'pubdate'		=> $data->{pubdate},
	};
	$self->book($bk);
	$self->found(1);
	return $self->book;
}

1;
__END__

=head1 REQUIRES

Requires the following modules be installed:

L<WWW::Scraper::ISBN::Driver>,
L<WWW::Mechanize>,
L<Template::Extract>

=head1 SEE ALSO

L<WWW::Scraper::ISBN>,
L<WWW::Scraper::ISBN::Record>,
L<WWW::Scraper::ISBN::Driver>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  Miss Barbell Productions, <http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2004-2007 Barbie for Miss Barbell Productions

  This module is free software; you can redistribute it and/or 
  modify it under the same terms as Perl itself.

The full text of the licenses can be found in the F<Artistic> file included 
with this module, or in L<perlartistic> as part of Perl installation, in 
the 5.8.1 release or later.

=cut
