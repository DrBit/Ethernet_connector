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

struct MyRec {
	// Containig
	char server_address[25];			// example: office.pygmalion.nl
	char server_script[45];				// example: /labelgenerator/generate.php?batch_id=
	char printer_IP[15];				// example: 10.250.1.8
	char printer_port[6];				// example: 8000
	char password[30];					// example: YXJkdWlubzpQQXBhWXViQTMzd3I=
	char ui_server[25];					// example: robot.eric.nr1net.corp
	unsigned int machine_id;			// example: 1
} config;

void init_DB () {
	db.create(MY_TBL,sizeof(config),number_of_positions);
	db.open(MY_TBL);
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
		Serial.print(" * printer_IP IP: "); Serial.println(config.printer_IP);
		Serial.print(" * printer_port PP: "); Serial.println(config.printer_port);
		Serial.print(" * password PS: "); Serial.println(config.password);
		Serial.print(" * User interface Server US: "); Serial.println(config.ui_server);
		Serial.print(" * Machine ID MI: "); Serial.println(config.machine_id);
	} 
	Serial.println("-----");
	#endif
}


void manual_data_write () {
	
	
	// MANUAL WRITE 
	int position_n = 1;			// Field position in the table (only one)
	
	/*   // comment to save memory
	sprintf(config.server_address, "office.pygmalion.nl");
	sprintf(config.server_script, "/labelgenerator/generate.php?batch_id=");
	sprintf(config.printer_IP, "10.250.1.8");
	sprintf(config.printer_port, "8000");
	sprintf(config.password, "YXJkdWlubzpQQXBhWXViQTMzd3I=");
	sprintf(config.ui_server, "robot.eric.nr1net.corp");
	config.machine_id = 1;
	*/
	
	db.write(position_n, DB_REC config);
	#if defined DEBUG_serial
	Serial.print("Position ");
	Serial.print (position_n);
	Serial.println (" recorded!");
	#endif
	 
	
	//Show_all_records();
}

