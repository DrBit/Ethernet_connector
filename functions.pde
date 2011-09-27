///////////////////////
// FUNCIONS
///////////////////////
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
			Serial.print("Discovering servers.");
			break;
		  case DhcpStateRequesting:
			Serial.print("Requesting lease.");
			break;
		  case DhcpStateRenewing:
			Serial.print("Renewing lease.");
			break;
		  case DhcpStateLeased: {
			Serial.println("Obtained lease!");

			// Since we're here, it means that we now have a DHCP lease, so we
			// print out some information.
			const byte* ipAddr = EthernetDHCP.ipAddress();
			const byte* gatewayAddr = EthernetDHCP.gatewayIpAddress();
			const byte* dnsAddr = EthernetDHCP.dnsIpAddress();

			Serial.print("My IP address is ");
			Serial.println(ip_to_str(ipAddr));

			Serial.print("Gateway IP address is ");
			Serial.println(ip_to_str(gatewayAddr));

			Serial.print("DNS IP address is ");
			Serial.println(ip_to_str(dnsAddr));

			// You will often want to set your own DNS server IP address (that is
			// reachable from your Arduino board) before doing any DNS queries. Per
			// default, the DNS server IP is set to one Obtained from the DHCP server
			// but can be set at Google's public DNS servers.
			// byte dnsServerIp[] = { 8, 8, 8, 8};		// Google's DNS server
			// EthernetDNS.setDNSServer(dnsServerIp);	// Set Google's DNS
			EthernetDNS.setDNSServer(EthernetDHCP.dnsIpAddress());	// Set DHCP's DNS

			Serial.println();
			
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

char hostName[512];
void get_ip_from_dns_name() {
	// We print the message only once. (This wont benecessary in the future
	if (!print_once){
		Serial.println("Enter a host name via the Arduino Serial Monitor to connect to.");
		print_once=true;
	}
	
	int length = 0;
	
	// We get serial data as DNS NAME if we havent get an IP Yet
	
	if (!got_ip) {
		while (Serial.available()) {
			hostName[length] = Serial.read();
			length = (length+1) % 512;
			delay(100);
		}
		hostName[length] = '\0';
	}

	if (length > 0) {
		Serial.print("Resolving ");
		Serial.print(hostName);
		Serial.print(".");

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
					Serial.print(".");
				}
			} while (DNSTryLater == err);
		}

		Serial.println();

		// Finally, we have a result. We're just handling the most common errors
		// here (success, timed out, not found) and just print others as an
		// integer. A full listing of possible errors codes is available in
		// EthernetDNS.h
		if (DNSSuccess == err) {
			Serial.print("The IP address is ");
			Serial.print(ip_to_str(server_ipAddr));
			Serial.println(".");
			//executed = false;					// Flag for eneable conection
			got_ip = true;
		} else if (DNSTimedOut == err) {
			Serial.println("Timed out.");
			got_ip = false;
		} else if (DNSNotFound == err) {
			Serial.println("Does not exist.");
			got_ip = false;
		} else {
			Serial.print("Failed with error code ");
			Serial.print((int)err, DEC);
			Serial.println(".");
			got_ip = false;
		}
	}else{
		
	}
}


// some variables for not bloking at this point
#define number_of_retris 5
unsigned int retris = 0;

boolean Ethernet_open_connection () {
	Serial.println("connecting to the server");
	delay (100);
	if (client.connect()) {
		Serial.println("connected");
		request_data();		// Request data
		return true;
	} else {
		// kf you didn't get a connection to the server:
		Serial.println("connection failed");
		// Double check for too many tries
		retris ++;
		if (retris > number_of_retris) {
			stopEthernet();
			retris = 0;
		}
		return false;
	}
	delay (100);
}

// REQUEST DATA!!!
void request_data () {
	client.println("POST / HTTP/1.0");
	client.print("Host: www.");
	client.println(hostName);
	client.println("From: betamaster50@gmail.com");
	client.println("User-Agent: Arduino (SeedCounter)");
	client.println("Content-Type: application/x-www-form-urlencoded");
	client.println("Content-Length: 32");
	client.println();
	client.println("username=*********&password=********");
	client.println();
	delay (100);
}


void getResponse(){  
	Serial.println("getting response.");
	while (client.available()) {
		char c = client.read();
		Serial.print(c);
		received_data = true;
	}

	// if the server's disconnected, stop the client:
	if (!client.connected()) {
		Serial.println("client disconnected.");
		if (received_data) executed = true;
	}
	
	delay (100);

}

void stopEthernet(){
	Serial.println("Stoping ethernet.");
	client.stop();
	delay (100);
	Serial.println("Ethernet stoped.");
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