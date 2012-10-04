=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::enagas_monthly;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);

use Data::Dumper;
use File::Temp;
#use CAM::PDF;

sub key { "enagas_monthly"; }
sub name { "enagas_monthly";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://www.enagas.es/cs/Satellite?cid=1146233000618&language=en&pagename=ENAGAS%2FPage%2FENAG_listadoComboDoble";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;

# If month is 1 or 2, the last year, otherwise current year
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                localtime(time);
	$year-- if ($mon < 2);
	$year += 1900;

	$self->{mech}->get($URL);

	$self->{mech}->form_number(2); # We want form no 2 for our purposes
	$self->{mech}->select(
	    "idCombo",
	    'Bulletin on Gas Statistics'
	    );
	$self->{mech}->submit();

	$self->{mech}->form_number(2);
	$self->{mech}->select(
	    "idCombo2",
	    $year
	    );
	$self->{mech}->submit();

#      The two links we want are the first two pdf links
	my $link1 = $self->{mech}->find_link(
	    text_regex => qr/Download pdf/,
	    n => 1
	    );
	my $link2 = $self->{mech}->find_link(
	    text_regex => qr/Download pdf/,
	    n => 2
	    );

	my (@data, @data2);

	foreach my $link ($link1, $link2) {
	    $self->{mech}->get( $link->url());
	    my $pdf = File::Temp->new(
		suffix => '.pdf'
		);
	    print $pdf $self->{mech}->content();
	    my $body = `pdftotext -q -layout $pdf -`;
	    study($body);
	    $body =~ m/(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{4})/;
	    my $month = "$1 $2";
	    foreach my $cat (
		'Conventional demand',
		'Electricity Sector',
		'I.C. Exportations',
		'Guadalquivir underground storage output',
		'GME to REN Transfers',
		) {
		# We need to match the above title, some whitespace, then 
		# the number
		my $value;
		my $rexp = $cat . '\s+([0-9,]+)';
		if ($body =~ m/$rexp/ms) {
		    $value = $1;
		} else {
		    $value = 0;
		}
		print "$month  -> $cat - $value\n"; # Comment this for production
		push @data, [$month, $cat, $value];
	    }
	    # Page 12 data. Note tha tI expect this to be revised:
	    # Column 1 of the table shows *last year*'s data
	    foreach my $terr (
		'Algeria GN',
		'Algeria GNL',
		'Italy GNL',
		'Qatar GNL',
		'Oman GNL',
		'Nigeria GNL',
		'Egypt GNL',
		'Norway GNL',
		'France GN',
		'Libya GNL',
		'T&T GNL',
		'USA GNL',
		'Peru GNL',
		'Belgium GNL',
		'YEMEN GNL',
		'National GN',
		'Portugal GN',
		) {
		my $rexp = $terr . '\s+([0-9.\-]+)';
		$body =~ m/$rexp/;
		my $qty = $1;
		if ($qty eq '-') {
		    $qty = 0;
		}
		print "$month -> $terr - $qty\n"; #Comment this line for production
		push @data2, [$month, $terr, $qty];
	    }
	}
		

=pod
#1)	INSTRUCTIONS:
	1) Go to the URL
2) Click on the option "Bullitin on Gas Statistics" 
3) Then click on the Arrow button. If today's date is in the months of January or February, then we should click on the previous year,
otherwise we should click on the year in today's date.
3) Then download the 2 most recent months of data in that year.
4) From page 3 of the pdf, we need the following numbers in the first column (mes/month): 
	"Convencional nacional" (Conventional demand), 
	"Sector electrico" (Electricity sector), 
	"Salidas Conexiones internacionales" (I.C exportations), 
	"Salidas valle Guadalquivir " (Guadalquivir underground storage output),
	"Salidas GME transito a Portugal REN" (GME to REN transfers)
	Put these values in one multi- array (structure should be: date, type,value).
5) We also want data from page 12 (takes a while to load but its a table). We want all the data in the first column.
Replace dashes with 0's. Then put the data in a second multi-dim array (should have the structure: date,country,value).

=cut

	
	$self->updateDB("eeg.enagas_monthly_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


