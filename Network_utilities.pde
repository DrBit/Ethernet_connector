
prog_uchar enEth1[] PROGMEM  = {"DHCP begin..."};

void Enable_Ethernet () {
	// Initiate a DHCP session. The argument is the MAC (hardware) address that
	// you want your Ethernet shield to use. The second argument enables polling
	// mode, which means that this call will not block like in the
	// SynchronousDHCP example, but will return immediately.
	// Within your loop(), you can then poll the DHCP library for its status,
	// finding out its state, so that you can tell when a lease has been
	// obtained. You can even find out when the library is in the process of
	// renewing your lease.
	EthernetDHCP.begin(mac, 1);
	#if defined DEBUG_serial
	SerialFlashPrintln (enEth1);
	// Serial.println("DHCP begin..."); 
	#endif
}

prog_uchar dhcp1[] PROGMEM  = {"Discovering servers."};
prog_uchar dhcp2[] PROGMEM  = {"Requesting lease."};
prog_uchar dhcp3[] PROGMEM  = {"Renewing lease."};
prog_uchar dhcp4[] PROGMEM  = {"Obtained lease!"};

prog_uchar dhcp5[] PROGMEM  = {"My IP address is "};
prog_uchar dhcp6[] PROGMEM  = {"Gateway IP address is "};
prog_uchar dhcp7[] PROGMEM  = {"DNS IP address is "};
			
int Ethernet_mantain_connection() {
	static DhcpState prevState = DhcpStateNone;
	static unsigned long prevTime = 0;

	// poll() queries the DHCP library for its current state (all possible values
	// are shown in the switch statement below). This way, you can find out if a
	// lease has been obtained or is in the process of being renewed, without
	// blocking your sketch. Therefore, you could display an error message or
	// something if a lease cannot be obtained within reasonable time.
	// Also, poll() will actually run the DHCP module, just like maintain(), so
	// you should call either of these two methods at least once within your
	// loop() section, or you risk losing your DHCP lease when it expires!
	DhcpState state = EthernetDHCP.poll();
	
	if (prevState != state) {
	
	#if defined DEBUG_serial
	Serial.println();
	#endif

		switch (state) {
		  case DhcpStateDiscovering:
			#if defined DEBUG_serial
			SerialFlashPrint (dhcp1);
			// Serial.print("Discovering servers.");
			#endif
			break;
		  case DhcpStateRequesting:
			#if defined DEBUG_serial
			SerialFlashPrint (dhcp2);
			//Serial.print("Requesting lease.");
			#endif
			break;
		  case DhcpStateRenewing:
			#if defined DEBUG_serial
			SerialFlashPrint (dhcp3);
			//Serial.print("Renewing lease.");
			#endif
			break;
		  case DhcpStateLeased: {
			#if defined DEBUG_serial
			SerialFlashPrintln (dhcp4);
			//Serial.println("Obtained lease!");
			
			// Since we're here, it means that we now have a DHCP lease, so we
			// print out some information.
			const byte* ipAddr = EthernetDHCP.ipAddress();
			const byte* gatewayAddr = EthernetDHCP.gatewayIpAddress();
			const byte* dnsAddr = EthernetDHCP.dnsIpAddress();
			
			SerialFlashPrint (dhcp5);
			//Serial.print("My IP address is ");
			Serial.println(ip_to_str(ipAddr));
			
			SerialFlashPrint (dhcp6);
			//Serial.print("Gateway IP address is ");
			Serial.println(ip_to_str(gatewayAddr));

			SerialFlashPrint (dhcp7);
			//Serial.print("DNS IP address is ");
			Serial.println(ip_to_str(dnsAddr));
			Serial.println ("");
			#endif

			// You will often want to set your own DNS server IP address (that is
			// reachable from your Arduino board) before doing any DNS queries. Per
			// default, the DNS server IP is set to one Obtained from the DHCP server
			// but can be set at Google's public DNS servers.
			// byte dnsServerIp[] = { 8, 8, 8, 8};		// Google's DNS server
			// EthernetDNS.setDNSServer(dnsServerIp);	// Set Google's DNS
			EthernetDNS.setDNSServer(EthernetDHCP.dnsIpAddress());	// Set DHCP's DNS

			// Serial.println();
			
			break;
		  }
		}
	} else if (state != DhcpStateLeased && millis() - prevTime > 300) {
	 prevTime = millis();
	 #if defined DEBUG_serial
	 Serial.print('.'); 
	 #endif
	}

	prevState = state;
	
	if (state == DhcpStateLeased) {
		return 1;
	}else{
		return 0;
	}
}



