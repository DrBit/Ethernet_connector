

void Ethernet_setup () {
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
	Serial.println(F("DHCP begin...")); 
	#endif
}

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
	Serial.println(F(" "));
	#endif
	
		switch (state) {
		  case DhcpStateDiscovering:
			#if defined DEBUG_serial
			Serial.print(F("Discovering servers."));
			#endif
			break;
		  case DhcpStateRequesting:
			#if defined DEBUG_serial
			Serial.print(F("Requesting lease."));
			#endif
			break;
		  case DhcpStateRenewing:
			#if defined DEBUG_serial
			Serial.print(F("Renewing lease."));
			#endif
			break;
		  case DhcpStateLeased: {
			#if defined DEBUG_serial
			Serial.println(F("Obtained lease!"));
			
			// Since we're here, it means that we now have a DHCP lease, so we
			// print out some information.
			const byte* ipAddr = EthernetDHCP.ipAddress();
			const byte* gatewayAddr = EthernetDHCP.gatewayIpAddress();
			const byte* dnsAddr = EthernetDHCP.dnsIpAddress();
			
			
			Serial.print(F("My IP address is "));
			Serial.println(ip_to_str(ipAddr));
			
			Serial.print(F("Gateway IP address is "));
			Serial.println(ip_to_str(gatewayAddr));

			Serial.print(F("DNS IP address is "));
			Serial.println(ip_to_str(dnsAddr));
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
	 Serial.print (F(".")); 
	 #endif
	}

	prevState = state;
	
	if (state == DhcpStateLeased) {
		return 1;
	}else{
		return 0;
	}
}


void get_ip_from_dns_name() {

	#if defined DEBUG_serial
	Serial.print(F("Resolving "));
	Serial.print(hostName);
	Serial.print(F("."));
	#endif

	// Let's send our DNS query. If anything other than DNSSuccess is returned,
	// an error has occurred. A full list of possible return values is
	// available in EthernetDNS.h
	DNSError err = EthernetDNS.sendDNSQuery(hostName);

	if (DNSSuccess == err) {
		do {
			// This will not wait for a reply, but return immediately if no reply
			// is available yet. In this case, the return value is DNSTryLater.
			// We can use this behavior to go on with our sketch while the DNS
			// server and network are busy finishing our request, rather than
			// being blocked and waiting.
			err = EthernetDNS.pollDNSReply(server_ipAddr);
			// This procedure will fetch the IP adress and put into server_ipAddr

			if (DNSTryLater == err) {
				// You could do real stuff here, or go on with a your loop(). I'm
				// just printing some dots to signal that the query is being
				// processed.
				delay(20);
				#if defined DEBUG_serial
				Serial.print(F("."));
				#endif
			}
		} while (DNSTryLater == err);
	}
	#if defined DEBUG_serial
	Serial.println(F(" "));
	#endif
	// Finally, we have a result. We're just handling the most common errors
	// here (success, timed out, not found) and just print others as an
	// integer. A full listing of possible errors codes is available in
	// EthernetDNS.h
	if (DNSSuccess == err) {
		#if defined DEBUG_serial
		Serial.print(F("The IP address is "));
		Serial.print(ip_to_str(server_ipAddr));
		Serial.println(F("."));
		#endif
		got_ip = true;
	} else if (DNSTimedOut == err) {
		#if defined DEBUG_serial
		Serial.println(F("Timed out."));
		#endif
		got_ip = false;
	} else if (DNSNotFound == err) {
		#if defined DEBUG_serial
		Serial.println(F("Does not exist."));
		#endif
		got_ip = false;
	} else {
		#if defined DEBUG_serial
		Serial.print(F("Failed with error code "));
		Serial.print((int)err, DEC);
		Serial.println(F("."));
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

boolean Ethernet_open_connection () {
	#if defined DEBUG_serial
	Serial.println(F("connecting to the server"));
	delay (100);
	#endif
	if (client.connect(_ip,_port)) {
		#if defined DEBUG_serial
		Serial.println(F("connected"));
		#endif
		return true;
	} else {
		// kf you didn't get a connection to the server:
		#if defined DEBUG_serial
		Serial.println(F("connection failed"));
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
	executed =  false;
	connection_case = generateLabel;
	got_ip= false;
	print_state = ready;
}


void generate_label () {

	client.print("GET ");
	client.print(hostAddress);
	client.print(seeds_batch);
	client.println(" HTTP/1.0");
	
	client.print("Authorization: Basic ");
	client.println(password);    //user:password -> encoded in base64 -> http://maxcalci.com/base64.html
	
	client.print("Host: ");
	client.println(hostName);
	
	client.print("User-Agent: Arduino SeedCounter Client ");
	client.println(_version);
	
	client.println();
	delay (100);
}


void getResponse(){  
	#if defined DEBUG_serial
	Serial.print(F("waiting for response."));
	#endif
	unsigned int timeoutCounter = 0;
	while (!client.available()) {
		// Wait for the client to be available
		#if defined DEBUG_serial
		Serial.print(F("."));
		#endif
		delay (200);
		timeoutCounter ++;
		if (timeoutCounter > (15000/200)) {		// If greater than 15 seconds
			#if defined DEBUG_serial
			Serial.print(F("\nTime Out!"));
			#endif
			send_command (00);			// Indicates function was not completed 
			send_error (01);			// Indicates the error type generateds
			resetState ();				// Resets all variables in order to get to the beginin of the code.
			break;
		}
	}
	#if defined DEBUG_serial
	Serial.println(F("."));
	#endif
	while (client.available()) {
		XML_pharser();
	}

	
	// if the server's disconnected, stop the client:
	if (!client.connected()) {
		#if defined DEBUG_serial
		Serial.println(F("\nserver closed session."));
		if (received_data) {
			Serial.print(F("received data: "));
			Serial.println(labelParameter);
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

void print_label () {
	
	client.print(F("GET /"));
	client.print(labelParameter);
	client.println(F(" HTTP/1.0"));

	client.print(F("Host: "));
	client.print(ip_to_str(printer_ipAddr));
	client.print(F(":"));
	client.println(printer_port);
	
	client.print(F("User-Agent: Arduino SeedCounter Client "));
	client.println(_version);
	
	client.println(F(" "));
	
	delay (100);
	
	#if defined DEBUG_serial
	Serial.println(F("\nPrinter request sended!!"));
	#endif
}

void stopEthernet(){
	#if defined DEBUG_serial
	Serial.println(F("Stoping ethernet."));
	#endif
	
	client.stop();
	// executed = false;
	got_ip=false;
	print_once = false;
	connected = false;
	
	#if defined DEBUG_serial
	Serial.println(F("Ethernet stoped."));
	#endif
}


// Just a utility function to nicely format an IP address.
const char* ip_to_str(const uint8_t* ipAddr)
{
	static char buf[16];
	sprintf(buf, "%d.%d.%d.%d\0", ipAddr[0], ipAddr[1], ipAddr[2], ipAddr[3]);
	return buf;
}


/***** Checks free ram and prints it serial *****/
void mem_check () {
	//checking memory:
	Serial.print(F("Memory available: ["));
	Serial.print(freeRam());
	Serial.println(F(" bytes]"));
}

/***** Returns free ram *****/
int freeRam () {
	extern int __heap_start, *__brkval; 
	int v; 
	return (int) &v - (__brkval == 0 ? (int) &__heap_start : (int) __brkval); 
}