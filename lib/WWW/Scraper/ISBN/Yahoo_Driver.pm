package WWW::Scraper::ISBN::Yahoo_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.20';

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
# Inheritence

use base qw(WWW::Scraper::ISBN::Driver);

###########################################################################
# Modules

use WWW::Scraper::ISBN::Driver;
use WWW::Mechanize;

###########################################################################
# Constants

use constant    YAHOO   => 'http://shopping.yahoo.com';
use constant    SEARCH  => 'http://search.shopping.yahoo.com/search?p=';

#--------------------------------------------------------------------------

###########################################################################
# Public Interface

=head1 METHODS

=over 4

=item C<search()>

Creates a query string, then passes the appropriate form fields to the 
Yahoo Books server.

The returned page should be the correct catalog page for that ISBN. If not the
function returns zero and allows the next driver in the chain to have a go. If
a valid page is returned, the following fields are returned via the book hash:

  isbn          (now returns isbn13)
  isbn10        (no longer provided by Yahoo on page)
  isbn13
  ean13         (industry name)
  title
  author
  pubdate       (no longer provided by Yahoo on page)
  publisher     
  book_link
  image_link
  thumb_link    (same as image_link)
  description
  binding       (if known)
  pages         (no longer provided by Yahoo on page)
  weight        (no longer provided by Yahoo on page)
  width         (no longer provided by Yahoo on page)
  height        (no longer provided by Yahoo on page)

The book_link and image_link refer back to the Yahoo Books website.

=cut

sub search {
    my $self = shift;
    my $isbn = shift;
    $self->found(0);
    $self->book(undef);
    my $data = {};

    # validate and convert into EAN13 format
    my $ean = $self->convert_to_ean13($isbn);
    return $self->handler("Invalid ISBN specified [$isbn]")   
        if(!$ean || (length $isbn == 13 && $isbn ne $ean)
                 || (length $isbn == 10 && $isbn ne $self->convert_to_isbn10($ean)));
    $isbn = $ean;

    my $mech = WWW::Mechanize->new;
    $mech->agent_alias( 'Linux Mozilla' );

    eval { $mech->get( YAHOO . '/books' ) };
    return $self->handler("Yahoo! book website appears to be unavailable.")
	    if($@ || !$mech->success() || !$mech->content());

	eval { $mech->get( SEARCH . $isbn ) };
    return $self->handler("Yahoo! book search website appears to be unavailable.")
	    if($@ || !$mech->success() || !$mech->content());


    # The Results page
    my $content = $mech->content();
    #print STDERR "\n# results=[\n$content\n]\n";

    my ($list) = $content =~ m!<ul class="hproducts">(.*?)</ul>!is;
    my ($link,$thumb) = $list =~ m!<li[^>]+><div class="img"><a href="([^"]+)"[^>]+><img src="([^"]+)"!is;

    #print STDERR "\n# link=[$link],  thumb=[$thumb], list=[$list]\n";

    return $self->handler("Failed to find that book on Yahoo! book website.")
        unless(defined $link);

    $data->{book_link} = YAHOO . $link;

	eval { $mech->get( $data->{book_link} ) };
    return $self->handler("Yahoo! book search website appears to be unavailable.")
	    if($@ || !$mech->success() || !$mech->content());


	# The Book page
    my $html = $mech->content();
    #print STDERR "\n# page=[\n$html\n]\n";

    $data->{thumb_link}     = $thumb;
    ($data->{image_link})   = $html =~ m!<meta property="og:image" content="([^"]+)"/>!is;
    ($data->{title})        = $html =~ m!<meta property="og:title" content="([^"]+)"/>!is;
    ($data->{description})  = $html =~ m!<div class="exp-hide"><span itemprop="description">(.*?)</span></div>!is;
    ($data->{publisher})    = $html =~ m!<td class="label"><em>Publisher</em></td><td>([^<]+)</td>!is;
    ($data->{binding})      = $html =~ m!<td class="label"><em>Book Format</em></td><td>([^<]+)</td>!is;
    ($data->{author})       = $html =~ m!<td class="label"><em>Author</em></td><td>([^<]+)</td>!is;
    ($data->{isbn13})       = $html =~ m!http://shopping.yahoo.com/(97[89]\d+)!s;
    ($data->{isbn10})       = $self->convert_to_isbn10($ean);

	return $self->handler("Could not extract data from Yahoo! result page.")
		unless(defined $data);

	# trim top and tail
	foreach (keys %$data) { next unless(defined $data->{$_});$data->{$_} =~ s/^\s+//;$data->{$_} =~ s/\s+$//; }

    my $bk = {
        'isbn13'        => $data->{isbn13},
        'isbn10'        => $data->{isbn10},
        'isbn'          => $data->{isbn13},
        'ean13'         => $data->{isbn13},
        'author'        => $data->{author},
        'title'         => $data->{title},
		'book_link'		=> $data->{book_link},
        'image_link'    => $data->{image_link},
        'thumb_link'    => $data->{image_link},
		'description'	=> $data->{description},
        'publisher'     => $data->{publisher},
        'pubdate'       => $data->{pubdate},
		'binding'	    => $data->{binding},
		'pages'		    => $data->{pages},
		'weight'		=> $data->{weight},
		'width'		    => $data->{width},
		'height'		=> $data->{height},
		'depth'		    => $data->{depth},
        'html'          => $html
    };
    $self->book($bk);
    $self->found(1);
    return $self->book;
}

