/**
 *  Source file for implementation of module sendAckC in which
 *  the node 1 send a request to node 2 until it receives a response.
 *  The reply message contains a reading from the Fake Sensor.
 *
 *  @author Saeid Rezaei
 */

#include "sendAck.h"
#include "Timer.h"

module sendAckC {

  uses {
  /****** INTERFACES *****/
	interface Boot; 
	
	interface SplitControl; // to Start the radio
	interface Packet;
	interface AMSend as RespSend;
	interface AMSend as ReqSend;
	interface Receive;
	interface PacketAcknowledgements;
	
	interface Timer<TMilli>;
	
	//interface used to perform sensor reading (to get the value from a sensor)
	interface Read<uint16_t>;
  }

} 
implementation{

	message_t packet;
	
	bool locked = FALSE; 
	uint8_t counter = 0;
    uint8_t rec_id;
 
   void sendReq();
    void sendResp();
  
  
  //***************** Send request function ********************//
   void sendReq() {
	 //This function is called when we want to send a request
	 //* STEPS:
	 //* 1. Prepare the msg
	
	  sensor_msg_t* mess = (sensor_msg_t*)(call Packet.getPayload(&packet, sizeof(sensor_msg_t)));
	  if (mess == NULL) {
		return;
	  }
	 counter+=1;
	 mess->type = REQ; //0 is the type for REQ message
	 mess->counter = counter;
	 //mess->data = ""
	 dbg("radio_pack","Preparing the Request message ... \n");
	 
	 // 2. Set the ACK flag for the message using the PacketAcknowledgements interface
	//call PacketAcknowledgements.requestAck((sensor_msg_t*) mess);
	call PacketAcknowledgements.requestAck(&packet);
	 // 3. Send an UNICAST message to the correct node
	 if(call RespSend.send(2, &packet, sizeof(sensor_msg_t)) == SUCCESS){
	     dbg("radio_send", "Packet passed to lower layer successfully!\n");
	     dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	     dbg_clear("radio_pack","\t Payload Sent\n" );
		 dbg_clear("radio_pack", "\t\t type: %hhu \n ", mess->type);
		 dbg_clear("radio_pack", "\t\t counter: %hhu \n", mess->counter);
		 //dbg_clear("radio_pack", "\t\t data: %hhu \n", mess->data);
	}
	 //locked = true;
 }   
      
  //******************  send response *****************//
   void sendResp() {
  	/* This function is called when we receive the REQ message.
  	 * `call Read.read()` reads from the fake sensor.
  	 * When the reading is done it raise the event read Done.
  	 */
	call Read.read();
  }

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted on node %u.\n", TOS_NODE_ID);
	call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
	if(err == SUCCESS){
	dbg("radio","Radio On. \n");
	if(TOS_NODE_ID == 1){
	dbg("role", "node 1 start sending request.... :\n");
	call Timer.startPeriodic(1000);
	}
	}
	else{
	dbgerror("radio","Radio connection error");
	call SplitControl.start();
	}
  }
  
  event void SplitControl.stopDone(error_t err){
    
  }

  //***************** MilliTimer interface ********************//
  event void Timer.fired() {
	/* This event is triggered every time the timer fires.
	 * When the timer fires, we send a request
	 */
	 if(locked){
	 	return;
	 }
	 else{
	 	dbg("timer","timer fired at %s.\n", sim_time_string());
	 	 sendReq();
	 }
  }
  
  

  //********************* AMSend interface ****************//
  event void RespSend.sendDone(message_t* buf,error_t err) {
	/* This event is triggered when a message is sent 
	 *
	 * STEPS:
	 * 1. Check if the packet is sent
	 * 2. Check if the ACK is received (read the docs)
	 * 2a. If yes, stop the timer. The program is done
	 * 2b. Otherwise, send again the request
	*/
	if(&packet == buf && err == SUCCESS)
	{
		dbg("radio_send", "packet sent Successfully\n");
		if(call PacketAcknowledgements.wasAcked(&buf))
		{
			dbg("radio_ack", "ACK Received...");
     		dbg_clear("radio_send", " at time %s \n", sim_time_string());
			
			locked = TRUE;
		}
		else{
			dbgerror("ack", "Recieve Ack error!");
		}
	
	
	}
	else{
		dbgerror("radio_send", "Send done error!");
	}
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	/* This event is triggered when a message is received 
	 *
	 * STEPS:
	 * 1. Read the content of the message
	 * 2. Check if the type is request (REQ)
	 * 3. If a request is received, send the response
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	if(len != sizeof(sensor_msg_t)) {
		return buf;
	}
	else{
		sensor_msg_t* msg = (sensor_msg_t*)payload;
		
      dbg("radio_rec", "Received packet at time %s\n", sim_time_string());
      dbg("radio_pack"," Payload length %hhu \n", call Packet.payloadLength( buf ));
      dbg("radio_pack", ">>>Pack \n");
      dbg_clear("radio_pack","\t\t Payload Received\n" );
      dbg_clear("radio_pack", "\t\t type: %hhu \n ", msg->type);
	  dbg_clear("radio_pack", "\t\t counter: %hhu \n", msg->counter);
	  
	  if(msg->type == REQ)
	  {
	  	  rec_id = msg->counter;
		  sendResp();
	  }
     
      return buf;
	}
  }
  
  //************************* Read interface **********************//
  event void Read.readDone(error_t result, uint16_t data) {
	/* This event is triggered when the fake sensor finish to read (after a Read.read()) 
	 *
	 * STEPS:
	 * 1. Prepare the response (RESP)
	 * 2. Send back (with a unicast message) the response
	 * X. Use debug statement showing what's happening (i.e. message fields)
	 */
	 
	 if(result == SUCCESS){
	
	 	 sensor_msg_t* mess = (sensor_msg_t*)(call Packet.getPayload(&packet, sizeof(sensor_msg_t)));
		 if(mess == NULL){
	 		 dbgerror("Msg_err", "Response Message error \n");
		 }
		
	 	mess->type = RESP; 
	 	mess->counter = rec_id;
	 	mess->data = data;
		dbg("radio_pack","Preparing the Req message ... \n");
		
		//call PacketAcknowledgements.requestAck(&mess);
		call PacketAcknowledgements.requestAck(&packet);

	 // 3. Send an UNICAST message to the correct node
	 	if(call ReqSend.send(1, &packet, sizeof(sensor_msg_t)) == SUCCESS){
	     	dbg("radio_send", "Respose Packet passed to lower layer successfully!\n");
	     	dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	     	dbg_clear("radio_pack","\t Payload Sent\n" );
		 	dbg_clear("radio_pack", "\t\t type: %hhu \n ", mess->type);
		 	dbg_clear("radio_pack", "\t\t counter: %hhu \n", mess->counter);
			dbg_clear("radio_pack", "\t\t data: %hhu \n", mess->data);
		 	dbg_clear("radio_send","\n ");
         	dbg_clear("radio_pack","\n ");
	 	}
	 }
	 
	 else{
	  dbgerror("Resp_err", "Response error \n");
	 }
}
	 
	  event void ReqSend.sendDone(message_t* buf,error_t err) {
	/* This event is triggered when a Response is received 
	 *
	 * STEPS:
	 * 1. Check if the packet is sent
	 * 2. Check if the ACK is received (read the docs)
	 * 2a. If yes, switch the value of locker

	 * 2b. Otherwise, send again the request
	*/
	if(&packet == buf && err == SUCCESS)
	{
		if(call PacketAcknowledgements.wasAcked(buf))
		{
			dbg("radio_send", "Response Packet sent...");
     		dbg_clear("radio_send", " at time %s \n", sim_time_string());
			
			locked = FALSE;
		}
		else{
			dbgerror("Ack_send", "Recieve Response Ack error!");
		}
	
	
	}
	else{
		dbgerror("radio_send", "Send done error!");
	}
  }

}

