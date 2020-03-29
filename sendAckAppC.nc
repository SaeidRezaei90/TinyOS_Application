/**
 *  Configuration file for wiring of sendAckC module to other common 
 *  components needed for proper functioning
 *
 *  @author Saeid Rezaei
 */

#include "sendAck.h"

configuration sendAckAppC {}

implementation {

/****** COMPONENTS *****/
  components MainC, sendAckC as App;
  components new TimerMilliC();
  components ActiveMessageC;
  //components new AMSenderC(AM_SEND_MSG) as Resp_send;
  //components new AMSenderC(AM_SEND_MSG) as Req_send;
  components new AMSenderC (AM_SEND_MSG);
  components new AMReceiverC(AM_SEND_MSG);
  components new FakeSensorC();
  //Boot interface
  App.Boot -> MainC.Boot;

  //Timer interface
  App.Timer -> TimerMilliC;
  
  //Sensor read
  App.Read -> FakeSensorC;


  //Radio Control
  App.SplitControl -> ActiveMessageC;
  App.ReqSend -> AMSenderC;
  App.RespSend -> AMSenderC;
  App.Packet -> AMSenderC;
  App.Receive -> AMReceiverC;
  App.PacketAcknowledgements->ActiveMessageC;

}

