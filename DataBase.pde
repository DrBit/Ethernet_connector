//*********************
// DEFINE DATABASE
//*********************
#include "WProgram.h"
#include <EEPROM.h>
#include <DB.h>
#include <string.h>

DB db;

#define MY_TBL 1
#define number_of_positions 1


void init_DB () {
	db.create(MY_TBL,sizeof(config),number_of_positions);
	db.open(MY_TBL);
}

void read_records_entry1 () 
{
	db.read(1, DB_REC config);		// Read records
	#if defined DEBUG_serial
	Serial.println("Records readed sccesfully!");
	#endif
}


void Show_all_records()
{
	#if defined DEBUG_serial
	Serial.print("Number of records in DB: ");Serial.println(db.nRecs(),DEC);
	if (db.nRecs()) Serial.println("\nDATA RECORDED IN INTERNAL MEMORY:");
	for (int i = 1; i <= db.nRecs(); i++)
	{
		db.read(i, DB_REC config);
		Serial.print("Memory position: "); Serial.println(i); 
		Serial.print(" * server_address SA: "); Serial.println(config.server_address);
		Serial.print(" * server_script SS: "); Serial.println(config.server_script);
		Serial.print(" * printer_IP IP: "); Serial.println(ip_to_str(config.printer_IP));
		Serial.print(" * printer_port PP: "); Serial.println(config.printer_port);
		Serial.print(" * password PS: "); Serial.println(config.password);
		Serial.print(" * User interface (UI) Server US: "); Serial.println(config.ui_server);
		Serial.print(" * Machine ID MI: "); Serial.println((int)config.machine_id);
	} 
	Serial.println("-----");
	#endif
}


void manual_data_write () {
	
	
	// MANUAL WRITE 
	int position_n = 1;			// Field position in the table (only one)
	
	// comment to save memory
	sprintf(config.server_address, "office.pygmalion.nl");
	sprintf(config.server_script, "/labelgenerator/generate.php?batch_id=");
	config.printer_IP [0] = 10;
	config.printer_IP [1] = 250;
	config.printer_IP [2] = 1;
	config.printer_IP [3] = 8;
	config.printer_port = 8000;
	sprintf(config.password, "YXJkdWlubzpQQXBhWXViQTMzd3I=");
	sprintf(config.ui_server, "robot.eric.nr1net.corp");
	config.machine_id = 1;
	
	
	db.write(position_n, DB_REC config);
	#if defined DEBUG_serial
	Serial.print("Position ");
	Serial.print (position_n);
	Serial.println (" recorded!");
	#endif
	 
	
	//Show_all_records();
}