=item C<convert_to_ean13()>

Given a 10/13 character ISBN, this function will return the correct 13 digit
ISBN, also known as EAN13.

=item C<convert_to_isbn10()>

Given a 10/13 character ISBN, this function will return the correct 10 digit 
ISBN.

=back

=cut

sub convert_to_ean13 {
	my $self = shift;
    my $isbn = shift;
    my $prefix;

    return  unless(length $isbn == 10 || length $isbn == 13);

    if(length $isbn == 13) {
        return  if($isbn !~ /^(978|979)(\d{10})$/);
        ($prefix,$isbn) = ($1,$2);
    } else {
        return  if($isbn !~ /^(\d{10}|\d{9}X)$/);
        $prefix = '978';
    }

    my $isbn13 = '978' . $isbn;
    chop($isbn13);
    my @isbn = split(//,$isbn13);
    my ($lsum,$hsum) = (0,0);
    while(@isbn) {
        $hsum += shift @isbn;
        $lsum += shift @isbn;
    }

    my $csum = ($lsum * 3) + $hsum;
    $csum %= 10;
    $csum = 10 - $csum  if($csum != 0);

    return $isbn13 . $csum;
}

sub convert_to_isbn10 {
	my $self = shift;
    my $ean  = shift;
    my ($isbn,$isbn10);

    return  unless(length $ean == 10 || length $ean == 13);

    if(length $ean == 13) {
        return  if($ean !~ /^(?:978|979)(\d{9})\d$/);
        ($isbn,$isbn10) = ($1,$1);
    } else {
        return  if($ean !~ /^(\d{9})[\dX]$/);
        ($isbn,$isbn10) = ($1,$1);
    }

	return  if($isbn < 0 or $isbn > 999999999);

	my ($csum, $pos, $digit) = (0, 0, 0);
    for ($pos = 9; $pos > 0; $pos--) {
        $digit = $isbn % 10;
        $isbn /= 10;             # Decimal shift ISBN for next time 
        $csum += ($pos * $digit);
    }
    $csum %= 11;
    $csum = 'X'   if ($csum == 10);
    return $isbn10 . $csum;
}

q{currently listening to: Into Insignificance I Will Pale by Paul Menel};

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

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  Miss Barbell Productions, <http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2004-2013 Barbie for Miss Barbell Productions

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
