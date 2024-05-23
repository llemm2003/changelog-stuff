SET SERVEROUTPUT ON
set linesize 10000
DECLARE
/* Start of Script related variables */
g_json_tbl_name varchar2(15) := 'CHANGELOG_TBL';
g_json_dir_alias varchar2(13) := 'JSON_DIR_TEST';
g_json_dir_os varchar2(50) := '/var/log/change/';
g_json_changelog_file varchar2(30) := 'change.log';
g_tmp_string varchar2(100);
g_t_dir_name_os varchar2(100);
g_t_dir_alias varchar2(13);
create_tbl_message varchar2(100);
t_test number(1);
g_json_string varchar2(4000);
/* Start of Script related variables */

/* Start of Changelog related variables */
g_rcd_id varchar2(5) := '00023';
g_change_action varchar2(100) := 'Tablespace autocorrective action via OEM';
g_ticket_system varchar2(3) := 'RCD';
g_change_implementer varchar2(3) := 'OEM';
g_change_type varchar2(8) := 'CIUPDATE';
g_host_name varchar2(80);
g_change_timestamp varchar2(60); --iso8601 format
g_escalation_contact varchar2(29) := 'GBU-GBUCS-Database-Operations';
g_change_source varchar2(15) := 'sqlplus via OEM';
g_change_status_code varchar2(17) := 'change-status-000';
g_change_tag_1 varchar2(30) := 'OEM-TST';
g_change_tag_2 varchar2(30) := 'TABLESPACE-TST';
/* End of Changelog related variables */

/* Start of anonymous procedure for this activity */
PROCEDURE Populate_Hostname_time (full_hostname OUT varchar2, iso_time OUT varchar2 ) IS
	l_hostname varchar2(15);
	l_domain varchar2(60);
	l_date_sysdate varchar2(10);
	l_time_sysdate varchar2(8);
	BEGIN
		select host_name into l_hostname from v$instance;
		select value into l_domain from v$parameter where name='db_domain';
		full_hostname := l_hostname ||'.'||l_domain;
		select to_char(sysdate,'YYYY-MM-DD'),to_char(sysdate,'HH24:MI:SS') into l_date_sysdate,l_time_sysdate from dual;
		dbms_output.put_line(l_date_sysdate||'   '||l_time_sysdate);
		iso_time := l_date_sysdate||'T'||l_time_sysdate||'+0000';
	END;

PROCEDURE Create_table_for_json_data (in_tbl_name IN varchar2, out_create_status OUT varchar2) IS
	l_tmp_string varchar2(500); 
	l_tbl_is_exist_counter number(1);
	BEGIN
		out_create_status  := 'OK';
		dbms_output.put_line('TBL NAME: '||in_tbl_name);
		l_tmp_string := 'create table '||in_tbl_name||' (host_name varchar2(80),change_action varchar2(100),ticket_system varchar2(3),
		change_implementer varchar2(3),change_type varchar2(8),change_timestamp varchar2(60),escalation_contact varchar2(29),
		change_source varchar2(15),change_status_code varchar2(17),change_tag_1 varchar2(30),change_tag_2 varchar2(30),rcd_id varchar2(5))';
		select count(*) into l_tbl_is_exist_counter from dba_tables where table_name=in_tbl_name;
		IF l_tbl_is_exist_counter > 0 THEN
			EXECUTE IMMEDIATE 'drop table '||in_tbl_name;
		END IF;
		EXECUTE IMMEDIATE l_tmp_string;
		EXCEPTION
			WHEN OTHERS  THEN  out_create_status := sqlerrm;
	END;
	
PROCEDURE Insert_data_to_table (	in_tbl_name IN varchar2,
										in_p_host_name varchar2,
										in_p_change_timestamp varchar2,
										in_p_change_action varchar2,
										in_p_ticket_system varchar2,
										in_p_change_type varchar2,
										in_p_rcd_id varchar2,
										in_p_escalation_contact varchar2,
										in_p_change_source varchar2,
										in_p_change_implementer varchar2,
										in_p_change_status_code varchar2,
										in_p_change_tag_1 varchar2,
										in_p_change_tag_2 varchar2) IS
	l_tmp_string varchar2(1000) := 'INSERT INTO '||in_tbl_name||'(host_name,
									change_timestamp,
									change_action,
									ticket_system,
									change_type,
									rcd_id,
									escalation_contact,
									change_source,
									change_implementer,
									change_status_code,
									change_tag_1,
									change_tag_2 )
									VALUES ('''||in_p_host_name||''','''||
									in_p_change_timestamp||''','''||
									in_p_change_action ||''','''||
									in_p_ticket_system||''','''||
									in_p_change_type||''','''||
									in_p_rcd_id||''','''||
									in_p_escalation_contact ||''','''||
									in_p_change_source ||''','''||
									in_p_change_implementer ||''','''||
									in_p_change_status_code ||''','''||
									in_p_change_tag_1||''','''||
									in_p_change_tag_2||''')';   
	BEGIN
		EXECUTE IMMEDIATE l_tmp_string;
		dbms_output.put_line(l_tmp_string);
	END;

