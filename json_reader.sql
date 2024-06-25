set serveroutput on
DECLARE
/*
PLSQL Script that will:
1. Parse the lifecycle of the DB from PDJ. 
2. Check if DG. 

Since Lifecycle information of the DB is not anywhere inside the DB. This script will capture Json values from either from the two pdj directory:
/opt/gbucs/prov/platform_deploy.json
/var/tmp/platform_deploy.json

Using the JSON query expression: '.deploymentVariables."Environment Code".name' 

*/
/*JSON RELATED VARIABLES*/
g_tmp_string varchar2(200);
g_json_dir_alias varchar2(13) := 'JSON_DIR_TEST';
g_json_os_filename varchar2(50) := 'platform_deploy.json';
g_pdb_directory_name varchar2(20) := '/var/tmp/';
g_clob_column clob;
g_lifecycle varchar2(20);
g_temporary_table varchar2(20) := 'JSON_FILE_TABLE';
g_file_handle utl_file.file_type;
g_string varchar2(4000) := 'NO';
g_string2 varchar2(4000);
g_working_dir varchar2(4000);
g_json_select_string varchar2(200) := 'select JT.* from JSON_FILE_TABLE, JSON_TABLE( a,''$.deploymentVariables."Environment Code"'' COLUMNS(lifecycle varchar2(20) PATH ''$.name'') )AS JT';
TYPE g_os_directory_type IS TABLE OF varchar2(50);
g_os_directory_names g_os_directory_type := g_os_directory_type('/var/tmp/','/opt/gbucs/prov/');
/*END OF JSON RELATED VARIABLES*/

/*DG RELATED VARIABLES*/
g_log_archive_config varchar2(50) ;

/*END OF DG RELATED VARIABLES*/
FUNCTION Create_Test_PDJ (in_directory_alias IN varchar2, in_os_directory IN varchar2, in_pdj_file IN varchar2) RETURN varchar2 IS
	l_file_handle utl_file.file_type;
	l_create_directory_command varchar2(100);
	l_string_storage varchar2(4000);
	l_found_directory_string varchar2(4000);
BEGIN
	--dbms_output.put_line ('TEST THE DIRECTORY :'||in_os_directory);
	l_create_directory_command := 'CREATE OR REPLACE DIRECTORY '||in_directory_alias||' as '''||in_os_directory||'''';
	execute immediate (l_create_directory_command);
	BEGIN
	l_file_handle := utl_file.fopen(in_directory_alias,in_pdj_file,'R');
	EXCEPTION 
		WHEN OTHERS THEN
		NULL;
		--dbms_output.put_line('NOT THIS '||in_os_directory||sqlerrm);
	END;
	l_found_directory_string :=in_os_directory;
	BEGIN
	UTL_FILE.GET_LINE(l_file_handle,l_string_storage);
	EXCEPTION 
		WHEN OTHERS THEN 
		l_found_directory_string := 'NO';
	END;
	UTL_FILE.FCLOSE(l_file_handle);
	--dbms_output.put_line('This is the working directory: '||l_found_directory_string);
	RETURN l_found_directory_string;
END Create_Test_PDJ;

PROCEDURE Create_populate_table_JSON (in_table_name IN varchar2,in_directory_alias IN varchar2,in_os_directory IN varchar2,in_pdj_file_name IN varchar2) IS
	l_create_table_command varchar2(100);
	l_create_directory_command varchar2(100);
	l_filename_handle utl_file.file_type;
	l_clob_column clob;
	l_string_storage varchar2(4000);
	l_string_command varchar2(4000);
	l_table_counter INTEGER;
BEGIN
	l_create_directory_command := 'CREATE OR REPLACE DIRECTORY '||in_directory_alias||' as '''||in_os_directory||'''';
	--dbms_output.put_line(l_create_directory_command);
	execute immediate (l_create_directory_command);
	l_create_table_command :=  'CREATE TABLE '||in_table_name||' (a clob)';
	select count(*) into l_table_counter from dba_tables where table_name=in_table_name;
	IF l_table_counter >= 1 THEN
		execute immediate ('DROP TABLE '|| in_table_name);
	END IF;
	execute immediate (l_create_table_command);
	dbms_lob.createtemporary(l_clob_column,true);
	l_filename_handle := utl_file.fopen(in_directory_alias,in_pdj_file_name,'R');
	LOOP
		BEGIN
			utl_file.get_line(l_filename_handle,l_string_storage);
			IF g_string IS NOT NULL THEN
				dbms_lob.append(l_clob_column,l_string_storage);
			END IF;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
				EXIT;
		END;
	END LOOP;
	l_string_command := 'INSERT INTO '||in_table_name||' (a) values (:1)';
	execute immediate l_string_command using l_clob_column;
END;

BEGIN /*MAIN*/
	--DG CHECK
	SELECT NVL(value,'NO DG') INTO g_log_archive_config from v$parameter where name='log_archive_config';
	--END OF DG CHECK
	
	--Lifcycle check
	FOR i IN g_os_directory_names.FIRST..g_os_directory_names.LAST 
	LOOP
		--dbms_output.put_line('TESTING THIS:'||g_os_directory_names(i));
		g_string := Create_Test_PDJ(g_json_dir_alias,g_os_directory_names(i),g_json_os_filename);
		--dbms_output.put_line(g_string);
		IF g_string <> 'NO' THEN
			g_working_dir := g_string;
		END IF;
	END LOOP;
	--dbms_output.put_line('THIS IS THE WORKING DIRECTORY: '||g_working_dir);
	g_json_dir_alias := 'JSON_DIR';
	Create_populate_table_JSON(g_temporary_table,g_json_dir_alias,g_working_dir,g_json_os_filename);
	execute immediate (g_json_select_string) into g_lifecycle;
	dbms_output.put_line('LIFECYCLE =>'||g_lifecycle);
	--END of lifecycle check.
	dbms_output.put_line('DG =>'||g_log_archive_config);
END  /*MAIN*/;


/*
History:
June 25, 2024 Rommell Sabino
*/