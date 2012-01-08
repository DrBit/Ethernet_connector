
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
      //process_data(dataRec);          // Proces the recorded data as data
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
    reset_data();
  }else{
    strgdata_Result[strlen(strgdata_Result)]=input;
  }
}

void reset_data() {    // Reset Data String
  //Clean string
  int len = strlen(dataRec);
  for (int c = 0; c < len; c++) {
    dataRec[c] = 0;
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
  //Check if its one of the tags we want
  for (int i=0; i < numberOfTags; i++) {    // We compare the TAG we got with our desired TAGs
    if (!strcmp(tag_in,myTagStrings[i])) {  // If we have a match...
      data_type = i;                        // We store the type of match
      got_match = true;                     // We rise the flag
	  received_data = true;					// Flag for the outside code know we got a match (this wont be reset inside XML handler)
    }
  }
  // If one maches it will continu
  if (got_match) {
    // If it is a desitred tag, we output info
    data_mode = true;                       // We prepare to capture next data which will be the sensitive data
    reset_tag();                     // We reset the tag information
    got_match = false;               // We restore the got_match flag
	clean_data(dataRec);			 // Clean data before getting the new one. 
  }else{                             // If we dont have a match, this tag is not what we want                               // END Debug
    reset_tag();                     // We wipeout the tag and
    inici = true;                    // Start over again
  } 
}


// Process data gathered
void process_data(char* data_in) {

	for (int a=0; a<max_data_leng; a++) {
		//labelParameter[a] = data_in[a];
	}
}

void clean_data(char* data_in) {
	//Clean data
	int len = strlen(data_in);
	for (int c = 0; c < len; c++) {
		data_in[c] = 0;
	}
}

