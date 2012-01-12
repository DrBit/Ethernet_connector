#if defined(ARDUINO) && ARDUINO > 18
#include <SPI.h>
#endif

#include <Ethernet.h>
#include <EthernetDHCP.h>
#include <EthernetDNS.h>
#include <avr/pgmspace.h>


#define ID             1    //incase you have more than 1 unit on same network, just change the unit ID to other number

#define _version "V1.4"

///////////////////////
// NETWORK UTILITIES
///////////////////////

 #define DEBUG_serial
 #define NO_DNS				// USE in case we dont have DNS server (ONLY FOR DEBUG)

// #if defined DEBUG
// Serial.println(val);
// #endif


////////////////////////
// XML VARs & DEFINES
////////////////////////

//Defines
#define max_tag_leng 12			// Max leng of tag
#define max_data_leng 110		// Max leng of tag
#define numberOfTags 20			// Define the number of tags we are gona use (remember last one is /0)

#define numberOfPostitions 20	// Define the number of positions we would look for when updating.
// This value should be included in the server to make it easier to update

//VARs
const char* myTagStrings[numberOfTags]={

	"<SA>", "<SS>", "<PS>", "<PP>",
	"<IP1>", "<IP2>", "<IP3>", "<IP4>",
	"<response>"
};   // Array of tags


// Keep non configuration tags at the end of the chain (like response)
byte LastTagNumber = 0;			// Container where we store last found tag
byte LastPosTagNumber = 0;		// Container where we sotre last found position tag
char tagRec[max_tag_leng];		// Var containg the tag
char dataRec[max_data_leng];	// Var containg the data  

// FLAGS for XML
boolean tag_mode =false;
boolean data_mode = false;
boolean inici = true;
boolean got_match = false;


// Records of the DB
struct MyRec {
	// Containig
	char server_address[25];		// example: office.pygmalion.nl
	char server_script[45];			// example: /labelgenerator/generate.php?batch_id=
	byte printer_IP[4];				// example: {10,250,1,8}
	unsigned int printer_port;		// example: 8000
	char password[30];				// example: YXJkdWlubzpQQXBhWXViQTMzd3I=
	char ui_server[25];				// example: robot.eric.nr1net.corp
	byte machine_id;				// example: 1
	//byte numberOfPostitions;		// example: 20
} config;
// When changing the structure data in the eeprom needs to be rewritten

////////////////////////
// NETWORK VARs & DEFINES
////////////////////////

const int buffer_command = 3;
const int buffer_batch = 4;
char seeds_batch[buffer_batch] = "600";

// Generate a random MAC for each device
byte mac[] = { 
  0xDE, 0xAD, 0xCA, 0xEF, 0xFE,  (ID) };

// Need for temporary store the retrieval of IP address from DNS names
byte server_ipAddr [4] = {  
  0,0,0,0					// Dummy
};


#if defined(ARDUINO) && ARDUINO >= 100
EthernetClient client;
#else
Client client(server_ipAddr, 80);
#endif

// Function to format IP and print it in serial com.
const char* ip_to_str(const uint8_t*);		// Format IP address


// Setup
void setup()
{
	Serial.begin(9600);
	delay(200);
	mem_check ();				// Displays memory always to have an idea of free ram
	init_DB ();					// Necessary to init DB
	read_records_entry1 ();		// Reads first row of records in case we have 2 different configurations
	Show_all_records();			// Show records in the eeprom, (Not executed in no debug mode
	// manual_data_write ();	// Write temp variables in the eeprom
	open_comunication_with_arduino ();	// Opens serial comunications with arduino
	Enable_Ethernet();			// Enebales ethernet module
}


// Flags
boolean received_data = false;
boolean got_ip = false;
boolean connected = false;
boolean got_response = false;
 
// Program states
#define CONFIGURE 1
#define START 2
#define GET_LABEL 3
#define PRINT_LABEL 4
#define UPDATE_POSITIONS 5
byte program_state = CONFIGURE; 
byte last_program_state = 0;

// Retries control
byte retries = 0;

// TEXT srtrings

