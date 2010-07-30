use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		    => 'WWW::Scraper::ISBN::Yahoo_Driver',
    'VERSION_FROM'	=> 'lib/WWW/Scraper/ISBN/Yahoo_Driver.pm',
    'PREREQ_PM'		=> {
		WWW::Scraper::ISBN			=> 0.25,
		WWW::Scraper::ISBN::Driver	=> 0.18,
		WWW::Mechanize				=> 0.56,	# when agent_alias() got added
		Test::More					=> 0.45,	# for testing
	},
	NO_META			=> 1,

    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => q|Search driver for Yahoo Book's online catalog|,
       AUTHOR     => 'Barbie <barbie@cpan.org>') : ()),
);
