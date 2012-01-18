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
			if (c == endOfLine) { 		// begining or end of command
				// In this case we check if we had previous data in the buffer and process it if necessary
				// restart all and ready to receive a commmand
				if (lookForNumber) {
					lookForNumber = false;
					if (processCommand()) {	// we got a valid command!						
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
				// we got an incoming comand, start receive command number
				lookForNumber = true;
				incomingCommand = true;
				lookForLetter = false;
			}else if (lookForNumber) {
				// We look for the command number
				commandNumber[numberIndex] = c;
				if (numberIndex == command_digits) { 
					reset_command ();	// Command invalid too many characters
				}
				numberIndex++;
			}
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
	if (incomingCommand) {
		// convert commandNumber
		for (int i = (command_digits -1) ; i >= 0; i--) {
			commandNumberInt = atoi(&commandNumber[i]);		// Transform received string into integer

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
			
			if (c == endOfLine) { 		// begining or end of command
				// In this case we check if we had previous data in the buffer and process it if necessary
				// restart all and ready to receive a commmand
				if (lookForNumber) {
					lookForNumber = false;
					if (processCommand()) {	// we got a valid command!						
						if (incomingCommand) {
							reset_command ();
							if (commandNumberInt == 14) {
								parameter_container[strlen(parameter_container)] = '\0';
								return true;		// End of data stream
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
					// we got an incoming comand, start receive command number
					lookForNumber = true;
					incomingCommand = true;
					lookForLetter = false;
				}else if (lookForNumber) {
					// We look for the command number
					commandNumber[numberIndex] = c;
					if (numberIndex == command_digits) { 
						reset_command ();	// Command invalid too many characters
					}
					numberIndex++;
				}else if (strlen(parameter_container) == buffer ) { );
					// Error!! buffer overload
					return false;
				}else{
					// DATA comes here
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
	Serial.print(endOfLine);	// Print begining command
	Serial.print("C");
	// We need to send in form of two digits like (01)
	if (command < 10) {
		Serial.print('0');
	}
	Serial.print(command);
	Serial.print(endOfLine);	// Print end command
}

bool send_error (unsigned int command) {
	Serial.print(endOfLine);	// Print begining command
	Serial.print("E");
	// We need to send in form of two digits like (01)
	if (command < 10) {
		Serial.print('0');
	}
	Serial.print(command);
	Serial.print(endOfLine);	// Print end command
}


void send_data () {


}

//////////////////////////
// Common functions
//////////////////////////

prog_uchar waitpcommand1[] PROGMEM  = {"Waiting for command"};
/*prog_uchar waitpcommand2[] PROGMEM  = {"Starting process print label "};
prog_uchar waitpcommand3[] PROGMEM  = {"NOT expected command: "};
prog_uchar waitpcommand4[] PROGMEM  = {"Starting process fetch and send positions "};
prog_uchar waitpcommand5[] PROGMEM  = {"Send error to the server "};
prog_uchar waitpcommand6[] PROGMEM  = {"Send Action to the server"};
prog_uchar waitpcommand7[] PROGMEM  = {"Send Status to the server"};*/

int wait_for_print_command () {
	#if defined DEBUG_serial
	mem_check ();
	SerialFlashPrintln (waitpcommand1);
	#endif
	while (true) {
		return receiveNextValidCommand();
	}	
}


// INIT comunication with the arduino MEGA

prog_uchar open_comA1[] PROGMEM  = {"NOT *C01* command: "};
prog_uchar open_comA2[] PROGMEM  = {"\nModule ready!"};

void open_comunication_with_arduino () {
	send_command (5);		// To indicate we are ready to start
	
	boolean command_received = false;
	while (!command_received) {
		int last_command_received = receiveNextValidCommand();
		if (last_command_received == 01) {		// confirmation
			command_received = true;	// Send flag DNS received correctly and get out.
		} else {		// Not the command we are expecting, wait for the good comand
			send_command (2);	// indicates ther is an error
			send_error (3);		// send error, Expected command (C01) (confirmation)
			#if defined DEBUG_serial
			SerialFlashPrintln (open_comA1);
			Serial.println(last_command_received);
			#endif
		}
	}
	
	// confirmation received
	// comunication open and ready!
	#if defined DEBUG_serial
	SerialFlashPrintln (open_comA2);
	#endif
}


// function to print string from flash memory (with end carriage return)
void SerialFlashPrintln (prog_uchar* text_string) {
	char buffer;
	unsigned int a = 0;
	while (true) {
		buffer =  pgm_read_byte_near(text_string + a);
		if (buffer == '\0') break;
		Serial.print(buffer);
		a++;
	}
	Serial.println("");
}

// function to print string from flash memory (without end carriage return)
void SerialFlashPrint (prog_uchar* text_string) {
	char buffer;
	unsigned int a = 0;
	while (true) {
		buffer =  pgm_read_byte_near(text_string + a);
		if (buffer == '\0') break;
		Serial.print(buffer);
		a++;
	}
}