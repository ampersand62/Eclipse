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

sub key { "enagas_monthly"; }
sub name { "enagas_monthly";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://www.enagas.es/cs/Satellite?cid=1146233000618&language=en&pagename=ENAGAS%2FPage%2FENAG_listadoComboDoble";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
		
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
	my @data;
	
	$self->updateDB("eeg.enagas_monthly_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


