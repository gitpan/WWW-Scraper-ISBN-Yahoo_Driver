package WWW::Scraper::ISBN::Yahoo_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.03';

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
use constant	SEARCH	=> 'http://search.shopping.yahoo.com/search?did=56&p=';

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

	my $mechanize = WWW::Mechanize->new();
	$mechanize->get( SEARCH . $isbn );
	return undef	unless($mechanize->success());

	# The Results page
	my $template = <<END;
<td align=center width=70><a href="http://shopping.yahoo.com/[% code %]"><img src="http://us.f[% ... %]
END

	my $extract = Template::Extract->new;
    my $data = $extract->extract($template, $mechanize->content());

	return $self->_error_handler("Could not extract data from Yahoo Books result page.")
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

	return $self->_error_handler("Could not extract data from Yahoo Books result page.")
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

sub _error_handler {
	my $self = shift;
	my $mess = shift;
	print "Error: $mess\n"	if $self->verbosity;
	$self->error("$mess\n");
	$self->found(0);
	return 0;
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

  Copyright (C) 2002-2004 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or 
  modify it under the same terms as Perl itself.

=cut