prog_uchar dns1[] PROGMEM  = {"Resolving host: "};
prog_uchar dns2[] PROGMEM  = {"The IP address is "};
prog_uchar dns3[] PROGMEM  = {"Timed out."};
prog_uchar dns4[] PROGMEM  = {"Does not exist."};
prog_uchar dns5[] PROGMEM  = {"Failed with error code "};

void get_ip_from_dns_name(char* pointer_hostName, byte* pointer_IPaddr) {

	#if defined DEBUG_serial
	SerialFlashPrint (dns1);
	//Serial.print("Resolving ");
	Serial.print(pointer_hostName);
	Serial.print(".");
	#endif

	// Let's send our DNS query. If anything other than DNSSuccess is returned,
	// an error has occurred. A full list of possible return values is
	// available in EthernetDNS.h
	DNSError err = EthernetDNS.sendDNSQuery(pointer_hostName);

	if (DNSSuccess == err) {
		do {
			// This will not wait for a reply, but return immediately if no reply
			// is available yet. In this case, the return value is DNSTryLater.
			// We can use this behavior to go on with our sketch while the DNS
			// server and network are busy finishing our request, rather than
			// being blocked and waiting.
			err = EthernetDNS.pollDNSReply(pointer_IPaddr);
			//or
			// err = EthernetDNS.pollDNSReply(pointer_IPaddr);
			// This procedure will fetch the IP adress and put into pointer_IPaddr

			if (DNSTryLater == err) {
				// You could do real stuff here, or go on with a your loop(). I'm
				// just printing some dots to signal that the query is being
				// processed.
				delay(20);
				#if defined DEBUG_serial
				Serial.print(".");
				#endif
			}
		} while (DNSTryLater == err);
	}
	#if defined DEBUG_serial
	Serial.println("");
	#endif
	// Finally, we have a result. We're just handling the most common errors
	// here (success, timed out, not found) and just print others as an
	// integer. A full listing of possible errors codes is available in
	// EthernetDNS.h
	if (DNSSuccess == err) {
		#if defined DEBUG_serial
		SerialFlashPrint (dns2);
		//Serial.print("The IP address is ");
		Serial.print(ip_to_str(pointer_IPaddr));
		Serial.println(".");
		#endif
		got_ip = true;
	} else if (DNSTimedOut == err) {
		#if defined DEBUG_serial
		SerialFlashPrint (dns3);
		//Serial.println("Timed out.");
		#endif
		got_ip = false;
	} else if (DNSNotFound == err) {
		#if defined DEBUG_serial
		SerialFlashPrint (dns4);
		//Serial.println("Does not exist.");
		#endif
		got_ip = false;
	} else {
		#if defined DEBUG_serial
		SerialFlashPrint (dns5);
		//Serial.print("Failed with error code ");
		Serial.print((int)err, DEC);
		Serial.println(".");
		#endif
		got_ip = false;
	}
}




uint8_t *_ip;
uint16_t _port;

void set_server_ip(uint8_t *ip) {
	_ip = ip;
}

void set_server_port(uint16_t port) {
	_port = port;
}


// some variables for not bloking at this point
#define number_of_retris 5
unsigned int retris = 0;

prog_uchar eth1[] PROGMEM  = {"Connecting to the server."};
prog_uchar eth2[] PROGMEM  = {"Connected."};
prog_uchar eth3[] PROGMEM  = {"Connection failed."};

