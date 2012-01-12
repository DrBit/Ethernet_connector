
////////////////////////
// XML FUCNTIONS
////////////////////////

void XML_pharser() {

  if (inici){
    char inputC = client.read();  // read char
	#if defined DEBUG_serial
	Serial.print(inputC);
	#endif
    // Record Tag
    if (inputC == '<') {
      tag_mode = true;
      record_tag(inputC, tagRec); // We will record the character
      inici = false;
    }
  }
  
  while (tag_mode) {
    char inputC = client.read();  // read char
	#if defined DEBUG_serial
	Serial.print (inputC);
	#endif
    record_tag(inputC, tagRec);   // We will record the character
    if (inputC == '>') {          // We are ending the tag
	  process_tag(tagRec);        // We process the tag
      tag_mode = false;           // We exit tag mode
    }else if (inputC == '<') {    // If we didn't finish the tag and we got a new one...
      reset_tag();                // We reset the tag
      record_tag('<', tagRec);    // We record again the firts character again
    }
  }
  
  while (data_mode) {
    char inputC = client.read();      // read char
	#if defined DEBUG_serial
	Serial.print (inputC);
	#endif
    if (inputC == '<') {              // If it's a coming tag means we finished the data
      record_tag(inputC, tagRec);     // We will record the character for the coming tag
      process_data(dataRec);          // Proces the recorded data as data
	  LastTagNumber = 0;			  // RESET FALG
	  LastPosTagNumber = 0;				// Reset FLAG
      tag_mode = true;
      data_mode = false;              // Quit data mode
    }else{
      record_data(inputC, dataRec);   // If its not coming tag We will record the data
    }
  }
}

//Record data
void record_data (char input, char* strgdata_Result ) {
  if (strlen(strgdata_Result)== max_data_leng ) {
    //Serial.println (" Reached the data max lengh, we reset the tag" );
    reset_data(dataRec);
  }else{
    strgdata_Result[strlen(strgdata_Result)]=input;
  }
}

void reset_data(char* data_in) {    // Reset Data String
  //Clean string
  int len = strlen(data_in);
  for (int c = 0; c < len; c++) {
    data_in[c] = 0;
  }
}

//Record tag
void record_tag (char input, char* strgtag_Result ) {
  if (strlen(strgtag_Result)== max_tag_leng ) {
    // Serial.println (" Reached the tag max lengh, we reset the tag" );
    reset_tag();
  }else{
    strgtag_Result[strlen(strgtag_Result)]=input;
  }
}

void reset_tag() {    // Reset Tag String
  //Clean string
  int len = strlen(tagRec);
  for (int c = 0; c < len; c++) {
    tagRec[c] = 0;
  }
}

// Process Tag
void process_tag(char* tag_in) {
	//Check if its one of the tags we have stored
	for (int i=0; i < numberOfTags; i++) {    // We compare the TAG we got with our desired TAGs
		if (!strcmp(tag_in,myTagStrings[i])) {  // If we have a match...
		  got_match = true;                     // We rise the flag
		  LastTagNumber = i + 1;				// 0 is reserved for NO TAG
		  LastPosTagNumber = 0;
		  received_data = true;					// Flag for the outside code know we got a match (this wont be reset inside XML handler)
		}
	}
  
	if (!got_match) {
		//Check if its one of the tags we want
		for (int i=1; i <= numberOfPostitions; i++) {    // We compare the TAG we got with our desired TAGs
		// for (int i=0; i < config.numberOfPostitions; i++) {    // We compare the TAG we got with our desired TAGs
			
			for (int p = 1; p <= 4; p++) {
				
				char created_tag [6];
				if (p==1) {
					sprintf(created_tag, "<Xc%d>", i);
				}
				if (p==2) {
					sprintf(created_tag, "<Xf%d>", i);
				}
				if (p==3) {
					sprintf(created_tag, "<Yc%d>", i);
				}
				if (p==4) {
					sprintf(created_tag, "<Yf%d>", i);
				}
				
				if (!strcmp(tag_in,created_tag)) {		// If we have a match...
					got_match = true;						// We rise the flag
					LastTagNumber = 0;						// 0 is reserved for NO TAG
					LastPosTagNumber = ((i-1)*4) + p;		// Flag last tag
					received_data = true;					// Flag for the outside code know we got a match (this wont be reset inside XML handler)
				}
			}
		}
	}

	// If one maches it will continue
	if (got_match) {
		// If it is a desitred tag, we output info
		data_mode = true;                // We prepare to capture next data which will be the sensitive data
		reset_tag();                     // We reset the tag information
		got_match = false;               // We restore the got_match flag
		clean_data(dataRec);			 // Clean container before getting the new data. 
	}else{                             // If we dont have a match, this tag is not what we want                               // END Debug
		reset_tag();                     // We wipeout the tag and
		inici = true;                    // Start over again
	} 
}


