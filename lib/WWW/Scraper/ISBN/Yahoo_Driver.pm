package WWW::Scraper::ISBN::Yahoo_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.04';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::Yahoo_Driver - Search driver for Yahoo Books online catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from the Yahoo Books online catalog.

=cut

### CHANGES ###############################################################
#   0.01	10/04/2004	Initial Release
#	0.02	19/04/2004	Test::More added as a prerequisites for PPMs
#   0.03	31/08/2004	Simplified error handling
#   0.04	07/01/2001  handler() moved to WWW::Scraper::ISBN::Driver
###########################################################################

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
	return undef	unless($mechanize->success());

	# Yahoo now has a encoded search form on the front page.

	my $template = <<HERE;
<form name="search" onSubmit="return submitForm(this, '56');"
 action="[% action %]">[% ... %]
HERE

    my $data = $extract->extract($template, $mechanize->content());
	return undef	unless(defined $data);
	
	my $search = "http://shopping.yahoo.com$data->{action}?f=&mid=&dept_id=56&p=$isbn&did=56";
	$mechanize->get( $search );
	return undef	unless($mechanize->success());

	# The Results page
	$template = <<HERE;
<!-- ITEM -->
<table class="item_table" cellspacing="0" cellpadding="0">
  <tr>
    <td class="img">
<a href="http://shopping.yahoo.com/[% code %]"><img src="http://us.f[% ... %]
HERE

    $data = $extract->extract($template, $mechanize->content());
	return $self->handler("Could not extract data from Yahoo Books result page.")
		unless(defined $data);

	my $code = 'http://shopping.yahoo.com/' . $data->{code};
	$mechanize->get( $code );
	return undef	unless($mechanize->success());

	# The Book page
	$template = <<END;
<h1 class=yshp_product_page><b>[% title %]</b></h1>[% ... %]
<h2 class=yshp_product_page><b>[% author %]</b></h2><br></td>[% ... %]
<b>Compare Prices</b>[% ... %]
<tr valign=top>
<td width=150 align=center>
<a href="[% ... %]" onclick="window.open([% ... %]); return false;"><img src="[% image_link %]" width="[% ... %]" height="[% ... %]" alt="[% ... %]" border=0></a>[% ... %]
<b>Publisher:</b></span> [% publisher %] ([% pubdate %])<br><span class=[% ... %]><b>ISBN:</b></span> [% isbn %]<br>[% ... %]
END
	$data = $extract->extract($template, $mechanize->content());

	return $self->handler("Could not extract data from Yahoo Books result page.")
		unless(defined $data);

	$data->{author} =~ s!</?a[^>]*>!!g;	# remove anchor tags

	my $bk = {
		'isbn'			=> $data->{isbn},
		'author'		=> $data->{author},
		'title'			=> $data->{title},
		'book_link'		=> $code,
		'image_link'	=> $data->{image_link},
		'thumb_link'	=> $data->{image_link},
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

=over 4

=item L<WWW::Scraper::ISBN::Driver>

=item L<WWW::Mechanize>

=item L<Template::Extract>

=back

=head1 SEE ALSO

=over 4

=item L<WWW::Scraper::ISBN>

=item L<WWW::Scraper::ISBN::Record>

=item L<WWW::Scraper::ISBN::Driver>

=back

=head1 AUTHOR

  Barbie, E<lt>barbie@cpan.orgE<gt>
  Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT

  Copyright (C) 2004-2005 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or 
  modify it under the same terms as Perl itself.

=cut