boolean Ethernet_open_connection () {
	#if defined DEBUG_serial
	SerialFlashPrintln (eth1);
	//Serial.println("connecting to the server");
	delay (100);
	#endif
	if (client.connect()) {  //_ip,_port
		#if defined DEBUG_serial
		SerialFlashPrintln (eth2);
		//Serial.println("connected");
		#endif
		return true;
	} else {
		// kf you didn't get a connection to the server:
		#if defined DEBUG_serial
		SerialFlashPrintln (eth3);
		//Serial.println("connection failed");
		#endif
		// Double check for too many tries
		retris ++;
		if (retris > number_of_retris) {
			stopEthernet();
			retris = 0;
			send_command (00);			// Indicates function was not completed 
			send_error (00);			// Indicates the error type generateds
			resetState ();				// Resets all variables in order to get to the beginin of the code.
		}
		delay (2000);
		return false;
	}
}

void resetState () {
	connected = false;
	//executed =  false;
	got_ip= false;
	// print_state = ready;
}


prog_uchar response1[] PROGMEM  = {"waiting for response."};
prog_uchar response2[] PROGMEM  = {"\nTime Out!"};
prog_uchar response3[] PROGMEM  = {"\nserver closed session."};
prog_uchar response4[] PROGMEM  = {"Latest data received: "};


void getResponse(){  
	#if defined DEBUG_serial
	SerialFlashPrint (response1);
	//Serial.print("waiting for response.");
	#endif
	unsigned int timeoutCounter = 0;
	while (!client.available()) {
		// Wait for the client to be available
		#if defined DEBUG_serial
		Serial.print(".");
		#endif
		delay (200);
		timeoutCounter ++;
		if (timeoutCounter > (15000/200)) {		// If greater than 15 seconds
			#if defined DEBUG_serial
			SerialFlashPrintln (response2);
			//Serial.print("\nTime Out!");
			#endif
			send_command (00);			// Indicates function was not completed 
			send_error (01);			// Indicates the error type generateds
			resetState ();				// Resets all variables in order to get to the beginin of the code.
			break;
		}
	}
	#if defined DEBUG_serial
	Serial.println(".");
	#endif
	while (client.available()) {
		XML_pharser();
	}

	
	// if the server's disconnected, stop the client:
	if (!client.connected()) {
		#if defined DEBUG_serial
		SerialFlashPrintln (response3);
		//Serial.println("\nserver closed session.");
		if (received_data) {
			SerialFlashPrintln (response4);
			//Serial.print("received data: ");
			Serial.println(dataRec);
		}
		#endif
		got_response = true;
	}
		
	if (!received_data) {			// We didnt got any data so won't go forth.. send error
		send_command (00);			// Indicates function was not completed 
		send_error (02);			// Indicates the error type generateds
		resetState ();				// Resets all variables in order to get to the beginin of the code.
	}
}

prog_uchar stopEthernet1[] PROGMEM  = {"Stoping ethernet."};
prog_uchar stopEthernet2[] PROGMEM  = {"Ethernet stoped."};

void stopEthernet(){
	#if defined DEBUG_serial
	SerialFlashPrintln (stopEthernet1);
	//Serial.println("Stoping ethernet.");
	#endif
	
	client.stop();
	// executed = false;
	got_ip=false;
	// print_once = false;
	connected = false;
	
	#if defined DEBUG_serial
	SerialFlashPrintln (stopEthernet2);
	//Serial.println("Ethernet stoped.");
	#endif
}


// Just a utility function to nicely format an IP address.
const char* ip_to_str(const uint8_t* ipAddr)
{
	static char buf[16];
	sprintf(buf, "%d.%d.%d.%d\0", ipAddr[0], ipAddr[1], ipAddr[2], ipAddr[3]);
	return buf;
}

prog_uchar freemem1[] PROGMEM  = {"Memory available: ["};
prog_uchar freemem2[] PROGMEM  = {" bytes]"};

/***** Checks free ram and prints it serial *****/
void mem_check () {
	//checking memory:
	SerialFlashPrint (freemem1);
	// Serial.print("Memory available: [");
	Serial.print(freeRam());
	SerialFlashPrintln (freemem2);
	// Serial.println(" bytes]");
}

/***** Returns free ram *****/
int freeRam () {
	extern int __heap_start, *__brkval; 
	int v; 
	return (int) &v - (__brkval == 0 ? (int) &__heap_start : (int) __brkval); 
}




