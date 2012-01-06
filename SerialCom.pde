//////////////////////////////
// COMMUNICATION FUNCTIONS
//////////////////////////////
	
#define endOfLine '*'
	
//////////////////////////
// Receive
//////////////////////////
#define number_of_commands 20
#define number_of_errors 20

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
			char c = (char) Serial.read();
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
			char c = Serial.read();
			// Serial.print (c);	// JUST for debug
			
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
			commandNumberInt = atoi(&commandNumber[i]);		// Transform received string into integer
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
			errorNumberInt = atoi(&commandNumber[i]);		// Transform received string into integer
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


boolean recevie_data (char* parameter_container,int buffer) {
	
	// first clean data
	int len = buffer;
	for (int c = 0; c < len; c++) {
		parameter_container[c] = 0;
	}

	while (true) {
		while (Serial.available()) {
			char c = (char) Serial.read();
			
			//Serial.print (Serial.read());	// JUST for debug
			
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
				}else if (strlen(parameter_container) == buffer ) {
					// Serial.println (" Reached the data max lengh, we reset the tag" );
					// Error!! buffer overload
					return false;
				}else{
					// DATA comes here
					// Serial.print (c);
					parameter_container[strlen(parameter_container)]=c;
					// DEBUG IP
				}
			}
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
	// Waiting for a comand to be received (default print command 04) as we already configured printer.
	if (print_state == ready) {
		
		#if defined DEBUG_serial
		Serial.println("Network ready!"); 
		Serial.println("Waiting for print label command (C04)");
		#endif
		
		boolean command_received = false;
		while (!command_received) {
			int last_command_received = receiveNextValidCommand();
			if (last_command_received == 04) {				// Petition of configuration all correct.
				send_command (1);
				#if defined DEBUG_serial
				Serial.println ("Starting process print label ");
				#endif
				command_received = true;
				print_state = printing;
				executed = false;
			} else if (last_command_received == 03) {		// Petition to configure printer
				send_command (1);
				get_configuration ();
				// command_received = true;
			} else {		// Not the command we are expecting, wait for the good comand
				// send error, (not expected command); (E10)
				#if defined DEBUG_serial
				Serial.print("NOT *C04* or *C03* command: ");
				Serial.println(last_command_received);
				#endif
			}
		}	
	}else{
		// we are in the preocess of printing
		// check if ready
	}
}


void indicate_we_are_ready () {
	send_command (5);		// To indicate we are ready to start
	
	// since we have to configure wait until we receive configure command
	boolean command_received = false;
	while (!command_received) {
		int last_command_received = receiveNextValidCommand();
		if (last_command_received == 03) {		// Petition to configure printer
			send_command (1);
			// get_configuration ();
			command_received = true;
		} else {		// Not the command we are expecting, wait for the good comand
			send_command (2);	// indicates ther is an error
			send_error (3);		// send error, Expected command (C03) (configure network)
			#if defined DEBUG_serial
			Serial.print("NOT *C03* command: ");
			Serial.println(last_command_received);
			#endif
		}
	}	
	
}


void get_configuration () {
	// Prepare to receive all configuration data
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
	if (false) {		// just for testing...
		SA = true;
		SS = true;
		IP = true;
		PS = true;
		PP = true;
		SB = true;
	}*/
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
		int last_command_received = receiveNextValidCommand();
		switch (last_command_received) { 
			case 7:
				recevie_data (hostName,bufferShort);
				SA = true;
				//Serial.print ("-7-");
			break;
			
			case 8:
				recevie_data (hostAddress,buffer);
				SS = true;
				//Serial.print ("-8-");
			break;
			
			case 9:
				recevie_data (seeds_batch,buffer_batch);
				SB = true;
				//Serial.print ("-9-");
			break;
			
			case 10:		// Printer IP
				receive_printer_IP ();
				IP = true;
				//Serial.print ("-10-");
			break;
			
			case 11:
				recevie_data (password,bufferShort);
				PS = true;
				//Serial.print ("-11-");
			break;
			
			case 12:
				receive_printer_port ();
				PP = true;
				//Serial.print ("-12-");
			break;
			
			default:
				// something went WRONG
				#if defined DEBUG_serial
				Serial.print("something went WRONG: "); 
				Serial.println(last_command_received);
				#endif
				send_command (2);	// send error
				send_error (4);		// Error 4 Configuration command not supported
			break;
		}	
	}
	
	send_command (1);		// To indicate we configured correctly
	
	//#if defined DEBUG_serial
	Serial.println ("");
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
	//#endif
}

void receive_printer_port () {
	const int buf_port = 6;
	char printerPort[buf_port];
	recevie_data (printerPort,buf_port);
	char * thisChar = printerPort;
	printer_port = atoi(thisChar);
}

void receive_printer_IP () {
	int buf_ip =17;				// 17 is the maximum numbers an IP can contain (including dots) 
	char printerIP[buf_ip];		
	recevie_data (printerIP,buf_ip);
	Serial.println (printerIP);
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
	//Serial.println (num);
	printer_ipAddr[0] = (byte) num;
	
	num = 0;
	for (int i = (secondDot-1); i>=(firstDot+1) ; i--) {
		num = atoi(&printerIP[i]);
	}
	//Serial.println (num);
	printer_ipAddr[1] = (byte) num;
	
	num = 0;
	for (int i = (thirdDot-1); i>=(secondDot+1) ; i--) {
		num = atoi(&printerIP[i]);
	}
	//Serial.println (num);
	printer_ipAddr[2] = (byte) num;
	
	num = 0;
	for (int i = (lastChar-1); i>=(thirdDot+1) ; i--) {
		num = atoi(&printerIP[i]);
	}
	//Serial.println (num);
	printer_ipAddr[3] = (byte) num;
	#if defined DEBUG_serial
	Serial.print (F("IP: "));
	Serial.println (ip_to_str(printer_ipAddr));
	#endif
}