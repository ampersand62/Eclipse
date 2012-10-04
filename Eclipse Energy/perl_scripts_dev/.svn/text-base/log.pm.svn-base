
package log;
#use warnings;
#use strict;
use Exporter();
our @ISA = qw(Exporter);
our @EXPORT = qw(complain info debug backup log_info log_debug check_website_status check_file_exists imacros_error_file_check check_element);
our $VERSION = 1.00;
use misc qw(slurp);
use conf;
use MIME::Lite;

use POSIX qw(strftime);

MIME::Lite->send ("smtp", "smtp.lyse.net");

my %level = (
		0=>"",
		1=>"Warning: ",
		2=>"ERROR: "
	);


#if you pass a level 0,1 or 2, you get warining or error: in the log file. otherwise just info:
sub complain {
	my ($lvl, $str) = @_;
	return info((exists $level{$lvl} ? $level{$lvl} : "Info: ") . $str . "\n");
}

#just prints to the log file
sub info {
#	open F, ">> $conf::log_file"
#		or return print STDERR "@_\n"; # SILENT ERROR
#	print F @_;
#	close F;
#	undef;
	
	log_info(@_);
}

#just prints to the arguement to the screen
sub debug {
#	local $, = " ";
#	local $\ = "\n";
#	print @_;

	log_debug(@_);

}

#
sub backup {
	my ($f,$c) = @_;
	return unless $conf::backup_dir;
	open F, "> $conf::backup_dir/$f" or
		return complain(2, "Failed to dump backup data: $!");
	print F $c;
	close F;
}


sub register {
	my $h = shift;
	$h->{LOG} = [ "", "Process & send log file (note capital letters)", \&sendLog ];
}


sub sendLog {
	return complain(1, "Log file $conf::log_file not found") unless -e $conf::log_file;

	my $msg = MIME::Lite->new(
		From    => 'tristesse@gmail.com',
		To      => 'tristesse@gmail.com',
		Subject => "Hello World",
	);

	$msg->data( slurp($conf::log_file) );

	$msg->send or complain(1, "Failed to send mail with log!");

	my $dt = scalar localtime;
	$dt =~ tr/a-zA-Z0-9 //cd;
	rename($conf::log_file, "$conf::log_file--$dt");

	return 1;
}



sub log_info {

my($msg,$msg2) = @_;

	#depending on what we've set in conf.pm, we'll write to 
	#either the scheduler log file or the eeg.log file
	if($conf::run_location =~ m/scheduler/){

			print $msg."\n";
		
	}	

	if ($conf::run_location =~ m/console/){
		
		open F, ">> $conf::log_file" or return print STDERR "@_\n";
			my $dt = strftime "%Y-%m-%d_%H.%M.%S", localtime;
			print F $dt."     ".$msg."\n";
		close F;
	}
	if($msg2){
		my $t = $conf::backup_dir."imacros_error_log.txt";
		open F, "> $t" or return print STDERR "@_\n";
			print F $msg."\n";
		close F;
		
	}
}


sub log_debug{

my($log_text) = @_;

#only write to the log if we are running at debug level
if($conf::log_level =~ m/debug/){

info($log_text);

}

}

sub check_website_status{
	
my($status,$URL) = @_;

#checking the http status code
if($status =~ m/200/g){
	
		info("The website $URL has loaded successfully with http status code of $status");
	}
	
	else{
	
		info("The website $URL didn't load OK. Status code $status");
		
	}	
	
}


sub check_file_exists{
	
my($fn) = @_;

#opening the file to see if it has been saved
open F, $fn;
 
#checking for an error in the error variable 
if ($! =~ m/No such file or directory/){
	
	 die("File $fn does not exist");
		
}
else{

	 debug("File $fn was created");
}
}
sub imacros_error_file_check{
	
my($fn) = @_;

#opening the file to see if it has been saved
open F, $fn;
 
#checking for an error in the error variable 
if ($! =~ m/No such file or directory/){
	
	 debug("No imacros error file was created");
		
}
else{

	my $t = slurp($fn);
	close F;
	$fn =~ s/\//\\/g;
	unlink $fn;
	die("ERROR $t");
	 
}

}

sub check_element{
	
my($obj) = @_;

if ($@){

	my $log_text = "Couldn't click on $obj";
	info($log_text);
			
	}
	
else{

	my $log_text = "$obj was  successfully clicked on";
	debug($log_text);
	
};
		
}



1;


