//////////////////////////////
// COMMUNICATION FUNCTIONS
//////////////////////////////

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
				executed = false;
				
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

void get_configuration () {
	boolean SA = false;		// server_address (host name)
	boolean SS = false;		// server_script (Host Address)
	boolean IP = false;		// printer_IP
	boolean PS = false;		// password
	boolean PP = false;		// printer port
	
	#if defined DEBUG_serial
	mem_check ();			// Check free memory
	Serial.println("Enter configuration "); 
	#endif
	// Test configuration
	/*
	SA: office.pygmalion.nl
	SS: /labelgenerator/generate.php?batch_id=290
	IP: 10.10.249.105
	PS: ***********************
	PP: 8000
	SA || !SS || !IP || !PS || !PP
	*/
	#if defined DEBUG_serial
	SA = true;
	SS = true;
	IP = true;
	PS = true;
	PP = true;
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
			
			// Staring of script
			String SprinterIP = printerIP;
			// convert into -> byte printer_ipAddr[4]
			// ip 10.11.12.13
			int firstDot = SprinterIP.indexOf('.');
			int secondDot = SprinterIP.indexOf('.', firstDot + 1 );
			int thirdDot = SprinterIP.indexOf('.', secondDot + 1 );
			int lastChar = SprinterIP.length();
			//int firstdoubleDot = stringOne.indexOf(':');
			

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
	#if defined DEBUG_serial
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
	#endif
}