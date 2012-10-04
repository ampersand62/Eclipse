=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please don't edit anything in this section. Feel free to add Perl modules to use --- #
package Site::ssb;

our $DEBUG = 1;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);

sub key { "ssb"; }
sub name { "ssb";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://statbank.ssb.no/statistikkbanken/SelectVarVal/define.asp?SubjectCode=09&ProductId=09.05&MainTable=VareLandMnd&PLanguage=1&Tabstrip=SELECT&Qid=1005960&nvl=True&SessID=5819704&FF=2&mt=1&pm=&gruppe1=Hele&gruppe2=Hele&gruppe3=Hele&gruppe4=Hele&VS1=ImpEks&VS2=VareKoderKN8Siff&VS3=LandKoderAlf1&VS4=&feil=You%20must%20select%20at%20least%20one%20value%20for%20imports/exports";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;

	$self->{mech}->get($URL);

	# Contents -> Quantity 1;
	$self->{mech}->select(
	    'Contents',
	    "Megde1"
	    );
	# Export
	$self->{mech}->select(
	    'var1',
	    2
	    );

	print $self->{mech}->content() if $DEBUG;

=pod
#1)	INSTRUCTIONS:
1) Go to the LNG link:     http://statbank.ssb.no/statistikkbanken/SelectVarVal/define.asp?SubjectCode=09&ProductId=09.05&MainTable=VareLandMnd&PLanguage=1&Tabstrip=SELECT&Qid=1005960&nvl=True&SessID=5819704&FF=2&mt=1&pm=&gruppe1=Hele&gruppe2=Hele&gruppe3=Hele&gruppe4=Hele&VS1=ImpEks&VS2=VareKoderKN8Siff&VS3=LandKoderAlf1&VS4=&feil=You%20must%20select%20at%20least%20one%20value%20for%20imports/exports
2) We also have this direct link: http://statbank.ssb.no/statistikkbanken/SelectVarVal/define.asp?MainTable=VareLandMnd&PLanguage=1&nvl=True&Qid=1005959&QT=ST&FQ=1   .This sometimes doesn't work and when it does, it seems only to work for the current month.
3) If you choose the first link, we need to following options selected: Contents -> quanitity  1 and Value options, Imports/exports -> Exports, Commodity number -> 27111100 (natural gas, liquified), Country -> Choose all countries, Month -> choose last 3 months.
4) Then click show table. There's alot of zero's which we aren't interested in so if you come across 0's for quantity, don't include that row.
5) we want both columns for each month. Date in format YYYY-MM-01. So the final array should look like: <date,export_country, value,quantity>


1) Go to the natual gas in gaseous state link: http://statbank.ssb.no/statistikkbanken/SelectVarVal/define.asp?SubjectCode=09&ProductId=09.05&MainTable=VareLandMnd&PLanguage=1&Tabstrip=SELECT&Qid=1005959&nvl=True&SessID=5819704&FF=2&mt=1&pm=&gruppe1=Hele&gruppe2=Hele&gruppe3=Hele&gruppe4=Hele&VS1=ImpEks&VS2=VareKoderKN8Siff&VS3=LandKoderAlf1&VS4=&feil=You%20must%20select%20at%20least%20one%20value%20for%20imports/exports
2) Again we have a direct link: http://statbank.ssb.no/statistikkbanken/SelectVarVal/define.asp?MainTable=VareLandMnd&PLanguage=1&nvl=True&Qid=1005960&QT=ST&FQ=1
3) If you choose the first link, we need to following options selected: Contents -> Value NOK and Quantity 2 options, Imports/exports -> Exports, Commodity number -> 27112100 (natual gas in gaseous state), Country -> Choose all countries, Month -> choose last 3 months.
4) Then click show table. There's alot of zero's which we aren't interested in so if you come across 0's for quantity, don't include that row.
5) we want both columns for each month. Date in format YYYY-MM-01. So the final array should look like: <date,export_country, value,quantity>

You could store it in one final array if you like with a type col also.

=cut
	my @data;
	
	$self->updateDB("eeg.enagas_monthly_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


