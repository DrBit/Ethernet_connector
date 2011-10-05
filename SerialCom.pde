//////////////////////////////
// COMMUNICATION FUNCTIONS
//////////////////////////////
	
#define endOfLine '*'
	
//////////////////////////
// Receive
//////////////////////////
#define number_of_commands 20
#define number_of_errors 10
char numberIndex = 0;
#define command_digits 2
char commandNumber[command_digits];
boolean lookForLetter = false;
boolean lookForNumber = false;
boolean incomingCommand = false;
boolean incomingError = false;
int commandNumberInt = 0;
int errorNumberInt = 0;

int receiveNextValidCommand () {

	while (true) {
		while (Serial.available()) {
			char c = Serial.read();
			//Serial.print (c);	// JUST for debug
			
			if (c == endOfLine) { 		// begining or end of command
				//Serial.print ("-End of line detected-");
				// In this case we check if we had previous data in the buffer and process it if necessary
				// restart all and ready to receive a commmand
				if (lookForNumber) {
					lookForNumber = false;
					if (processCommand()) {	// we got a valid command!
						//Serial.print ("-Process command-");						
						if (incomingCommand) {
							reset_command ();
							return commandNumberInt;
						}
					}else{
						// failed to process comand
					}
				}
				lookForLetter = true;
				numberIndex = 0;
			}
			
			if (lookForLetter && (c == 'C')) {
				//Serial.print ("-C detected-");
				// we got an incoming comand, start receive command number
				lookForNumber = true;
				incomingCommand = true;
				lookForLetter = false;
			}else if (lookForNumber) {
				//Serial.print ("-Number-");
				// We look for the command number
				commandNumber[numberIndex] = c;
				if (numberIndex == command_digits) { 
					reset_command ();	// Command invalid too many characters
				}
				numberIndex++;
			}
			//delay (100);		// just give enough time to receive another character if 
		}
	}
}

int receiveNextValidError () {
	while (true) {
		while (Serial.available()) {
			//char c = Serial.read();
			Serial.print (c);	// JUST for debug
			
			if (c == endOfLine) { 		// begining or end of command
				//Serial.print ("-End of line detected-");
				// In this case we check if we had previous data in the buffer and process it if necessary
				// restart all and ready to receive a commmand
				if (lookForNumber) {
					lookForNumber = false;
					if (processCommand()) {	// we got a valid command!
						//Serial.print ("-Process command-");						
						if (incomingError) {
							reset_command ();
							return errorNumberInt;
						}
					}else{
						// failed to process comand
					}
				}
				lookForLetter = true;
				numberIndex = 0;
			}
			
			if (lookForLetter && (c == 'E')) {
				//Serial.print ("-E detected-");
				// we got an incoming error, start receive error number
				lookForNumber = true;
				incomingError = true;
				lookForLetter = false;
			}else if (lookForNumber) {
				//Serial.print ("-Number-");
				// We look for the command number
				commandNumber[numberIndex] = c;
				if (numberIndex == command_digits) { 
					reset_command ();	// Command invalid too many characters
				}
				numberIndex++;
			}
			//delay (100);		// just give enough time to receive another character if 
		}
	}
}

boolean processCommand () {
	//Serial.print ("-P-");
	if (incomingCommand) {
		// convert commandNumber
		// Serial.print ("-Incoming-");
		for (int i = (command_digits -1) ; i >= 0; i--) {
			commandNumberInt = atoi(&commandNumber[i]);		// Transform received string into integuer
			// Serial.println ("");
			// Serial.println (commandNumberInt);
		}
		// is valid?
		if ((commandNumberInt >= 0) && (commandNumberInt <= number_of_commands)) { 
			//Serial.print ("VALID");
			return true;
		}else {		
			//Serial.print ("NVALID");
			return false;
		}
	} else if (incomingError) {
	    for (int i = (command_digits-1) ; i >= 0; i--) {
			errorNumberInt = atoi(&commandNumber[i]);		// Transform received string into integuer
		}
		// is valid?
		if ((errorNumberInt >= 0) && (errorNumberInt <= number_of_errors)) { 
			return true;
		}else {		
			return false;
		}
	} else {
		// command not valid
		//Serial.println ("-not expectig command-");
		return false;
	}
}



void reset_command () {				// whenever data validation fails we reset all
	numberIndex = 0;
	lookForNumber = false;
	incomingCommand = false;
	incomingError = false;
	lookForLetter = false;
}


//Record data
void record_data (char input, char* strgdata_Result ) {
  if (strlen(strgdata_Result)== max_data_leng ) {
    //Serial.println (" Reached the data max lengh, we reset the tag" );
    reset_data();
  }else{
    strgdata_Result[strlen(strgdata_Result)]=input;
  }
}

boolean recevie_data (char* parameter_container,int* buffer) {
	// first clean data
	int len = strlen(parameter_container);
	for (int c = 0; c < len; c++) {
		parameter_container[c] = 0;
	}

	while (true) {
		while (Serial.available()) {
			char c = Serial.read();
			//Serial.print (c);	// JUST for debug
			
			if (c == endOfLine) { 		// begining or end of command
				//Serial.print ("-End of line detected-");
				// In this case we check if we had previous data in the buffer and process it if necessary
				// restart all and ready to receive a commmand
				if (lookForNumber) {
					lookForNumber = false;
					if (processCommand()) {	// we got a valid command!
						//Serial.print ("-Process command-");						
						if (incomingCommand) {
							reset_command ();
							if (commandNumberInt == 14) {
								parameter_container[strlen(parameter_container)] = '\0';
								return true;
								// End of data stream
							}else{
								return false;
							}
						}
					}else{
						// failed to process comand
					}
				}
				lookForLetter = true;
				numberIndex = 0;
			}else{
				// DATA comes here
				if (strlen(parameter_container)== buffer ) {
					// Serial.println (" Reached the data max lengh, we reset the tag" );
					// Error!! buffer overload
					return fasle;
				}else{
					parameter_container[strlen(parameter_container)]=c;
				}
			}
			
			if (lookForLetter && (c == 'C')) {
				//Serial.print ("-C detected-");
				// we got an incoming comand, start receive command number
				lookForNumber = true;
				incomingCommand = true;
				lookForLetter = false;
			}else if (lookForNumber) {
				//Serial.print ("-Number-");
				// We look for the command number
				commandNumber[numberIndex] = c;
				if (numberIndex == command_digits) { 
					reset_command ();	// Command invalid too many characters
				}
				numberIndex++;
			}
			//delay (100);		// just give enough time to receive another character if 
		}
	}
}

