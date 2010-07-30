package WWW::Scraper::ISBN::Yahoo_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.11';

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

###########################################################################
#Constants                                                                #
###########################################################################

use constant    YAHOO   => 'http://books.yahoo.com';
use constant    SEARCH  => 'http://search.shopping.yahoo.com/search?p=';

#--------------------------------------------------------------------------

###########################################################################
#Inheritence                                                              #
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

  isbn          (now returns isbn13)
  isbn10        (no longer provided by Yahoo on page)
  isbn13
  ean13
  title
  author
  pubdate       (no longer provided by Yahoo on page)
  publisher     (no longer provided by Yahoo on page)
  book_link
  image_link
  thumb_link    (same as image_link)
  binding       (if known)
  pages         (if known)
  weight        (if known) (in grammes)
  width         (if known) (in millimetres)
  height        (if known) (in millimetres)

The book_link and image_link refer back to the Yahoo Books website.

=back

=cut

sub search {
    my $self = shift;
    my $isbn = shift;
    $self->found(0);
    $self->book(undef);
    my $data = {};

    my $mech = WWW::Mechanize->new;
    $mech->agent_alias( 'Linux Mozilla' );

    $mech->get( YAHOO );
    return $self->handler("Yahoo! book website appears to be unavailable.")
        unless($mech->success());

    my $search = SEARCH . $isbn;

    $mech->get( $search );
    return $self->handler("Failed to find that book on Yahoo! book website.")
        unless($mech->success());

    # The Results page
    my $content = $mech->content();
    #print STDERR "\n# content1=[\n$content\n]\n";
    ($data->{book_link},$data->{title},$data->{binding},$data->{author},$data->{pubdate}) 
                                        = $content =~ m!<h2 class="title"><a href="([^"]+)">([^<]+) <em>\((\w+)\)</em></a></h2>Author: ([^<]+)<br/>Published: ([^<]+)<br/>!is;
    return $self->handler("Could not extract data from Yahoo! Books result page. [$search]")
        unless(defined $data->{book_link});

    my $uri = $mech->uri();
    $uri =~ s!^(https?://[^/]+).*!$1!;
    my $link = $uri . $data->{book_link};

    $mech->get( $link );
    return $self->handler("Could not extract data from Yahoo! Books book page. [$link]")
        unless($mech->success());


	# The Book page
    my $html = $mech->content();

    #print STDERR "\n#$html";

    ($data->{pages})                    = $html =~ m!<em>Number of Pages</em></td><td>(\d+)</td>!s;
    ($data->{weight})                   = $html =~ m!<li><b>Shipping Weight:</b>\s*([\d.]+)\s*ounces</li>!s;
    ($data->{height},$data->{width})    = $html =~ m!<li><b>\s*Product Dimensions:\s*</b>\s*([\d.]+) x ([\d.]+) x ([\d.]+) inches\s*</li>!s;
    ($data->{isbn13})                   = $html =~ m!http://shopping.yahoo.com/(97[89]\d+)!s;
    ($data->{isbn10})                   = $isbn if(length($isbn) == 10);
    ($data->{publisher})                = (undef);
    ($data->{image_link})               = $html =~ m!<img id="shimgproductmain".*?src="([^"]+)"!s;
    ($data->{title},$data->{author},$data->{binding})    
                                        = $html =~ m!<h1><strong class="title"><span property="dc:title">(.*) - ([^<]+)</span></strong> <em>\((\w+)\)</em></h1>!;

    my $bk = {
        'isbn13'        => $data->{isbn13},
        'isbn10'        => $data->{isbn10},
        'isbn'          => $data->{isbn13},
        'ean13'         => $data->{isbn13},
        'author'        => $data->{author},
        'title'         => $data->{title},
		'book_link'		=> $mech->uri(),
        'image_link'    => $data->{image_link},
        'thumb_link'    => $data->{image_link},
        'publisher'     => $data->{publisher},
        'pubdate'       => $data->{pubdate},
		'binding'	    => $data->{binding},
		'pages'		    => $data->{pages},
		'weight'		=> $data->{weight},
		'width'		    => $data->{width},
		'height'		=> $data->{height}
    };
    $self->book($bk);
    $self->found(1);
    return $self->book;
}

#qw{currently reading: The Testament by John Grisham};

1;

__END__

=head1 REQUIRES

Requires the following modules be installed:

L<WWW::Scraper::ISBN::Driver>,
L<WWW::Mechanize>,

=head1 SEE ALSO

L<WWW::Scraper::ISBN>,
L<WWW::Scraper::ISBN::Record>,
L<WWW::Scraper::ISBN::Driver>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to the
RT system (http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Scraper-ISBN-Yahoo_Driver).
However, it would help greatly if you are able to pinpoint problems or even
supply a patch.

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  Miss Barbell Productions, <http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2004-2010 Barbie for Miss Barbell Productions

  This module is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
