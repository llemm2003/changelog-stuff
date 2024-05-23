# changelog stuff
 Scripts related to changelogging. 

1. changelog_wrapper.pl
	Just a changelog.sh wrapper. 
	
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
	


2. json_writer.sql
	Script that can be used to write json date to change.log. 
	It can be added to sql or plsql scripts to record atomic changes. This will avoid extra jobs/hacks on writing stuff to kibana.
	
	