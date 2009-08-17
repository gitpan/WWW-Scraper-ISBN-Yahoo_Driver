package WWW::Scraper::ISBN::Yahoo_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.10';

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
    my $mech = WWW::Mechanize->new;
    $mech->agent_alias( 'Linux Mozilla' );

    $mech->get( YAHOO );
    return $self->handler("Yahoo! book website appears to be unavailable.")
        unless($mech->success());

    # Yahoo now has a encoded search form on the front page.
#    my $template = <<HERE;
#<form name="s"[% ... %]action="[% action %]">[% ... %]
#HERE
#    my $data = $extract->extract($template, $mech->content());
#    my $search = "$data->{action}?p=$isbn&did=56;f=isbn;mid=1";

    my ($template,$data);
    my $search = SEARCH . $isbn;

    $mech->get( $search );
    return $self->handler("Failed to find that book on Yahoo! book website.")
        unless($mech->success());

    # The Results page
    my $content = $mech->content();
#print STDERR "\n# content1=[\n$content\n]\n";
    my ($code) = $content =~ /<li class="hproduct first.*?"><div class="img"><a href="(http[^"]+)"/is;
#print STDERR "\n# code=[$code]\n";
    return $self->handler("Could not extract data from Yahoo! Books result page. [$search]")
        unless(defined $code);

    $mech->get( $code );
    return  unless($mech->success());
    my $html = $mech->content();

#print STDERR "\n# content2=[\n$html\n]\n";

    # The Book page
    my $template1 = <<END;
<img id="shimgproductmain"[% ... %]src="[% thumb_link %]"[% ... %]
<h2>Product Details: <em>[% title %]</em></h2>[% ... %]
<em>Author:</em></td><td><a href="[% ... %]" rel="nofollow" target="_blank">[% author %]</a>[% ... %]
<em>Publisher:</em></td><td>[% publisher %] ([% pubdate %])</td>[% ... %]
<em>ISBN:</em></td><td>[% isbn %]</td>[% ... %]
<em>ISBN13:</em></td><td>[% isbn13 %]</td>[% ... %]
END

    my $template2 = <<END;
<img id="shimgproductmain"[% ... %]src="[% thumb_link %]"[% ... %]
<h2>Product Details: <em>[% title %]</em></h2>[% ... %]
<em>Author:</em></td><td><a href="[% ... %]" rel="nofollow" target="_blank">[% author %]</a>[% ... %]
<em>Publisher:</em></td><td>[% publisher %] ([% pubdate %])</td>[% ... %]
<em>ISBN:</em></td><td>[% isbn %]</td>[% ... %]
END

    $template = ($html =~ /ISBN13:/s) ? $template1 : $template2;
    $data = $extract->extract($template, $html);

    return $self->handler("Could not extract data from Yahoo! Books book page.")
        unless(defined $data);

    $data->{author} =~ s!</?a[^>]*>!!g;         # remove anchor tags
    $data->{image_link} = $data->{thumb_link};  # no big picture now

    my $root = $mech->uri();
    $root =~ s!(https?://([^/]+)).*!$1!;
    $data->{image_link} = $root . $data->{image_link}   if($data->{image_link} !~ /^http/);
    $data->{thumb_link} = $root . $data->{thumb_link}   if($data->{thumb_link} !~ /^http/);

    my $bk = {
        'isbn13'        => $data->{isbn13},
        'isbn10'        => $data->{isbn},
        'isbn'          => $data->{isbn},
        'author'        => $data->{author},
        'title'         => $data->{title},
        'book_link'     => $code,
        'image_link'    => $data->{image_link},
        'thumb_link'    => $data->{thumb_link},
        'publisher'     => $data->{publisher},
        'pubdate'       => $data->{pubdate},
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
