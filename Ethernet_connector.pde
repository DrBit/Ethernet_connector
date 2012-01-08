#if defined(ARDUINO) && ARDUINO > 18
#include <SPI.h>
#endif

#include <Ethernet.h>
#include <EthernetDHCP.h>
#include <EthernetDNS.h>


#define ID             1    //incase you have more than 1 unit on same network, just change the unit ID to other number

#define _version "V1.3"

///////////////////////
// NETWORK UTILITIES
///////////////////////

 #define DEBUG_serial

// #if defined DEBUG
// Serial.println(val);
// #endif


////////////////////////
// XML VARs & DEFINES
////////////////////////

//Defines
#define max_tag_leng 12		// Max leng of tag
#define max_data_leng 80		// Max leng of tag
#define numberOfTags 1			// Define the number of tags we are gona use (remember last one is /0)

//VARs
const char* myTagStrings[numberOfTags]={"<response>"};   // Array of tags
char tagRec[max_tag_leng];		// Var containg the tag
char dataRec[max_data_leng];	// Var containg the data  

// int  Data_results[numberOfTags]={0, 0};
int data_type = 0;				// Container to store the type of data acording to the tag

//VARs for storing results
// char labelParameter[max_data_leng];

// FLAGS
boolean tag_mode =false;
boolean data_mode = false;
boolean inici = true;
boolean got_match = false;

////////////////////////
// NETWORK VARs & DEFINES
////////////////////////

const int buffer_command = 3;
const int buffer_batch = 4;
const int buffer = 44;
const int bufferShort = 31;
char hostName[bufferShort]= "office.pygmalion.nl";
char hostAddress[buffer] = "/labelgenerator/generate.php?batch_id=";
char password[bufferShort] = "YXJkdWlubzpQQXBhWXViQTMzd3I=";
uint16_t printer_port = 8000;
char seeds_batch[buffer_batch] = "600";

// boolean print_state = 0;
// #define ready 0
// #define printing 1

byte mac[] = { 
  0xDE, 0xAD, 0xCA, 0xEF, 0xFE,  byte(ID) };

// Not needed when using DNS
byte server_ipAddr [4] = {  
  0,0,0,0					// Dummy
};

// UI server ip address
byte UIserver_ipAddr [4] = {  
  0,0,0,0					// Dummy
};

// testing at home
byte printer_ipAddr [4] = {  
  10,10,249,116				// Local IP of the printer address (Haarlem)
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
	// manual_data_write ();	// Write temp variables in the eeprom
	Show_all_records();			// Show records in the eeprom, (Not executed in no debug mode
	open_comunication_with_arduino ();	// Opens serial comunications with arduino
	Enable_Ethernet();			// Enebales ethernet module
}


// Flags
boolean received_data = false;
boolean got_ip = false;
boolean print_once = false;
boolean connected = false;
boolean got_response = false;
 
// Program states
#define CONFIGURE 1
#define START 2
#define GET_LABEL 3
#define PRINT_LABEL 4
#define UPDATE_POSITIONS 5
int program_state = CONFIGURE; 

// Retries control
int retries = 0;
int last_program_state = 0;

// Main loop
void loop()
{
	// Check if we have to renew the DHCP lease with the gateway or obtain an IP if starting
	int dhcp_state = Ethernet_mantain_connection();
	
	
	
	if (dhcp_state == 1) {				// if we have obtained an IP address..
		switch (program_state) { 
			// Get all configuration and update if necessary or send to arduino
			case CONFIGURE:	{
				if (!update_configuration ()) {		// if configuration fails might be DNS name is wrong
					// (only once)
					// ASK to arduino mega if DNS name has changed? send the last value we have
					// Has changed? then get data and update
					// try again
					
					// try again or send error *E05* if too much retris
				}else{
					send_command (1);		// Send confirmation that module has been configured correctly
					program_state = START;
				}
			break; }
			
			
			case START: {
				int next_order = wait_for_print_command ();
				if (next_order == 4) {
					program_state = GET_LABEL;			// Wait until the counter sends us the command to print a label
				}
				if (next_order == 5) { 
					program_state = UPDATE_POSITIONS;		// Wait until the counter sends us the command to print a label
				}
				program_state = GET_LABEL;
				// here comes update positions for mega
			break;}
			
			case GET_LABEL: {
				if (got_ip) {							// If we havent resolved an IP we have to resolve it first
					#if defined DEBUG_serial
					Serial.println("Set IP/port to pygmalion");
					#endif
					set_server_ip(server_ipAddr);		// Refresh the IP addres to connect to
					set_server_port(80);				// Change back the port to the default

					if (!connected) {
						connected = Ethernet_open_connection ();
					}else {  // Open connection
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
					get_ip_from_dns_name(hostName,server_ipAddr);		// Asks for a host and gets the IP addres trough DNS
					if (retries >= 2) {
						//send error
						#if defined DEBUG_serial
						mem_check ();
						Serial.println ("too much retries");
						#endif
						program_state = START;
					}
				}
				
			break;}
			
			case PRINT_LABEL:{
				#if defined DEBUG_serial
				Serial.println("Set IP/port to printer");
				#endif
				set_server_ip(printer_ipAddr);			// Change IP to the next client
				set_server_port(printer_port);			// Change port to the next client
				
				if (!connected) {
					connected = Ethernet_open_connection ();
				}else {  // Open connection
					print_label ();							// Send request to print the label
					send_command (06);						// Completed successfully
					program_state = START;					// Goes to the start 
					stopEthernet();
				}
			break;}
			
			case UPDATE_POSITIONS:{
				// answer mega with confirm? or its already done?
				// get all positions from website UI
				// pass them to arduino Mega
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
