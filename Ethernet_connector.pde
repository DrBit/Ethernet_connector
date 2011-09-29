
#if defined(ARDUINO) && ARDUINO > 18
#include <SPI.h>
#endif
#include <Ethernet.h>
#include <EthernetDHCP.h>
#include <EthernetDNS.h>


#define ID             1    //incase you have more than 1 unit on same network, just change the unit ID to other number

#define _version "V0.6"

byte mac[] = { 
  0xDE, 0xAD, 0xCA, 0xEF, 0xFE,  byte(ID) };

// Not needed when using DNS
byte server_ipAddr [4] = {  
  // 209, 40, 205, 190		// www.pachube.com
  // 10,42,43,50			// Mybook (Intranet)
  // 8,8,8,8				// Google DNS server (Internet)
  // 95,154,194,55			// personal server
  0,0,0,0					// Dummy
};

/*
byte printer_ipAddr [4] = {  
  10,10,249,105				// Local IP of the printer address
};*/

// testing at home
byte printer_ipAddr [4] = {  
  10,42,43,51				// Local IP of the printer address
};


uint16_t printer_port = 8000;


Client client(server_ipAddr, 80);

const char* ip_to_str(const uint8_t*);		// Format IP address



void setup()
{
	Serial.begin(9600);
	delay(200);
	// wait_for_host();
	get_configuration();
	Ethernet_setup();
}


boolean executed = false;
boolean received_data = false;
boolean got_ip = false;
boolean print_once = false;
boolean connected = false;
boolean got_response = false;

#define generateLabel false
#define printLabel true
boolean connection_case = generateLabel;
 
void loop()
{
	int dhcp_state = Ethernet_mantain_connection();
	// if we receive an oder from the serial port
	if (dhcp_state == 1) {// if we have obtained an IP address..
		// when we have an IP We execute orders (one time only)
		wait_for_print_command ();	// Wait until the counter sends us the command to print a label
		if (got_ip) {				// If we get IP from the name
			if (connection_case == generateLabel) {
				client.server_ip(server_ipAddr);		// Refresh the IP addres to connect to
			}else{
				#if defined DEBUG_serial
				Serial.println("Change IP to printer");
				#endif
				client.server_ip(printer_ipAddr);		// Change IP to the next client
				client.server_port(printer_port);		// Change port to the next client
			}
			if (!executed) {						// If we didn got an answedr from the server yet
				if (!connected) {
					connected = Ethernet_open_connection ();
				}else if (connected) {  // Open connection
					// We have an oppen connection with the server so we send our requests
					if (connection_case == generateLabel) {
						generate_label ();						// Send request to generate label
						getResponse();							// get and processe response
						if (got_response) {
							connection_case = printLabel;			// Change the mode so next time we have a connection we will print
							stopEthernet();
							got_response = false;
							#if defined DEBUG_serial
							mem_check ();
							#endif
						}
					}else if (connection_case == printLabel) {
						print_label ();							// Send request to print the label
						// getResponse();	//Do we need answer?// get and processe response
						//if (got_response) {
							//if (printed) 
							executed = true;		// Means we did all the process so we need to stop and wait again
							print_state = ready;	// Means we will request the server another print comand
							stopEthernet();
							//got_response = false;									
						//}
					}
				}
			}
		}else{
			// If we havent get an IP we have to ask for one (only in case its a host
			if (connection_case == generateLabel) {		// When generate label we connect trough a host name so we need the IP
				get_ip_from_dns_name();		// Asks for a host and gets the IP addres trough DNS
			}else{
				got_ip = true;				// because the IP of the printer we already took it from the previous configuration
			}
		}
	}else{
		// We are obtaining or renewing a DHCp lease, if we wait too much means error...
		// implement error
		// Serial.print("0"); send arduino a confirmation that has been an error
	}
}