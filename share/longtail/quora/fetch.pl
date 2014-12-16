#!/usr/bin/env perl
# fetch quora data and put in sqlite DB
#

use strict;
use warnings;
use DBI;
use Mojo::DOM;
use Data::Dumper;
use IO::All;
use LWP::Simple;

#my $dbh = DBI->connect("dbi:SQLite:dbname=quora","","");
my $base_url = "http://www.quora.com/sitemap/questions?page_id=1";
my $html = get($base_url);
my $dom = Mojo::DOM->new($html);

my $WANT_ANS_CUTOFF = 0;
my $ANS_COUNT_CUTOFF = 0;

# get the links from the sitemap
my @site_map_links = get_sitemap_page_links($dom);

warn Dumper @site_map_links;

foreach my $link (@site_map_links){

	my $html = get($link);
	print "Getting page: $link\n";

	my ($title, $q_text, $abstract, $want_ans, $ans_count) = '';

	my $page = Mojo::DOM->new($html);
	
	$page->find('span.count')->each( sub{
			$want_ans = $_->text if $_->text;
	});
	
	next if $want_ans < $WANT_ANS_CUTOFF;

	$page->find('div.answer_count')->each( sub{
			$ans_count = $_->text if $_->text;
	});

	next if $ans_count < $ANS_COUNT_CUTOFF;

	$page->find('h1')->each( sub{
		$title = $_->text if $_->text;
	});

	$page->find('div.question_details_text')->each( sub{
			$q_text = $_->text if $_->text;
	});


	warn "title: $title Want: $want_ans Count: $ans_count\n";
}




# returns an array of links for a page on the sitemap
sub get_sitemap_page_links {
	my $page = shift;
	my @links = ();
	
	$page->find('a[href]')->each ( sub{
			
		next if $_ =~ m/questions\?page_id=/;
		next if $_ !~ /wwww\.quora\.com/;
		
		push(@links, $_->{href});
	});
	
	return @links;
}