////////////////////////////////////////////////////////////////////
// UI SERVER
////////////////////////////////////////////////////////////////////

// How do we recognize the server?
// As the Arduino Mega is the one in contact with the user
// he will provide us with the server name (in case it changed)
// this DNS name is recorded in the Eeprom so we don't have to take it every time.
// only if it changes

/*
get DNS name from arduino
example: http://robot.eric.nr1net.corp
check if is the same we had in the eeprom and update if necessary
Check dns name
get IP from it
done!
*/
		
prog_uchar fetchconfig1[] PROGMEM  = {"Set IP \nSet port 80"};

// once the Ethernet is configured we can retrieve all configuration from the server
boolean fetch_configuration () {
	byte retries1 = 0;
	boolean done_it = false;
	while (retries1 < 10) {
		#if defined NO_DNS
		got_ip = true;
		#endif
		if (got_ip) {
			if (!done_it) {
				#if defined DEBUG_serial
				SerialFlashPrintln (fetchconfig1);	// Serial.println("IP of UI server retrieved!");	
				#endif
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
				char update_script [] ="/arduino/get/id/1/data/table=configuration;getallfields";
				get_HTTP (update_script, config.ui_server);
				getResponse();							// Pharse all data received and update if necessary
				if (got_response) {
					stopEthernet();
					got_response = false;				// reset falg
					received_data = false;				// Reset flag so its secure now that we already process every thing
					#if defined DEBUG_serial
					mem_check ();
					#endif
					return true;
				}else{
					// if we havent got response, either the server is down or the response was not valid
					return false;
				}
			}
		}else{
			// try to conect to the previous dns name recorded in Eeprom and retrieve IP
			get_ip_from_dns_name(config.ui_server,server_ipAddr);
		}
		retries1++;
	}
	return false;
}

void get_HTTP (char* address,char* host) {

	client.print("GET ");
	client.print(address);
	client.println(" HTTP/1.0");
	
	client.print("Host: ");
	client.println(host);
	
	client.print("User-Agent: Arduino SeedCounter Client ");
	client.println(_version);
	
	client.println();
	delay (100);
} 

void get_HTTP (char* address,char* host, unsigned int port) {

	client.print("GET ");
	client.print(address);
	client.println(" HTTP/1.0");
	
	client.print("Host: ");
	client.println(host);
	client.print(":");
	client.println(port);
	
	client.print("User-Agent: Arduino SeedCounter Client ");
	client.println(_version);
	
	client.println();
	delay (100);
}

void generate_label () {

	client.print("GET ");
	client.print(config.server_script);
	client.print(seeds_batch);
	client.println(" HTTP/1.0");
	
	client.print("Authorization: Basic ");
	client.println(config.password);    //user:password -> encoded in base64 -> http://maxcalci.com/base64.html
	
	client.print("Host: ");
	client.println(config.server_address);
	
	client.print("User-Agent: Arduino SeedCounter Client ");
	client.println(_version);
	
	client.println();
	delay (100);
}

void POST_data_UI_server (char* address,char* host, unsigned int data) {

	client.print("GET ");
	client.print(address);
	client.print(data);
	client.println(" HTTP/1.0");
	
	client.print("Host: ");
	client.println(host);
	
	client.print("User-Agent: Arduino SeedCounter Client ");
	client.println(_version);
	
	client.println();
	delay (100);
}

void send_data_UI_server (int data_type, int data) {
	
	// Data Types
	//#define data_error 1
	//#define data_action 2
	
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
				// Send POST with DATA INFORMATION 
				if (data_type == data_action) {
					char update_script[]="/arduino/get/id/1/data/action=";
					POST_data_UI_server (update_script,config.ui_server, data);
				}else if (data_type == data_error) {
					char update_script[]="/arduino/get/id/1/data/error=";
					POST_data_UI_server (update_script,config.ui_server, data);
				}
				
				
				// needed?????
				/*
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
				}*/
			}
		}else{		// try to conect to the previous dns name recorded in Eeprom and retrieve IP
			get_ip_from_dns_name(config.ui_server,server_ipAddr);
		}
		retries1++;
	}
}
