#!/usr/bin/perl -w
use strict;

#########################

use Test::More tests => 1;

eval "use WWW::Scraper::ISBN::Yahoo_Driver";
is($@,'');

#########################

