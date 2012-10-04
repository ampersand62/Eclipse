=pod
Description: Screap of Zeebrugge Hub Excel sheets. 
Problems encountered:
 a) The list of downloads is currently malformed; the first two <a> tags get 
mixed up as do the first HTML list entries. This code works round this, but 
may need modification once Zeebrugge get their page design correct.
 b) The first download caused problems with getting Spreadsheet::ParseExcel to
decode it (though not, oddly the second and subsequent ones. I guess this may
again be a transient fault on ZB's site.

Created by: Andy Holyer
Date: 4 May 2012
=cut


# --- Please dont' edit anything in this section. Feel free to add Perl modules to use --- #
package Site::zb_hub_liquidity;

our $DEBUG = 1;
our $TEMP = '/tmp/test.xslx';

use File::Temp;
use Text::Iconv;
my $converter = Text::Iconv->new( 'utf-8', 'windows-1251');
use Spreadsheet::XLSX;
use Spreadsheet::ParseExcel::Utility qw(ExcelFmt ExcelLocaltime LocaltimeExcel);
use Data::Dumper;

use warnings;
use strict;
use Date::Calc qw(Delta_Days Add_Delta_Days Today Now);
use misc qw(%monthToNum %txtToNum %frenchMon %alt_french_months GetBetween 
			getTables slurp clean parseDate parseDateMonText trim commaNumber get_gas_year 
			readFile formatDate getGasDate removeComma);
use log;
use base qw(Site);

sub key { "zb_hub_liquidity"; }
sub name { "zb_hub_liquidity";}
sub usesWWW { 1; }
#

#URL of website to scrape
my $URL = "http://www.huberator.com/information/hub_volumes.aspx";

sub scrape {
	
	#has the mechanize object. 
	my $self = shift;
	my @data;
	$self->{mech}->get($URL);

	# I'm banking here on the fact that the Data Publication links are 
	# consistently listed in reverse time order.
	my $link = $self->{mech}->find_link(
	    url_regex => qr/huberator_datapublication/i,
	    n => 1
	    );

	$self->{mech}->get($link->url());

#	my $excel = File::Temp->new(
#	    suffix => '.xlsx'
#	    );

	open EXCEL, $TEMP;
	print EXCEL $self->{mech}->content();
	close EXCEL;
	print "Done!\n" if $DEBUG;

	my $wb = Spreadsheet::XLSX -> new($TEMP, $converter);



	my $sheet = $wb->{Worksheet}[0];

	for my $row ($sheet->{MinRow} .. $sheet->{MaxRow}) {
	    my $cell = $sheet->{Cells}[$row][0];

	    next unless $cell;
	    if ($cell->{Type} eq 'Numeric') {

		my $date =  ExcelFmt('yyyy-mm-dd', $cell->{Val});
		# We also want cols 2 == traded and 5 == physical
		my $traded = $sheet->{Cells}[$row][2]->{Val};
		my $physical =  $sheet->{Cells}[$row][5]->{Val};

		print "$date: $traded, $physical\n" if $DEBUG;

		push @data, [$date, $traded, $physical];
	    };

	}	

	unlink($TEMP);
=pod
#1)	INSTRUCTIONS:

1) - Go to http://www.huberator.com/information/hub_volumes.aspx
2) Get the latest Data publication (i.e. for today its the 2012 one).
3) From the excel file, we want the traded and physical throughput in gWh.
4) Date should be in format YYYY-MM-DD. the final array should look like: <date,traded,physical throughput>.

=cut

	
	$self->updateDB("eeg.zb_hub_liquidity_arrivals",["eta","etd","vessel"],["berth"],\@data,name());
		
	#exits the method
	return 1;
	
}

1;


