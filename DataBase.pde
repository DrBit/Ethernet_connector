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

prog_uchar showall1[] PROGMEM  = {"Number of records in DB: "};
prog_uchar showall2[] PROGMEM  = {"\nDATA RECORDED IN INTERNAL MEMORY:"};
prog_uchar showall3[] PROGMEM  = {"Memory position: "};
prog_uchar showall4[] PROGMEM  = {" * server_address SA: "};
prog_uchar showall5[] PROGMEM  = {" * server_script SS: "};
prog_uchar showall6[] PROGMEM  = {" * printer_IP IP: "};
prog_uchar showall7[] PROGMEM  = {" * printer_port PP: "};
prog_uchar showall8[] PROGMEM  = {" * password PS: "};
prog_uchar showall9[] PROGMEM  = {" * User interface (UI) Server US: "};
prog_uchar showall10[] PROGMEM  = {" * Machine ID MI: "};
prog_uchar showall11[] PROGMEM  = {"-----"};


void Show_all_records()
{
	#if defined DEBUG_serial
	SerialFlashPrint (showall1);;Serial.println(db.nRecs(),DEC);
	if (db.nRecs()) SerialFlashPrintln (showall2);
	for (int i = 1; i <= db.nRecs(); i++)
	{
		db.read(i, DB_REC config);
		SerialFlashPrint (showall3); Serial.println(i); 
		SerialFlashPrint (showall4); Serial.println(config.server_address);
		SerialFlashPrint (showall5); Serial.println(config.server_script);
		SerialFlashPrint (showall6); Serial.println(ip_to_str(config.printer_IP));
		SerialFlashPrint (showall7); Serial.println(config.printer_port);
		SerialFlashPrint (showall8); Serial.println(config.password);
		SerialFlashPrint (showall9); Serial.println(config.ui_server);
		SerialFlashPrint (showall10); Serial.println((int)config.machine_id);
	} 
	SerialFlashPrintln (showall11);
	#endif
}

/*
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
}*/



