#!/usr/bin/perl
=begin
Small script to help DBA on printing the changelog json created by the changelog.sh script.
The changelogging script does not echo the output of the script and there are incidents that DBA got in trouble that the changes are done without running the changelog script 
eventhough the changelogging script was executed. 

The print out of this script will show the changelog and can be used for screenshot and evidence on compliance. 

How to use:

Mandatory parameters(script will exit if this is not supplied). 

-ticket_id=<ticket id>
-ticket_action=<action taken>

Non mandatory.
-change_type=start/stop/ciupdate(default is ciupdate)

Ex:
Ticket number = 123456-131072
Ticket action = "Blah blah blah"
change_type = start/stop/ciupdate

changelog_wrapper.pl -ticket_id=123456-131072 -ticket_action="Blah blah blah" -change_type=ciupdate
or
changelog_wrapper.pl -ticket_id=123456-131072 -ticket_action="Blah blah blah" 


=cut
use strict; use warnings;

#variable declaration
my $change_log_file='/var/log/change/change.log';

#function and procedure declaration.
sub accepted_parameter {
	my @accepted_parameters=@_;
	my %parameter_test;
	#Look-up table for accepted parameter. 
	my @accepted_parameter_name=('ticket_id','ticket_action','change_type');
	foreach my $stg_var (@accepted_parameters) {
		#This will test parameters and parameter values. ticket_id should follow the ticket id format.(CX only). Change type should only have the accepted value of STOP START or CIUPDATE(insensitive). 
		if ( $stg_var=~/^-(ticket_id)=(\d{6}-\d{6})\z/ or $stg_var=~/^-(ticket_action)=([\w\s\.\',].*)/ or $stg_var=~/^-(change_type)=(?i)(STOP|START|CIUPDATE)/ ) {
			if ( $1 eq 'change_type' ) {
				my $tmp_string=$2;
				$tmp_string=~s/(?<rct>\w)/\u$+{rct}/g;#make it uppercase
				print "Change_TYPE value $tmp_string\n";
				$parameter_test{change_type}=$tmp_string;
			} else {
				$parameter_test{$1}=$2;
			}
		} else {die "parameter $1 failed the test\n"}
		print "Key $1 is $parameter_test{$1}\n";
	}
	if (! exists $parameter_test{change_type} or ! defined   $parameter_test{change_type} ) {#If parameter change_type is not defined, auto value is CIUPDATE
		$parameter_test{change_type}='CIUPDATE';
	}
	foreach my $stg_var2 (@accepted_parameter_name) {
		if (! exists $parameter_test{$stg_var2} ) {
				die "Needed parameter $stg_var2 is required"; #Script will exit if any required parameter is not found. 
		}
	}
	return %parameter_test;
}

sub run_change_log {
	my %parameter_hash=accepted_parameter(@ARGV);
	my $execute_change_string = "/usr/local/bin/changelog.sh -t $parameter_hash{ticket_id} -n \"$parameter_hash{ticket_action}\" -r 0 $parameter_hash{change_type}";
	print "$execute_change_string\n";
	my $execute_change_logging = qx |$execute_change_string|;
	print_change_log_entry( $parameter_hash{ticket_id});
}

sub print_change_log_entry {
	my $ticket_id=$_[0];
	print "Checking in changelog $ticket_id=$_[0]\n";
	my @output_json = qx| jq -r ' (select(.ticket_id == "$ticket_id"))'  $change_log_file| ;
	print "$_" for @output_json;
}

#MAIN
run_change_log;


=begin History

May 4, 2024 -- rommell sabino Test code.
May 14, 2024 -- Added table for parameters. 

=cut