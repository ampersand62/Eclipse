
package misc;
use Exporter ();
use warnings;
use strict;
use Date::Calc qw(Add_Delta_Days Today);
use log;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(&commaNumber &trim &getTables &parseDate &parseDateMonText
	&getSite &clean &slurp %monthToNum %txtToNum %frenchMon %alt_french_months &GetBetween &get_gas_year readFile formatDate getGasDate removeComma);

use LWP::UserAgent;
use HTML::TableContentParser;
use HTTP::Request::Common qw(POST GET);

my $table_parser = HTML::TableContentParser->new();
our $agent = LWP::UserAgent->new();


our %monthToNum = (Jan=>1, Feb=>2, Mar=>3, Apr=>4,
	May=>5, Jun=>6, Jul=>7, Aug=>8,
	Sep=>9, Oct=>10, Nov=>11, Dec=>12);
our %numToMonth = map { $monthToNum{$_}=>$_ } keys %monthToNum;

our %txtToNum = (hundred=>'00',thousand=>'0000',million=>,'000000',billion=>'000000000');

our %frenchMon = (
	janvier => 1,
	fvrier => 2,
	mars => 3,
	avril => 4,
	mai => 5,
	juin => 6,
	juillet => 7,
	aot => 8,
	septembre => 9,
	octobre => 10,
	novembre => 11,
	dcembre => 12 );
	
our %alt_french_months = (

janv => 1,
"févr" => 2,
mars =>3,
avr => 4,
mai => 5,
juin => 6,
juil =>7,
"août" =>8,
sept =>9,
"oct" => 10,
nov => 11,
"déc" => 12
);
	
	
sub GetBetween {
	my ($str, $start, $end, $keepstart, $keepend) = @_;
	my $result;
	my $pos1 = index($str, $start) + length($start);
	my $pos2 = index($str, $end, $pos1);
	if ($keepstart) {
		$result = $start;
	}
	$result .= substr($str, $pos1, $pos2 - $pos1);
	if ($keepend) {
		$result .= $end;
	}
		return $result;
}

sub getTables {
	my ($txt,$pred) = @_;
	my %hash;
	foreach my $tab (@{ $table_parser->parse( $txt ) }) {
		my $row = $pred->($tab);
		next unless $row;
		my ($k,$v) = @$row;
		if(exists $hash{ $k }) {
			$hash{ $k } = [ @{$hash{$k}}, @$v ];
		} else { $hash{ $k } = $v; }
	}
	return \%hash;
}

sub slurp {
	open F, $_[0] or
		return complain(2, "Failed to open file $_[0]: $!\n");
	binmode F, ":raw";
	local $/ = undef;
	my $ret = <F>;
	close F;
	return $ret;
}

sub clean {
	my $g = $_;
	$g = join " ", @_ if @_;
	$g =~ tr/!-~//cd;
	return $g;
}


sub parseDate {
	my $dt = shift;
	my %opt = @_;

	use Time::ParseDate;
	use Time::localtime;

	my $res = parsedate($dt, UK=>1, PREFER_PAST=>1); #, DATE_REQUIRED=>1);
	die "Invalid date" unless $res;

	$res = parsedate($dt, UK=>1) if ($res < 0); # bug workaround
	$res += ($opt{date_diff}*24+3)*60*60 if exists $opt{date_diff};

	my $st = localtime $res;
	return sprintf "%04d-%02d-%02d", $st->year + 1900, $st->mon + 1, $st->mday;
}
sub parseDateMonText {
	my $dt = shift;
	my %opt = @_;

	use Time::ParseDate;
	use Time::localtime;

	my $res = parsedate($dt, UK=>1, PREFER_PAST=>1); #, DATE_REQUIRED=>1);
	die "Invalid date" unless $res;

	$res = parsedate($dt, UK=>1) if ($res < 0); # bug workaround
	$res += ($opt{date_diff}*24+3)*60*60 if exists $opt{date_diff};

	my $st = localtime $res;
	my $k;
	if($st->mon==1){$k="Feb";}
	if($st->mon==2){$k="Mar";}
	if($st->mon==3){$k="Apr";}
	if($st->mon==4){$k="May";}
	if($st->mon==5){$k="Jun";}
	if ($st->mon==6){$k="Jul";}
	if ($st->mon==7){$k="Aug";}
	if ($st->mon==8){$k="Sep";}
	if ($st->mon==9){$k="Oct";}
	if ($st->mon==10){$k="Nov";}
	if ($st->mon==11){$k="Dec";}	
	if ($st->mon==0){$k="Jan";}	
		
	return sprintf "%02d-%03s-%02d",  $st->mday, $k, $st->year-100;
	
}
sub trim {
	my $x = @_ ? shift : $_;
	$x =~ s/^ *//;
	$x =~ s/ *$//;
	return $x;
}

sub commaNumber {
	my $x = @_ ? shift : $_;
	$x =~ tr/&nbsp;//d;
	$x =~ s/,/\./;
	return $x;
}


sub get_gas_year {
	
	my($date) = @_;
	
	my $gas_year;
	
	#split the date
	my @arr = split("-",$date);
	
	#converting the year that is passed into an integer
	my $argyear= int($arr[0]);
		
	#getting rid of 0 in the month field	
	if($arr[1] =~ m/^0/){
				
			$arr[1]=~ s/0//;
			
	}
		
	#if the month passed is before oct
	if($arr[1]<10){
		
		my $last_year = $argyear -1;
		$gas_year = $last_year;
		
		debug("Gas year for the date is $gas_year"); 	

		return ("$gas_year","$arr[1]","$arr[2]");
	}
	
	#if month passed is oct or after
	else{
		$gas_year = $argyear; 	
		
		debug("Gas year for the date is $gas_year");
	
		return ("$gas_year","$arr[1]","$arr[2]");
		
	}
		

sub readFile{
	
	my $CSV = slurp(shift);
	my @data = split("\n",$CSV);     
	return @data

}

sub formatDate{
			
	my @dates = @_;
	my @a;		
	foreach my $date(@dates){		
		if(length $date == 1){		
			$date =~ s/$date/0$date/;			
			push(@a,$date);				
		}
		else{
			push(@a,$date);		
		}
						
	} 		
	return \@a;
			
}

sub getGasDate{
	my $gd;	
	my ($yr,$mth,$dy);
	if (shift() < 6){
		($yr,$mth,$dy) = Add_Delta_Days(Today(),-1);	
	}
	else{
		($yr,$mth,$dy) = Today();	
	}
	return parseDate($yr."-".$mth."-".$dy);  
}	

sub removeComma{
	
	my $c = shift();
	$c =~ s/,//g;
	return $c;
}
		
}
1;

