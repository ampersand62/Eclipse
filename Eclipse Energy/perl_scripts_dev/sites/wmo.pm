=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::wmo;
our $DEBUG = 1;
use Data::Dumper;
use File::Temp;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);

sub key { "wmo"; }
sub name { "wmo";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://worldweather.wmo.int/europe.htm";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;

	$self->{mech}->get($URL);

	# Cheating here slightly, since the links we want all have the
	# same <font> tag...
	foreach my $link ($self->{mech}->find_all_links()) {
	    next unless ($link->attrs()->{class} && $link->attrs()->{class} eq 'text15');

	    my $country = $link->text();

	    # This is a horrible hack, but the countries are listed twice; 
	    # only the first list have weather forcasts.
	    # Albania doesn't so we know that we're onto the second list if
	    # we get to it....
	    last if ($country eq 'Albania');

	    $self->{mech}->get($link->url_abs());
	    print STDERR "$country ->\n" if $DEBUG;
	    # We're now on the country page. Now we need to scan for each region
	    # on each page...

	    # As if to make it even more complicated, a few small countries 
	    # don't have any regions at all. So, we need to improvise...
	    my $has_regions = 0;

	    foreach my $rlink ($self->{mech}->find_all_links()) {
		next unless ($rlink->attrs()->{class} && $rlink->attrs()->{class} eq 'text15');	
	    
		my $region = $rlink->text();
		$has_regions = 1;

		$self->{mech}->get($rlink->url_abs());
		print STDERR "    $region\n" if $DEBUG;
		# This is complicated by the fact that not all region pages 
		# actually have a weather forcast - some of them (in I think
		# obscure places) just have the climate table

		# I have also deviated from the instructions below since 
		# as is it would not indicate where each location is for - 
		# So each datum consists of:
		# <date, country, region, min_temp, max_temp, weather>
		#
		my $has_forecast = 0;
		my $temp = File::Temp->new();

		print $temp $self->{mech}->content();

		$temp->seek ( 0, 0);

		while (<$temp>) {

		    if (/Weather Forecast/) {

			$has_forecast = 1;
			last;
		    }
		}

		if ($has_forecast) {
		    # Scan for the year
		    for my $i (1 ..13) {
			$_ = <$temp>;
		    }

		    $_ =~ m/(\d\d\d\d)/;
		    my $year = $1;


		    # Skip over the header row
		    for my $i (1 .. 16) {
			$_ = <$temp>;
		    }

		    # Each row of the table
		    while (<$temp>) {
			last unless /<tr>/;

			$_ = <$temp>;

			$_ =~ m/ (\d+)/;
			my $day = $1;

			$_ = <$temp>;

			$_ =~ m/(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)/;
			my $mon = $monthToNum{$1};
			for my $i (1 .. 5) {
			    $_ = <$temp>;
			}
			$_ =~ m/(\d+)/;
			my $min = $1;

			for my $i (1 .. 5) {
			    $_ = <$temp>;
			}
			$_ =~ m/(\d+)/;
			my $max = $1;

			for my $i (1 .. 9) {
			    $_ = <$temp>;
			}
			$_ = m/<b>(.*)<\/b>/;
			my $weather = $1;

			my $date = sprintf("%04d-%02d-%02d", $year, $mon, $day);

			print "$date: $country, $region, $min, $max, $weather\n" if $DEBUG;
			push @data, [$date, $country, $region, $min, $max, $weather] unless $DEBUG;
			# off the end of the row
			for my $i (1 ..5) {
			    $_ = <$temp>;
			}
		    }
		}

		close $temp;
	    }
	    
	    # It was a long way ago, but we need to check whether there were any
	    # regions
	    unless ($has_regions) {
		my $region = "no_region";
		# Yes, it's cut and paste, I'm afraid...

		my $has_forecast = 0;
		my $temp = File::Temp->new();

		print $temp $self->{mech}->content();

		$temp->seek ( 0, 0);

		while (<$temp>) {

		    if (/Weather Forecast/) {

			$has_forecast = 1;
			last;
		    }
		}

		if ($has_forecast) {
		    # Scan for the year
		    for my $i (1 ..13) {
			$_ = <$temp>;
		    }

		    $_ =~ m/(\d\d\d\d)/;
		    my $year = $1;


		    # Skip over the header row
		    for my $i (1 .. 16) {
			$_ = <$temp>;
		    }

		    # Each row of the table
		    while (<$temp>) {
			last unless /<tr>/;

			$_ = <$temp>;

			$_ =~ m/ (\d+)/;
			my $day = $1;

			$_ = <$temp>;

			$_ =~ m/(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)/;
			my $mon = $monthToNum{$1};
			for my $i (1 .. 5) {
			    $_ = <$temp>;
			}
			$_ =~ m/(\d+)/;
			my $min = $1;

			for my $i (1 .. 5) {
			    $_ = <$temp>;
			}
			$_ =~ m/(\d+)/;
			my $max = $1;

			for my $i (1 .. 9) {
			    $_ = <$temp>;
			}
			$_ = m/<b>(.*)<\/b>/;
			my $weather = $1;

			my $date = sprintf("%04d-%02d-%02d", $year, $mon, $day);

			print "$date: $country, $region, $min, $max, $weather\n" if $DEBUG;
			push @data, [$date, $country, $region, $min, $max, $weather] unless $DEBUG;
			# off the end of the row
			for my $i (1 ..5) {
			    $_ = <$temp>;
			}
		    }
		}

		close $temp;

	    }
	}
=pod
1) go to http://worldweather.wmo.int/europe.htm
2). for each and every country in the first table, choose each and every region for that country. then we want the data in the first table.date in yyyy-mm-dd format.
the final array should look like: <date,min_temp.max_temp,weather>. 

=cut
	
	$self->updateDB("eeg.wmo_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