//////////////////////////
// Send
//////////////////////////



bool send_command (unsigned int command) {
	//delay (300);
	Serial.print(endOfLine);	// Print begining command
	Serial.print("C");
	// We need to send in form of two digits like (01)
	if (command < 10) {
		Serial.print('0');
	}
	Serial.print(command);
	Serial.print(endOfLine);	// Print end command
	//delay(300);
}

bool send_error (unsigned int command) {
	//delay (300);
	Serial.print(endOfLine);	// Print begining command
	Serial.print("E");
	// We need to send in form of two digits like (01)
	if (command < 10) {
		Serial.print('0');
	}
	Serial.print(command);
	Serial.print(endOfLine);	// Print end command
	//delay(300);
}


void send_data () {


}

//////////////////////////
// Common functions
//////////////////////////

void wait_for_print_command () {
	if (print_state == ready) {
		
		#if defined DEBUG_serial
		Serial.println("Network ready!"); 
		Serial.println("Waiting for print label command (C04)");
		#endif
		
		boolean command_received = false;
		while (!command_received) {
			int last_command_received = receiveNextValidCommand();
			if (last_command_received == 04) {				// Petition of configuration all correct.
				send_command (01);
				#if defined DEBUG_serial
				Serial.println ("Starting process print label ");
				#endif
				command_received = true;
				print_state = printing;
				executed = false;
			} else {		// Not the command we are expecting, wait for the good comand
				// send error, (not expected command); (E10)
				#if defined DEBUG_serial
				Serial.print("NOT *C04* command: ");
				Serial.println(last_command_received);
				#endif
			}
		}	
	}else{
		// we are in the preocess of printing
		// check if ready
	}
}

void get_configuration () {

	send_command (05);		// To indicate we are ready to start
	
	
	
	boolean SA = false;		// server_address (host name)
	boolean SS = false;		// server_script (Host Address)
	boolean IP = false;		// printer_IP
	boolean PS = false;		// password
	boolean PP = false;		// printer port
	boolean SB = false;		// seeds batch
	
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
	if (false) {		// just testing...
		SA = true;
		SS = true;
		IP = true;
		PS = true;
		PP = true;
		SB = true;
	}
	// Check if we finished configuring
	while (!SA || !SS || !IP || !PS || !PP || !SB)  {
		#if defined DEBUG_serial
		Serial.println("Ready to receive Command "); 
		#endif
		/* 
		C07 - Send SA (server_address)
		C08 - Send SS (server_script)
		C09 - Send SB (seeds_batch)
		C10 - Send IP (printer_IP)
		C11 - Send PS (password)
		C12 - Send PP (printer_port)
		*/
		int last_command_received = receiveNextValidCommand()
		switch (last_command_received) { 
			case 07:
				recevie_data (hostName,bufferShort);
				SA = true;
			break;
			
			case 08:
				recevie_data (hostAddress,buffer);
				SS = true;
			break;
			
			case 09:
				recevie_data (seeds_batch,buffer_batch);
				SB = true;
			break;
			
			case 10:		// Printer IP
				char printerIP[bufferShort];
				recevie_data (printerIP,bufferShort);
				// Staring of script
				String SprinterIP = printerIP;
				// convert into -> byte printer_ipAddr[4]
				// ip 10.11.12.13
				int firstDot = SprinterIP.indexOf('.');
				int secondDot = SprinterIP.indexOf('.', firstDot + 1 );
				int thirdDot = SprinterIP.indexOf('.', secondDot + 1 );
				int lastChar = SprinterIP.length();

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
				#if defined DEBUG_serial
				Serial.print ("IP: ");
				Serial.println (ip_to_str(printer_ipAddr));
				#endif
				IP = true;
			break;
			
			case 11:
				recevie_data (password,bufferShort);
				PS = true;
			break;
			
			case 12:
				const int buf_port = 6;
				char printerPort[buf_port];
				recevie_data (printerPort,buf_port);
				char * thisChar = printerPort;
				printer_port = atoi(thisChar);
				PP = true;
			break;
			
			case default:
				// something went WRONG
				#if defined DEBUG_serial
				Serial.print("something went WRONG: "); 
				Serial.println(last_command_received);
				#endif
			break;
		}	
		/*
		//////////////////////////////////////
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
			char printerIP[bufferShort];
			#if defined DEBUG_serial
			Serial.print("Received: "); 
			Serial.println(command);
			Serial.println("Ready to receive DATA ");
			#endif
			length = 0;
			while (!Serial.available()) {}
			while (Serial.available()) {
				printerIP[length] = Serial.read();
				length = (length+1) % bufferShort;
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
		}*/
	}
	
	send_command (01);		// To indicate we configured correctly
	
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
	Serial.print ("SB: ");
	Serial.println (seeds_batch);
	// delay (300);
	#endif
}