=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::synergrid;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use Data::Dumper;
use base qw(Site);

sub key { "synergrid"; }
sub name { "synergrid";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://www.synergrid.be/index.cfm?PageID=18214&language_code=NED";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;

	my @data;
		
	$self->{mech}->get($URL);

	# This is a potential leap in the dark, but since the links 
	# are listed in reverse time order, getting the first will ensure 
	# that we get the most recent year published. I wait to be
	# proved wrong about this, of course.

	$self->{mech}->follow_link(
	    text_regex => qr/Overbrenging naar de eindklanten/,
	    n => 1
	    );

	my $pdf = File::Temp->new(
	    suffix => '.pdf'
	    );
	print $pdf $self->{mech}->content();
	my $body = `pdftotext -q -layout $pdf -`;
	study($body);

	$body =~ m/ANNEE\s+(\d{4})/m;
	my $year = $1;

	# Scraped these from the actual output file - note
	# there is an error - September != Septembre
	my @le_mois = (
	    'Janvier',
	    'F.vrier',
	    'Mars',
	    'Avril',
	    'Mai',
	    'Juin',
	    'Juillet',
	    'Ao.t',
	    'September',
	    'Octobre',
	    'Novembre',
	    'D.cembre'
	    );

	foreach my $mon (0...11) {
	    my $date = $year . '-' . ($mon+1) . '-01';

	    # Pattern is: {Month Name} {Amount} {Percent} {Amount} {Percent} {Amonut} {Percent}
	    my $regex = $le_mois[$mon] . '\h+([0-9.]+)\s+([-0-9,]+)%\s+([0-9.]+)\s+([-0-9,]+)%\s+([0-9.]+)\s+([-0-9,]+)%.*$';

	    if ($body =~ m/$regex/m) {
		my (
		    $central, 
		    $central_pc,
		    $industry,
		    $industry_pc,
		    $public,
		    $public_pc) = ($1, $2, $3, $4, $5, $6);
		$central = dotNumber($central);
		$industry = dotNumber($industry);
		$public = dotNumber($public);
		$central_pc = commaNumber($central_pc);
		$industry_pc = commaNumber($industry_pc);
		$public_pc = commaNumber($public_pc);
		
		print "$date - $central $central_pc $industry $industry_pc $public $public_pc\n"; 
		push @data, [$date, "Central", $central, $central_pc];
		push @data, [$date, "Industry", $industry, $industry_pc];
		push @data, [$date, "Public", $public, $public_pc];
	    } else {
		print "$date --\n";
	    }
	}
=pod
1) Go to http://www.synergrid.be/index.cfm?PageID=18214
2) Select the download starting with "Overbrenging naar de eindklanten (maandelijkse gegevens)". The one that you choose is
the one for the current year. If we are in the first 3 months of the year, then we should try to download the current years data and iF that is not available, then download the previous years file.
3) From the file, we want the month in the first colum to be converted to a date format. I.e. YYYY-MM-01. You can use the hash %alt_french_months from misc.pm to convert french months to numbers.
4) We also want the data in columns 2-4 including the headings which should be the "type" in the final array.
Substitute the decimals with nothing (they are thousand separators) and substitue the commas for decimals in the percentages.
5) So the final array should look like: (date,type,value,percentage).
=cut

	
	$self->updateDB("eeg.synergrid_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

sub dotNumber {
    my $x = @_ ? shift : $_;
    $x =~ tr/&nbsp;//d;
    $x =~ s/\.//g;
    return $x;
}

1;