// Process data gathered
#define DB_row 1

prog_uchar procesD1[] PROGMEM  = {"Item recorded!><"};
prog_uchar procesD2[] PROGMEM  = {"Item is the same!><"};
//	"<SA>", "<SS>", "<PS>", "<PP>",
//	"<IP1>", "<IP2>", "<IP3>", "<IP4>",

void process_data(char* data_in) {	
	//Got a valid tag!
	if (LastTagNumber > 0) {
		// Tag is valid, processing!
		switch (LastTagNumber) {
			// process data here only if its configuration, other data is processed elsewhere...
			
			// We point our temporal container to the data we want to change
			case 1:	{	// Tag 1 SA (Batch Server address in DNS form)
				if (strcmp(data_in,config.server_address)) {		// If data is different from the eeprom
					// store data in eeprom
					#if defined DEBUG_serial
					SerialFlashPrint (procesD1);
					#endif
					sprintf(config.server_address, data_in);
					db.write(DB_row, DB_REC config);
				}else{
					#if defined DEBUG_serial
					SerialFlashPrint (procesD2);
					#endif
				}
			break; }
			
			case 2:	{	// Tag 1 SS (Batch Server Script)
				if (strcmp(data_in,config.server_script)) {		// If data is different from the eeprom
					// store data in eeprom
					#if defined DEBUG_serial
					SerialFlashPrint (procesD1);
					#endif
					sprintf(config.server_script, data_in);
					db.write(DB_row, DB_REC config);
				}else{
					#if defined DEBUG_serial
					SerialFlashPrint (procesD2);
					#endif
				}
			break;}
			
			case 3:	{	// Tag 3 PS (Password)
				if (strcmp(data_in,config.password)) {		// If data is different from the eeprom
					// store data in eeprom
					#if defined DEBUG_serial
					// Serial.print("server_address different and recorded!");
					SerialFlashPrint (procesD1);
					#endif
					sprintf(config.password, data_in);
					db.write(DB_row, DB_REC config);
				}else{
					#if defined DEBUG_serial
					SerialFlashPrint (procesD2);
					#endif
				}
			break;}
			
			case 4:	{	// Tag 3 PP (Printer port)
				// convert data in into integuer
				int num = 0;
				// IF THIS IS FAILING TRY "(data_in)-1" in the line bellow
				for (int i = (strlen(data_in)-2); i>=0 ; i--) {
					num = atoi(&data_in[i]);
				}
				// Compare and store
				if (num != config.printer_port) {		// If data is different from the eeprom
					// store data in eeprom
					#if defined DEBUG_serial
					// Serial.print("server_address different and recorded!");
					SerialFlashPrint (procesD1);
					#endif
					config.printer_port = num;
					db.write(DB_row, DB_REC config);
				}else{
					#if defined DEBUG_serial
					SerialFlashPrint (procesD2);
					#endif
				}
			break;}
			
			case 5:	{	// Tag IP1
				// convert data in into integuer
				int num = 0;
				for (int i = (strlen(data_in)-1); i>=0 ; i--) {
					num = atoi(&data_in[i]);
				}
				// Compare and store
				if (num != config.printer_IP[0]) {		// If data is different from the eeprom
					// store data in eeprom
					#if defined DEBUG_serial
					// Serial.print("server_address different and recorded!");
					SerialFlashPrint (procesD1);
					#endif
					config.printer_IP[0] = num;
					db.write(DB_row, DB_REC config);
				}else{
					#if defined DEBUG_serial
					SerialFlashPrint (procesD2);
					#endif
				}
			break;}
			
			case 6:	{	// Tag IP2
				// convert data in into integuer
				int num = 0;
				for (int i = (strlen(data_in)-1); i>=0 ; i--) {
					num = atoi(&data_in[i]);
				}
				// Compare and store
				if (num != config.printer_IP[1]) {		// If data is different from the eeprom
					// store data in eeprom
					#if defined DEBUG_serial
					// Serial.print("server_address different and recorded!");
					SerialFlashPrint (procesD1);
					#endif
					config.printer_IP[1] = num;
					db.write(DB_row, DB_REC config);
				}else{
					#if defined DEBUG_serial
					SerialFlashPrint (procesD2);
					#endif
				}
			break;}
			
			case 7:	{	// Tag IP3
				// convert data in into integuer
				byte num = 0;
				for (int i = (strlen(data_in)-1); i>=0 ; i--) {
					num = atoi(&data_in[i]);
				}
				// Compare and store
				if (num != config.printer_IP[2]) {		// If data is different from the eeprom
					// store data in eeprom
					#if defined DEBUG_serial
					// Serial.print("server_address different and recorded!");
					SerialFlashPrint (procesD1);
					#endif
					config.printer_IP[2] = num;
					db.write(DB_row, DB_REC config);
				}else{
					#if defined DEBUG_serial
					SerialFlashPrint (procesD2);
					#endif
				}
			break;}
			
			case 8:	{	// Tag IP4
				// convert data in into integuer
				byte num = 0;
				for (int i = (strlen(data_in)-1); i>=0 ; i--) {
					num = atoi(&data_in[i]);
				}
				// Compare and store
				if (num != config.printer_IP[3]) {		// If data is different from the eeprom
					// store data in eeprom
					#if defined DEBUG_serial
					// Serial.print("server_address different and recorded!");
					SerialFlashPrint (procesD1);
					#endif
					config.printer_IP[3] = num;
					db.write(DB_row, DB_REC config);
				}else{
					#if defined DEBUG_serial
					SerialFlashPrint (procesD2);
					#endif
				}
			break;}
		}
	}else if (LastPosTagNumber > 0) {
		//Got a valid tag!
		// send command over serial to indicate we are going to send a position
		send_command (00);
		// whait for confiramtion
		
		// send data es
		Serial.print (LastPosTagNumber,DEC);
		Serial.print (",");
		Serial.print (data_in);
		send_command (00);
		// send command over serial to indicate we finished sending a position
	}
}



