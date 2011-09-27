//  Copyright (C) 2010 Georg Kaindl
//  http://gkaindl.com
//
//  This file is part of Arduino EthernetDHCP.
//
//  EthernetDHCP is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as
//  published by the Free Software Foundation, either version 3 of
//  the License, or (at your option) any later version.
//
//  EthernetDHCP is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with EthernetDHCP. If not, see
//  <http://www.gnu.org/licenses/>.
//

//  Illustrates how to use EthernetDHCP in polling (non-blocking)
//  mode.

#if defined(ARDUINO) && ARDUINO > 18
#include <SPI.h>
#endif
#include <Ethernet.h>
#include <EthernetDHCP.h>
#include <EthernetDNS.h>


#define ID             1    //incase you have more than 1 unit on same network, just change the unit ID to other number

byte mac[] = { 
  0xDE, 0xAD, 0xCA, 0xEF, 0xFE,  byte(ID) };

byte server [] = {  
  // 209, 40, 205, 190		//www.pachube.com
  // 10,42,43,50			// Mybook (Intranet)
  // 8,8,8,8				// Google DNS server (Internet)
  95,154,194,55				// personal server
};

Client client(server, 80);


const char* ip_to_str(const uint8_t*);		// Format IP address

void setup()
{
	Serial.begin(9600);
	Ethernet_setup();

}

boolean executed = false;
boolean received_data = false;
void loop()
{
	int dhcp_state = Ethernet_mantain_connection();
	// if we receive an oder from the serial port
	if (dhcp_state == 1) {// if we have obtained an IP address.. or we wait
		// when we have an IP We execute order (only once)
		if (!executed) {
			if (Ethernet_open_connection ()) {  // Open connection
				getResponse();
			}else{
				//We didnt get a connection, try again?
			}
		}
		// stopEthernet();
		// Send GET information
		// receive answer from the server
		// Close connection
	}else{
		// We are obtaining or renewing a DHCp lease
	}
	// pharse answer from the server and execute orders if nedded
	// send via serial the result of the operation and ok when finished sucessfully, or fail when not.
	
	
}