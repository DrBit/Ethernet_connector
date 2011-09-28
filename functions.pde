///////////////////////
// FUNCIONS
///////////////////////

#define DEBUG_serial

// #if defined DEBUG
// Serial.println(val);
// #endif

const int buffer = 70;
char hostName[buffer];
char hostAddress[buffer];
char password[buffer];



boolean print_state = 0;
#define ready 0
#define printing 1

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
	Serial.println("DHCP begin..."); 
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
	Serial.println();
	
		switch (state) {
		  case DhcpStateDiscovering:
			#if defined DEBUG_serial
			Serial.print("Discovering servers.");
			#endif
			break;
		  case DhcpStateRequesting:
			#if defined DEBUG_serial
			Serial.print("Requesting lease.");
			#endif
			break;
		  case DhcpStateRenewing:
			#if defined DEBUG_serial
			Serial.print("Renewing lease.");
			#endif
			break;
		  case DhcpStateLeased: {
			#if defined DEBUG_serial
			Serial.println("Obtained lease!");
			#endif
			// Since we're here, it means that we now have a DHCP lease, so we
			// print out some information.
			const byte* ipAddr = EthernetDHCP.ipAddress();
			const byte* gatewayAddr = EthernetDHCP.gatewayIpAddress();
			const byte* dnsAddr = EthernetDHCP.dnsIpAddress();
			
			#if defined DEBUG_serial
			Serial.print("My IP address is ");
			#endif
			Serial.println(ip_to_str(ipAddr));
			
			#if defined DEBUG_serial
			Serial.print("Gateway IP address is ");
			Serial.println(ip_to_str(gatewayAddr));

			Serial.print("DNS IP address is ");
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
	 Serial.print('.'); 
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
	Serial.print("Resolving ");
	Serial.print(hostName);
	Serial.print(".");
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
				Serial.print(".");
				#endif
			}
		} while (DNSTryLater == err);
	}

	Serial.println();

	// Finally, we have a result. We're just handling the most common errors
	// here (success, timed out, not found) and just print others as an
	// integer. A full listing of possible errors codes is available in
	// EthernetDNS.h
	if (DNSSuccess == err) {
		#if defined DEBUG_serial
		Serial.print("The IP address is ");
		Serial.print(ip_to_str(server_ipAddr));
		Serial.println(".");
		#endif
		got_ip = true;
	} else if (DNSTimedOut == err) {
		#if defined DEBUG_serial
		Serial.println("Timed out.");
		#endif
		got_ip = false;
	} else if (DNSNotFound == err) {
		#if defined DEBUG_serial
		Serial.println("Does not exist.");
		#endif
		got_ip = false;
	} else {
		#if defined DEBUG_serial
		Serial.print("Failed with error code ");
		Serial.print((int)err, DEC);
		Serial.println(".");
		#endif
		got_ip = false;
	}
}


// some variables for not bloking at this point
#define number_of_retris 5
unsigned int retris = 0;

boolean Ethernet_open_connection () {
	#if defined DEBUG_serial
	Serial.println("connecting to the server");
	delay (100);
	#endif
	if (client.connect()) {
		#if defined DEBUG_serial
		Serial.println("connected");
		#endif
		return true;
	} else {
		// kf you didn't get a connection to the server:
		#if defined DEBUG_serial
		Serial.println("connection failed");
		#endif
		// Double check for too many tries
		retris ++;
		if (retris > number_of_retris) {
			stopEthernet();
			retris = 0;
		}
		return false;
	}
}


void generate_label () {

	client.print("GET ");
	client.print(hostAddress);
	client.println(" HTTP/1.0");
	
	client.print("Authorization: Basic ");
	client.println(password);    //user:password -> encoded in base64 -> http://maxcalci.com/base64.html
	
	client.print("Host: www.");
	client.println(hostName);
	
	client.print("User-Agent: Arduino SeedCounter Client");
	client.print(_version);
	
	client.println();
	delay (100);
}


void getResponse(){  
	#if defined DEBUG_serial
	Serial.println("getting response.");
	#endif
	while (client.available()) {
		char c = client.read();
		Serial.print(c);
		received_data = true;
		// HERE TAG RECOGNITION CODE
	}

	// if the server's disconnected, stop the client:
	if (!client.connected()) {
		#if defined DEBUG_serial
		Serial.println("client disconnected.");
		#endif
	}
}

void print_label () {
	client.print("GET ");
	//client.print(answer from website);
	client.println(" HTTP/1.0");

	//client.println("From: betamaster50@gmail.com");
	//client.println("User-Agent: Arduino (SeedCounter)");
	//client.println("Content-Type: application/x-www-form-urlencoded");
	//client.println("username=*********&password=********");
	//client.println();
	//delay (100);
	
	// if the server's disconnected, stop the client:
	if (!client.connected()) {
		#if defined DEBUG_serial
		Serial.println("client disconnected.");
		#endif
		if (received_data) executed = true;
		//request_print_label ();
	}
	
	delay (5000);
	// ready to rpint again
	print_state = ready;
}

