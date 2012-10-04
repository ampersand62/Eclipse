=pod
Description: --- Put Description of Code Here ---
Created by: --- Put Name Here ---
Date: --- Put Date Here ---
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::tigf_allocations_storage;

use File::Temp;
our $DEBUG = 1;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);

sub key { "tigf_allocations_storage"; }
sub name { "tigf_allocations_storage";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://tetra.tigf.fr/SBT/public/Allocations.do?action=listeAllocations";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;

	$self->{mech}->get($URL);

	# Checkboxes
	$self->{mech}->tick( 'pointSelectionnes', 356, undef); # Total PITD+PIC
	$self->{mech}->tick( 'pointSelectionnes', 359);        # PEG
	$self->{mech}->tick( 'pointSelectionnes', 333);        # PITT-BIRIATOU
	$self->{mech}->tick( 'pointSelectionnes', 334, undef); # PITT-DORDOGNE
	$self->{mech}->tick( 'pointSelectionnes', 357);        # Total PITD
	$self->{mech}->tick( 'pointSelectionnes', 335);        # PITT-GRTGAZSUD
	$self->{mech}->tick( 'pointSelectionnes', 349);        # PITS
	$self->{mech}->tick( 'pointSelectionnes', 336, undef); # PITT-HERAULT
	$self->{mech}->tick( 'pointSelectionnes', 358);        # Total PIC
	$self->{mech}->tick( 'pointSelectionnes', 337);        # PITT-LARRAU

	my ($year, $month, $day) = Today();

	# From 8 days ago to 1 day ago (no figures for today)
 
	my ($sy, $sm, $sd) = Add_Delta_Days($year, $month, $day, -8);
	my ($ey, $em, $ed) = Add_Delta_Days($year, $month, $day, -1);

	$self->{mech}->field('validiteDebut', sprintf("%02d/%02d/%04d", $sd, $sm, $sy));
	$self->{mech}->field('validiteFin', sprintf("%02d/%02d/%04d", $ed, $em, $ey));

	$self->{mech}->submit();
	
	$self->{mech}->form_id('formuexport');
	$self->{mech}->field('listeExportAllocation', 'csv');
	$self->{mech}->submit();

	my $temp = File::Temp->new();
	print $temp $self->{mech}->content();

	$temp->seek(0, 0);

	$_ = <$temp>; # Lose the title line

	while (<$temp>) {
	    chomp;
	    my (
		$d, 
		$grtgaz_e,
		$grtgaz_x,
		$larrau_e,
		$larrau_x,
		$biriatou_e,
		$biriatou_x,
		$pits_e,
		$pits_x,
		$peg_e,
		$peg_x,
		$pic_t_x,
		$pitd_t_x
		) = split /;/;

	    $d =~ m!(\d\d)/(\d\d)/(\d\d\d\d)!;
	    my $date = "$3-$2-$1";

 	    print "$date, PITT-GRTGAZSUD, $grtgaz_e, $grtgaz_x\n" if $DEBUG;
	    push @data, [$date, 'PITT-GRTGAZSUD', $grtgaz_e, $grtgaz_x] unless $DEBUG;
 	    print "$date, PITT-LARRAU, $larrau_e, $larrau_x\n" if $DEBUG;
	    push @data, [$date, 'PITT-LARRAU', $larrau_e, $larrau_x] unless $DEBUG;
 	    print "$date, PITT-BIRIATOU, $biriatou_e, $biriatou_x\n" if $DEBUG;
	    push @data, [$date, 'PITT-BIRIATOU', $biriatou_e, $biriatou_x] unless $DEBUG;
 	    print "$date, PITS, $pits_e, $pits_x\n" if $DEBUG;
	    push @data, [$date, 'PITS', $pits_e, $pits_x] unless $DEBUG;
 	    print "$date, PEG, $peg_e, $peg_x\n" if $DEBUG;
	    push @data, [$date, 'PEG', $peg_e, $peg_x] unless $DEBUG;
 	    print "$date, Total PIC, 0, $pic_t_x\n" if $DEBUG;
	    push @data, [$date, 'Total PIC', 0, $pic_t_x] unless $DEBUG;
 	    print "$date, Total PITD, 0, $pitd_t_x\n" if $DEBUG;
	    push @data, [$date, 'Total PITD', 0, $pitd_t_x] unless $DEBUG;

	}

	# Now the 'Storage' Page....
	$self->{mech}->get($URL);
	$self->{mech}->follow_link(text => 'Storage');

	$self->{mech}->field('validiteDebut', sprintf("%02d/%02d/%04d", $sd, $sm, $sy));
	$self->{mech}->field('validiteFin', sprintf("%02d/%02d/%04d", $ed, $em, $ey));

	$self->{mech}->submit();
	$self->{mech}->form_id('formuexport');
	$self->{mech}->field('listeStockageExport', 'csv');
	$self->{mech}->submit();

	$temp = File::Temp->new();
	print $temp $self->{mech}->content();

	$temp->seek( 0, 0);

	$_ = <$temp>;

	while (<$temp>) {

	    chomp;
	    my ($d, $storage, $withdrawel, $injection, $volume) = split /;/;

	    $d =~ m!(\d\d)/(\d\d)/(\d\d\d\d)!;
	    my $date = "$3-$2-$1";

	    $storage =~ tr/,%/./d;
	    $withdrawel =~ tr/,%/./d;
	    $injection =~ tr/,%/./d;
	    $volume =~ tr/,%/./d;

	    print "$date: $storage, $withdrawel, $injection, $volume\n" if $DEBUG;
	    push @data, [$date, $storage, $withdrawel, $injection, $volume] unless $DEBUG;
	}
=pod
#1)	INSTRUCTIONS:
1) go to http://tetra.tigf.fr/SBT/public/Allocations.do?action=listeAllocations								
2) 1. At the link above there is a drop down menu at the top left of the page called pulications. Select "Allocated Quantities" from the list. 
This will present a page with tick boxes to pick which data to download. Please select: Total PITD, Total PIC, PEG, PITT-GRTGAZSUD, PITT-LARRAU, PITT-BIRIATOU  and PITS. 
The data range can be set at the top of the page. We'd like to collect last 7 days in each run.
3) You can get the data straight from page, or the csv/xls from the bottom of the page. Date in usual <YYYY-MM-DD> format.
4) So we'd like the final data in: <date,point_name,point_name,entry,exit>. You'll notice that PEG has traded numbers, but just put them in entry/exit cols.

1) 2. From the same publications list, select "Storage". This time all that needs to be selected is the date range, b. Again, last 7 days please.
2) We'd like all the columns from the resulting page. So the final array should be: <date,storage,withdrawal,injection,volume>;




=cut
	
	$self->updateDB("eeg.enagas_monthly_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


