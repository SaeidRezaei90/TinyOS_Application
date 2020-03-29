/**
 *  @author Saeid Rezaei
 */
#ifndef SENDACK_H
#define SENDACK_H

typedef nx_struct sensor_msg {
	nx_uint8_t type;
	nx_uint16_t data;
	nx_uint8_t counter;
} sensor_msg_t;

#define REQ 1
#define RESP 2 

enum {
	AM_SEND_MSG = 6,
};

#endif













#ifndef SENDACK_H
#define SENDACK_H

//payload of the msg
typedef nx_struct my_msg {
	//field 1
	//field 2
	//field 3
} my_msg_t;

#define REQ 1
#define RESP 2 

enum{
AM_MY_MSG = 6,
};

#endif