void stopEthernet(){
	#if defined DEBUG_serial
	Serial.println("Stoping ethernet.");
	#endif
	client.stop();
	#if defined DEBUG_serial
	Serial.println("Ethernet stoped.");
	#endif
	executed = false;
	got_ip=false;
	print_once = false;
	connected = false;
}

// Just a utility function to nicely format an IP address.
const char* ip_to_str(const uint8_t* ipAddr)
{
	static char buf[16];
	sprintf(buf, "%d.%d.%d.%d\0", ipAddr[0], ipAddr[1], ipAddr[2], ipAddr[3]);
	return buf;
}


//////////////////////////////
// INIT FUNCTIONS
//////////////////////////////

int buffer_command = 3;

void wait_for_host () {
	#if defined DEBUG_serial
	Serial.println("Waiting for host (IN command)");
	#endif
	char command[buffer_command];
	int length = 0;
	while (!Serial.available()) {}
	while (Serial.available()) {
		command[length] = Serial.read();
		length = (length+1) % buffer_command;
		delay(100);
	}
	command[length] = '\0';
	if (strcmp(command, "IN")  == 0) {
		#if defined DEBUG_serial
		Serial.print("Received: "); 
		Serial.println(command);
		#endif
		
	}else{
		#if defined DEBUG_serial
		Serial.println("NOT IN command");
		Serial.println(command);
		#endif
	}
}





void get_configuration () {
	boolean SA = false;		// server_address (host name)
	boolean SS = false;		// server_script (Host Address)
	boolean IP = false;		// printer_IP
	boolean PS = false;		// password
	boolean PP = false;		// printer port
	#if defined DEBUG_serial
	Serial.println("Enter configuration "); 
	#endif
	// Check if we finished configuring
	while (!SA || !SS || !IP || !PS || !PP)  {
		#if defined DEBUG_serial
		Serial.println("Ready to receive Command "); 
		#endif
		// receive command
		int length = 0;
		char command[buffer_command];
		while (!Serial.available()) {}
		while (Serial.available()) {
			command[length] = Serial.read();
			length = (length+1) % buffer_command;
			delay(100);
		}
		command[length] = '\0';
		
		// Check command!
		if (strcmp(command, "SA")  == 0) {		// server_address
			#if defined DEBUG_serial
			Serial.print("Received: "); 
			Serial.println(command);
			Serial.println("Ready to receive DATA "); 
			#endif
			length = 0;
			while (!Serial.available()) {}
			while (Serial.available()) {
				hostName[length] = Serial.read();
				length = (length+1) % buffer;
				delay(100);
			}
			hostName[length] = '\0';
			SA = true;
		}
		
		// Check command!
		if (strcmp(command, "SS")  == 0) {		// server_script (Host Address)
			#if defined DEBUG_serial
			Serial.print("Received: "); 
			Serial.println(command);
			Serial.println("Ready to receive DATA ");
			#endif
			length = 0;
			while (!Serial.available()) {}
			while (Serial.available()) {
				hostAddress[length] = Serial.read();
				length = (length+1) % buffer;
				delay(100);
			}
			hostAddress[length] = '\0';
			SS = true;
		}
		
		// Check command!
		if (strcmp(command, "IP")  == 0) {		// server_script (Host Address)
			char printerIP[buffer];
			#if defined DEBUG_serial
			Serial.print("Received: "); 
			Serial.println(command);
			Serial.println("Ready to receive DATA ");
			#endif
			length = 0;
			while (!Serial.available()) {}
			while (Serial.available()) {
				printerIP[length] = Serial.read();
				length = (length+1) % buffer;
				delay(100);
			}
			printerIP[length] = '\0';
			String SprinterIP = printerIP;
			// convert into -> byte printer_ipAddr[4]
			// ip 10.11.12.13
			int firstDot = SprinterIP.indexOf('.');
			int secondDot = SprinterIP.indexOf('.', firstDot + 1 );
			int thirdDot = SprinterIP.indexOf('.', secondDot + 1 );
			int lastChar = SprinterIP.length();
			//int firstdoubleDot = stringOne.indexOf(':');
			Serial.println (firstDot);
			Serial.println (secondDot);
			Serial.println (thirdDot);
			Serial.println (lastChar);
			Serial.println ("-----");
			

			int num = 0;	
			// when you cast the individual chars to ints you will get their ascii table equivalents 
			// Since the ascii values of the digits 1-9 are off by 48 (0 is 48, 9 is 57), 
			// you can correct by subtracting 48 when you cast your chars to ints.
			for (int i = (firstDot-1); i>=0 ; i--) {
				num = atoi(&printerIP[i]);
			}
			Serial.println (num);
			printer_ipAddr[0] = (byte) num;
			
			num = 0;
			for (int i = (secondDot-1); i>=(firstDot+1) ; i--) {
				num = atoi(&printerIP[i]);
			}
			Serial.println (num);
			printer_ipAddr[1] = (byte) num;
			
			num = 0;
			for (int i = (thirdDot-1); i>=(secondDot+1) ; i--) {
				num = atoi(&printerIP[i]);
			}
			Serial.println (num);
			printer_ipAddr[2] = (byte) num;
			
			num = 0;
			for (int i = (lastChar-1); i>=(thirdDot+1) ; i--) {
				num = atoi(&printerIP[i]);
			}
			Serial.println (num);
			printer_ipAddr[3] = (byte) num;
			
			
			Serial.print ("IP: ");
			Serial.println (ip_to_str(printer_ipAddr));
			
			IP = true;
		}
		
		// Check command!
		if (strcmp(command, "PS")  == 0) {		// server_script (Host Address)
			#if defined DEBUG_serial
			Serial.print("Received: "); 
			Serial.println(command);
			Serial.println("Ready to receive DATA ");
			#endif
			length = 0;
			while (!Serial.available()) {}
			while (Serial.available()) {
				password[length] = Serial.read();
				length = (length+1) % buffer;
				delay(100);
			}
			password[length] = '\0';
			PS = true;
		}
		
		// Check command!
		if (strcmp(command, "PP")  == 0) {		// server_script (Host Address)
			char printerPort[buffer];
			#if defined DEBUG_serial
			Serial.print("Received: "); 
			Serial.println(command);
			Serial.println("Ready to receive DATA ");
			#endif
			length = 0;
			while (!Serial.available()) {}
			while (Serial.available()) {
				printerPort[length] = Serial.read();
				length = (length+1) % buffer;
				delay(100);
			}
			printerPort[length] = '\0';
			
			char * thisChar = printerPort;
			printer_port = atoi(thisChar);
			 
			PP = true;
		}
	}
	
	Serial.print ("SA: ");
	Serial.println (hostName);
	Serial.print ("SS: ");
	Serial.println (hostAddress);
	Serial.print ("IP: ");
	Serial.println (ip_to_str(printer_ipAddr));
	Serial.print ("PS: ");
	Serial.println (password);
	Serial.print ("PP: ");
	Serial.println (printer_port);
	delay (300);
}



