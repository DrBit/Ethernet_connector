
#if defined(ARDUINO) && ARDUINO > 18
#include <SPI.h>
#endif
#include <Ethernet.h>
#include <EthernetDHCP.h>
#include <EthernetDNS.h>


#define ID             1    //incase you have more than 1 unit on same network, just change the unit ID to other number

#define _version "V0.4"

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

byte printer_ipAddr [4] = {  
  // 209, 40, 205, 190		// www.pachube.com
  // 10,42,43,50			// Mybook (Intranet)
  // 8,8,8,8				// Google DNS server (Internet)
  // 95,154,194,55			// personal server
  0,0,0,0					// Dummy
};

uint16_t printer_port;


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
 
void loop()
{
	int dhcp_state = Ethernet_mantain_connection();
	// if we receive an oder from the serial port
	if (dhcp_state == 1) {// if we have obtained an IP address..
		// when we have an IP We execute orders (one time only)
		wait_for_print_command ();	// Wait until the counter sends us the command to print a label
		if (got_ip) {				// If we get IP from the name
			client.server_ip(server_ipAddr);		// Refresh the IP addres to connect to
			if (!executed) {						// If we didn got an answedr from the server yet
				if (!connected) {
					connected = Ethernet_open_connection ();
				}else if (connected) {  // Open connection
					
					// option 1
					generate_label ();
					getResponse();
					client.server_ip(printer_ipAddr);		// Change IP to the next client
					client.server_port(printer_port);		// Change port to the next client
					stopEthernet();
					
					// option 2
					print_label ();
					getResponse();
					if (received_data) executed = true;
					stopEthernet();
				}
			}
		}else{
			// If we havent get an IP we have to ask for one
			get_ip_from_dns_name();		// Asks for a host and gets the IP addres trough DNS
		}
	}else{
		// We are obtaining or renewing a DHCp lease, if we wait too much means error...
		// implement error
		// Serial.print("0"); send arduino a confirmation that has been an error
	}
}