/*
		
		// AT the other side (example):
		
		// Calculate which is exatly the position we are working with.
		int position_number = LastPosTagNumber / 4;		// Gives us position number
		int position_component = LastPosTagNumber % 4;	// Gives us the component (1=Xc, 2=Xf, 3=Yc, 0=Yf)
		
		
		// Tag is valid, processing!
		switch (LastPosTagNumber) {
			// process positions here only if its configuration, other data is processed elsewhere...
	
			
			case 4:	{	// Tag 3 PP (Printer port)
				// convert data in into integuer
				int num = 0;
				for (int i = (strlen(data_in)-1); i>=0 ; i--) {
					num = atoi(&data_in[i]);
				}
				// Compare and store
				if (num != config.printer_port) {		// If data is different from the eeprom
					// store data in eeprom
					#if defined DEBUG_serial
					// Serial.print("server_address different and recorded!");
					SerialFlashPrintln (procesD1);
					#endif
					config.printer_port = num;
					db.write(DB_row, DB_REC config);
				}else{
					#if defined DEBUG_serial
					SerialFlashPrintln (procesD2);
					#endif
				}
			break;}
			
			case 8:	{	// Tag IP4
				// convert data in into integuer
				byte num = 0;
				for (int i = (strlen(data_in)-1); i>=0 ; i--) {
					num = atoi(&data_in[i]);
				}
				// Compare and store
				if (num != config.printer_IP[3]) {		// If data is different from the eeprom
					// store data in eeprom
					#if defined DEBUG_serial
					// Serial.print("server_address different and recorded!");
					SerialFlashPrintln (procesD1);
					#endif
					config.printer_IP[3] = num;
					db.write(DB_row, DB_REC config);
				}else{
					#if defined DEBUG_serial
					SerialFlashPrintln (procesD2);
					#endif
				}
			break;}
	
			
		}
}*/

void clean_data(char* data_in) {
	//Clean data
	int len = strlen(data_in);
	for (int c = 0; c < len; c++) {
		data_in[c] = 0;
	}
}