prog_uchar loop1[] PROGMEM  = {"Too much retries."};
prog_uchar loop2[] PROGMEM  = {"Set IP/port to pygmalion."};
prog_uchar loop3[] PROGMEM  = {"Set IP/port to printer"};
prog_uchar loop4[] PROGMEM  = {"Preparing to fetch configuration from the User Interface server."};
prog_uchar loop5[] PROGMEM  = {""};
prog_uchar loop6[] PROGMEM  = {""};
prog_uchar loop7[] PROGMEM  = {""};


// Main loop
void loop()
{
	// Check if we have to renew the DHCP lease with the gateway or obtain an IP if starting
	int dhcp_state = Ethernet_mantain_connection();
	
	if (dhcp_state == 1) {				// if we have obtained an IP address..
		switch (program_state) { 
			// Get all configuration and update if necessary or send to arduino
			case CONFIGURE:	{
				#if defined DEBUG_serial
				SerialFlashPrintln (loop4);
				// Serial.println ("too much retries");
				#endif
				if (!fetch_configuration ()) {		// if configuration fails might be DNS name is wrong
					// (only once)
					// ASK to arduino mega if DNS name has changed? send the last value we have
					// Has changed? then get data and update
					// try again
					
					if (retries >= 3) {
						//send error
						#if defined DEBUG_serial
						mem_check ();
						SerialFlashPrintln (loop1);
						// Serial.println ("too much retries");
						#endif
						program_state = START;	// Or in this case send an error and halt
					}
				}else{
					send_command (1);		// Send confirmation that module has been configured correctly
					program_state = START;
					Show_all_records();		// For debug only
				}
			break; }
			
			case START: {
				byte next_order = wait_for_print_command ();
				if (next_order == 4) {
					program_state = GET_LABEL;			// Wait until the counter sends us the command to print a label
				}
				if (next_order == 18) { 
					program_state = UPDATE_POSITIONS;		// Wait until the counter sends us the command to print a label
				}
				// program_state = GET_LABEL;
				// here comes update positions for mega
			break;}
			
			case GET_LABEL: {
				if (got_ip) {							// If we havent resolved an IP we have to resolve it first
					#if defined DEBUG_serial
					SerialFlashPrintln (loop2);
					// Serial.println("Set IP/port to pygmalion");
					#endif
					set_server_ip(server_ipAddr);		// Refresh the IP addres to connect to
					set_server_port(80);				// Change back the port to the default
					if (!connected) {
						connected = Ethernet_open_connection ();
					}else { 
						// We have an oppen connection with the server so we send our requests
						generate_label ();						// Send request to generate label
						getResponse();							// get and processe response
						if (got_response) {
							stopEthernet();
							got_response = false;				// reset falg
							program_state = PRINT_LABEL;
							#if defined DEBUG_serial
							mem_check ();
							#endif
							received_data = false;				// Reset flag so its secure now that we already process every thing
						}
					}
				}else {
					get_ip_from_dns_name(config.server_address,server_ipAddr);		// Asks for a host and gets the IP addres trough DNS
					if (retries >= 2) {
						//send error
						#if defined DEBUG_serial
						mem_check ();
						SerialFlashPrintln (loop1);
						//Serial.println ("too much retries");
						#endif
						program_state = START;
					}
				}
				
			break;}
			
			case PRINT_LABEL:{
				#if defined DEBUG_serial
				SerialFlashPrintln (loop3);
				// Serial.println("Set IP/port to printer");
				#endif
				set_server_ip(config.printer_IP);			// Change IP to the next client
				set_server_port(config.printer_port);			// Change port to the next client
				
				if (!connected) {
					connected = Ethernet_open_connection ();
				}else {  // Open connection
					sprintf(dataRec, "/%s",dataRec);		// Add missing sing before the string
					char temporal_ip [15];
					sprintf(temporal_ip, ip_to_str(config.printer_IP));
					get_HTTP (dataRec, temporal_ip, config.printer_port);
					// print_label ();							// Send request to print the label
					send_command (06);						// Completed successfully
					program_state = START;					// Goes to the start 
					stopEthernet();
				}
			break;}
			
			case UPDATE_POSITIONS:{
				// answer mega with confirm? or its already done?
				// get all positions from website UI
				// pass them to arduino Mega
				boolean done_it = false;
				byte retries1 = 0;
				while (retries1 < 10) {
					#if defined NO_DNS
					got_ip = true;
					#endif
					if (got_ip) {
						if (!done_it) {
							#if defined NO_DNS
							server_ipAddr[0]=95;
							server_ipAddr[1]=211;
							server_ipAddr[2]=54;
							server_ipAddr[3]=66;
							set_server_ip(server_ipAddr);		// Refresh the IP addres to connect to
							#else
							set_server_ip(server_ipAddr);		// Refresh the IP addres to connect to
							#endif
							set_server_port(80);				// Change back the port to the default
							done_it = true;
						}
						
						if (!connected) {	// open connection and send petition of all configuration data (exclude positions)
							connected = Ethernet_open_connection ();		// Try to open connection
						}else{
							// Send GET petition to get configuration data
							// get_HTTP (address,host);
							char update_script[]="/arduino/get/id/1/data/table=configuration;getallfields";
							get_HTTP (update_script, config.ui_server);
							getResponse();							// Pharse all data received and update if necessary
							if (got_response) {
								stopEthernet();
								got_response = false;				// reset falg
								received_data = false;				// Reset flag so its secure now that we already process every thing
								#if defined DEBUG_serial
								mem_check ();
								#endif
								break;
							}else{
								// if we havent got response, either the server is down or the response was not valid
							}
						}
					}else{
						// try to conect to the previous dns name recorded in Eeprom and retrieve IP
						get_ip_from_dns_name(config.ui_server,server_ipAddr);
					}
					retries1++;
				}
				// Get back to start 
				program_state = START;					// get back to start
			break;}
		}		
	}else{
		// We are obtaining or renewing a DHCp lease, if we wait too much means error...
		// implement error
		// Serial.print("0"); send arduino a confirmation that there has been an error
	}
	
	// Little retries for errors check
	if (program_state != last_program_state) {
		retries = 1;
		last_program_state = program_state;
	}else{
		retries ++;
	}
}


		/*mem_check ();
		wait_for_print_command ();		// Wait until the counter sends us the command to print a label
		if (got_ip) {					// If we get IP from the name
			if (connection_case == generateLabel) {
				#if defined DEBUG_serial
				Serial.println("Set IP and port to pygmalion server");
				#endif
				set_server_ip(server_ipAddr);		// Refresh the IP addres to connect to
				set_server_port(80);					// Change back the port to the default
			}else{
				if (!connected) {
					#if defined DEBUG_serial
					Serial.println("Set IP and port to printer host");
					#endif
					set_server_ip(printer_ipAddr);			// Change IP to the next client
					set_server_port(printer_port);			// Change port to the next client
				}
			}
			if (!executed) {									// If we didn got an answedr from the server yet
				if (!connected) {
					connected = Ethernet_open_connection ();
				}else if (connected) {  // Open connection
					// We have an oppen connection with the server so we send our requests
					if (connection_case == generateLabel) {
						generate_label ();						// Send request to generate label
						getResponse();							// get and processe response
						if (got_response) {
							connection_case = printLabel;		// Change the mode so next time we have a connection we will print
							stopEthernet();
							got_response = false;
							#if defined DEBUG_serial
							mem_check ();
							#endif
							received_data = false;				// Reset flag so its secure now that we already process every thing
						}
					}else if (connection_case == printLabel) {
						print_label ();							// Send request to print the label
						send_command (06);						// Completed successfully
						connection_case = generateLabel;
						executed = true;		// Means we did all the process so we need to stop and wait again
						print_state = ready;	// Means we will request the server another print comand
						stopEthernet();
					}
				}
			}
		}else{
			// If we havent resolved an IP so we have to resolve it first
			if (connection_case == generateLabel) {		// When generate label we connect trough a host name so we need the IP
				get_ip_from_dns_name();		// Asks for a host and gets the IP addres trough DNS
			}else{
				got_ip = true;				// because the IP of the printer we already took it from the previous configuration
			}
		}*/
