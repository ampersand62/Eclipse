=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::peru_lng;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);
use File::Temp;
our $DEBUG = 1;

sub key { "peru_lng"; }
sub name { "peru_lng";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://www.perupetro.com.pe/wps/wcm/connect/perupetro/site-en/ImportantInformation/Statistics/Natural%20Gas%20Royalties%20For%20Export";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;
	
	$self->{mech}->get($URL);

	# We want the *last* link which matches a year.....
	my @links = $self->{mech}->find_all_links(
	    text_regex => qr/^20\d{2}$/
	    );

	$self->{mech}->get(($links[$#links])->url());

	my $pdf = File::Temp->new(
	    suffix => '.pdf'
	    );

	print $pdf $self->{mech}->content();

	my $body = File::Temp->new();

       print $body `pdftotext -q -layout $pdf -`;

	$body->seek(0, 0);

	while (<$body>) {
#	    print $_ if $DEBUG;
	    next unless m!\d{2}/\d{2}/\d{4}!;

	    # This doesn't work perfectly but is as close as we can get...

	    $_ =~ m!(\d+)\s+([A-Z]{2}-\d+)\s+(\d{2})/(\d{2})/(\d{4})\s+(.*)\s+([0-9,.]+)\s+([0-9,.]+)\s+([A-Za-z ]*)\s+([0-9.]+)!;
	    my ($no, $load, $day, $mon, $year, $dest, $tons, $cal, $merch, $value) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);

	    my $date = sprintf("%04d-%02d-%02d", $year, $mon, $day);

	    $tons =~ s/,//g;
#	    $cal =~ s/,//g;

	    push @data, [$date, $load, $dest, $tons, $cal, $merch, $value];
	    print "$no: $date, $load, $day, $dest, $tons, $cal, $merch, $value\n" if $DEBUG;

	}
	
=pod
#1)	INSTRUCTIONS:
1) Go to http://www.perupetro.com.pe/wps/wcm/connect/perupetro/site-en/ImportantInformation/Statistics/Natural%20Gas%20Royalties%20For%20Export								
2) Click on the latest year
3) we want all the columns in the table.
4) Dont worry about any translations!
5) Column4 (date field) should be in format YYYY-MM-DD. Get rid of commas in the number fields and load all the data into
one multi-dim array.

=cut
	
	$self->updateDB("eeg.peru_lng_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