PROCEDURE  convert_data_json (in_tbl_name IN varchar2, out_json_string OUT varchar2) IS
	--l_tmp_json_storage varchar2(4000);
	l_tmp_string varchar2(1000) := 	'select json_object(''change_type'' VALUE change_type ,''hostname'' VALUE host_name,''ticket_id'' VALUE rcd_id,
									''ticket_system'' VALUE ticket_system,''change_implementer'' VALUE change_implementer,''escalation_contact'' VALUE escalation_contact,
									''change_source'' VALUE change_source,''timestamp'' VALUE change_timestamp,''change_action'' VALUE change_action,
									''change_status_code'' VALUE change_status_code, ''tags'' VALUE json_array(change_tag_1, change_tag_2 )) from '||in_tbl_name;
	BEGIN
		dbms_output.put_line (l_tmp_string);
		 EXECUTE IMMEDIATE l_tmp_string INTO out_json_string;
	END;

PROCEDURE Append_to_Json_file (in_json_string IN varchar2,in_dir_name IN varchar2,in_file_name IN varchar2) IS
	l_json_writer	UTL_FILE.FILE_TYPE;
	l_json_string 	varchar2(4000) := in_json_string;
	l_dir_alias		varchar2(30) := in_dir_name;
	l_json_file_name	varchar2(20) := in_file_name;
	l_string_json_read varchar2(4000);
	BEGIN
		l_json_writer := UTL_FILE.FOPEN(l_dir_alias,l_json_file_name,'A');
		utl_file.putf(l_json_writer,l_json_string);
		UTL_FILE.fclose(l_json_writer);
	END;
/* End of anonymous procedure for this activity */

/*MAIN*/
BEGIN
g_tmp_string := 'create or replace directory '|| g_json_dir_alias ||' as '''||g_json_dir_os||'''';
dbms_output.put_line (g_tmp_string);
execute immediate g_tmp_string;
Populate_Hostname_time(g_host_name,g_change_timestamp);
Create_table_for_json_data(g_json_tbl_name,create_tbl_message);
select directory_name, directory_path into g_t_dir_alias, g_t_dir_name_os  from dba_directories where directory_name='JSON_DIR_TEST';
dbms_output.put_line ('NAME: '|| g_t_dir_alias||' PATH: '||g_t_dir_name_os);
dbms_output.put_line ('FULL_HOSTNAME: '||g_host_name);
dbms_output.put_line ('Time: '||g_change_timestamp);
dbms_output.put_line ('Change Action: '||g_change_action);
dbms_output.put_line ('Ticket System: '||g_ticket_system);
dbms_output.put_line ('Change type: '||g_change_type);
dbms_output.put_line ('Ticket ID: '||g_rcd_id);
dbms_output.put_line ('Escalation Contact: '||g_escalation_contact);
dbms_output.put_line ('Change Tool: '||g_change_source);
dbms_output.put_line ('Change Implementer: '||g_change_implementer);
dbms_output.put_line ('Status code: '||g_change_status_code);
dbms_output.put_line ('Tag: '||g_change_tag_1);
dbms_output.put_line ('Tag: '||g_change_tag_2);
dbms_output.put_line ('Table Creation Status: '||create_tbl_message);

Insert_data_to_table(g_json_tbl_name,g_host_name,g_change_timestamp,g_change_action,g_ticket_system,g_change_type,g_rcd_id,g_escalation_contact,g_change_source,g_change_implementer,g_change_status_code,g_change_tag_1,g_change_tag_2);
convert_data_json(g_json_tbl_name,g_json_string);
dbms_output.put_line(g_json_string);
Append_to_Json_file(g_json_string,g_json_dir_alias,g_json_changelog_file);
END;
/

/*History

May 2, 2024		Rommell Sabino	First version. Script can form json tables that passes lint. 
								Needs to fix the array on change tag.
May 14, 2024	Rommell Sabino	The array on change_tag fixed. Can write to change.log on /var/log/change/change.log
								Sample output which passed on jsonlint.COMMENT
								{"change_type":"CIUPDATE","hostname":"dtax012zkh1.avp17674dt01.iciad.oraclevcn.com","ticket_id":"00023","ticket_system":"RCD","change_implementer":"OEM","escalation_contact":"GBU-GBUCS-Database-Operations","change_source":"sqlplus via OEM","timestamp":"2024-05-14T10:22:56+0000","change_action":"Tablespace autocorrective action via OEM","change_status_code":"change-status-000","tags":["OEM-TST","TABLESPACE-TST"]}



*/