void wait_for_print_command () {
	if (print_state == ready) {
		Serial.println("1"); 			// send arduino a confirmation , we are ready to print
		delay (300);
		
		#if defined DEBUG_serial
		Serial.println("Network ready!"); 
		Serial.println("Waiting for print command (PR)");
		#endif
		
		boolean command_received= false;
		while (!command_received) {
			char command[buffer_command];
			int length = 0;
			while (!Serial.available()) {}
			while (Serial.available()) {
				command[length] = Serial.read();
				length = (length+1) % buffer_command;
				delay(100);
			}
			command[length] = '\0';
			if (strcmp(command, "PR")  == 0) {
				#if defined DEBUG_serial
				Serial.print("Received: "); 
				Serial.println(command);
				#endif
				command_received = true;
				print_state = printing;
				
			}else{
				#if defined DEBUG_serial
				Serial.println("NOT PR command");
				Serial.println(command);
				#endif
			}
		}
		
		#if defined DEBUG_serial
		Serial.println("Ready to connect!"); 
		#endif
	}else{
		// we are in the preocess of printing
		// check if ready
	}
}


void convertIPtoInt () {
/*
	printerIP[length] = '\0';
	String SprinterIP = printerIP;
	// convert into -> byte printer_ipAddr[4]
	// ip 10.11.12.13
	int firstDot = SprinterIP.indexOf('.');
	int secondDot = SprinterIP.indexOf('.', firstDot + 1 );
	int thirdDot = SprinterIP.indexOf('.', secondDot + 1 );
	int lastChar = SprinterIP.length();
	//int firstdoubleDot = stringOne.indexOf(':');
	Serial.println (firstDot);
	Serial.println (secondDot);
	Serial.println (thirdDot);
	Serial.println (lastChar);
	Serial.println ("-----");


	int num = 0;	
	// when you cast the individual chars to ints you will get their ascii table equivalents 
	// Since the ascii values of the digits 1-9 are off by 48 (0 is 48, 9 is 57), 
	// you can correct by subtracting 48 when you cast your chars to ints.
	for (int i = (firstDot-1); i>=0 ; i--) {
		num = atoi(&printerIP[i]);
	}
	Serial.println (num);
	printer_ipAddr[0] = (byte) num;

	num = 0;
	for (int i = (secondDot-1); i>=(firstDot+1) ; i--) {
		num = atoi(&printerIP[i]);
	}
	Serial.println (num);
	printer_ipAddr[1] = (byte) num;

	num = 0;
	for (int i = (thirdDot-1); i>=(secondDot+1) ; i--) {
		num = atoi(&printerIP[i]);
	}
	Serial.println (num);
	printer_ipAddr[2] = (byte) num;

	num = 0;
	for (int i = (lastChar-1); i>=(thirdDot+1) ; i--) {
		num = atoi(&printerIP[i]);
	}
	Serial.println (num);
	printer_ipAddr[3] = (byte) num;


	Serial.print ("IP: ");
	Serial.println (ip_to_str(printer_ipAddr));
*/
}

	