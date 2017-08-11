#define NUM_PASS 3
#define MAX_PASS 2
#define HEIGHT 4			// bit wise

mtype = {
        /* common state*/
	WAIT,

	/* passenger state */
	GETON,
  	GETOFF,
	
	/* elevator state */
	MOVE_UP,
	MOVE_DOWN,
	FLOOR,
};


typedef Object
{
    /* common fields */
    mtype state = WAIT;
    mtype last_state = WAIT;
    byte floor = 0;			// bit wise current floor
   
    /* elevator fields */
    byte stopping_floors = 0;		// bit wise floors to be stopping
    byte number_of_passengers = 0;	// count wise

    /* passenger fields */
    byte destination = 0;		// bit wise destination
    short id = 0;			// bit wise id
    
};

byte participation = 0;			// bit wise
byte turn = 0;				// bit wise
Object elevator;


inline echo1() {
	printf("passenger.state :%e, turn :%d, passenger.id :%d  stopping_floors:%d, floor:%d\n",passenger.state, turn, passenger.id, elevator.stopping_floors , elevator.floor);
}

inline echo2() {
	printf("elevator.state :%e, turn :%d, elevator   stopping_floors:%d, floor:%d\n",elevator.state, turn, elevator.stopping_floors , elevator.floor);
}

proctype Passenger(Object passenger)
{

  participation = participation | passenger.id;
  do
  	:: passenger.state == WAIT -> wait: 
	  (turn & passenger.id) > 0;
	  atomic {
		if
		:: passenger.floor == elevator.floor && elevator.number_of_passengers < MAX_PASS ->  { 
			passenger.state = GETON;
			elevator.number_of_passengers++;
			elevator.stopping_floors = elevator.stopping_floors | passenger.destination;
		  }
		:: else -> elevator.stopping_floors = elevator.stopping_floors | passenger.floor;
		fi;
		echo1();
		turn = turn - passenger.id;
	  };
  	:: passenger.state == GETON -> geton: 
	  (turn & passenger.id) > 0;
	  atomic {
		if
		:: passenger.destination == elevator.floor ->  { 
			passenger.state = GETOFF;
			elevator.number_of_passengers--;
		   }
		:: else -> skip;
		fi;
		echo1();
		turn = turn - passenger.id;
	  };
  	:: passenger.state == GETOFF -> getoff: 
	  (turn & passenger.id) > 0;
	  atomic { 
		participation = participation - passenger.id;
		turn = turn - passenger.id;
		echo1();
		break;
	  }
  od;

  printf("-------------------process is ended, passenger.id :%d ------------------\n", passenger.id );
};


proctype Elevator()
{
  do
  	:: elevator.state == WAIT -> 
	   turn == 0;
	   atomic {
		if
		:: elevator.stopping_floors > 0 && elevator.stopping_floors > elevator.floor  -> elevator.state = MOVE_UP; elevator.last_state = WAIT;
		:: elevator.stopping_floors > 0 && elevator.stopping_floors < elevator.floor && elevator.floor > 1 -> elevator.state = MOVE_DOWN; elevator.last_state = WAIT;

		:: else -> skip;
		fi;
		echo2();
		turn = participation;
	   };
  	:: elevator.state == MOVE_UP -> 
	   turn == 0;
	   atomic {
		elevator.floor = elevator.floor << 1;
		elevator.stopping_floors = (elevator.stopping_floors ^ elevator.floor) & elevator.stopping_floors;
		elevator.state = FLOOR; elevator.last_state = MOVE_UP;
		echo2();
		turn = participation;
	   };
  	:: elevator.state == MOVE_DOWN ->
	   turn == 0;
	   atomic {
		elevator.floor = elevator.floor >> 1;
		elevator.stopping_floors = (elevator.stopping_floors ^ elevator.floor) & elevator.stopping_floors;
		elevator.state = FLOOR; elevator.last_state = MOVE_UP;
		echo2();
		turn = participation;
	   };
  	:: elevator.state == FLOOR -> 
	   turn == 0;
	   atomic {
		if
		:: elevator.last_state == MOVE_UP && elevator.stopping_floors > elevator.floor  -> elevator.state = MOVE_UP;
		:: elevator.last_state == MOVE_UP && elevator.stopping_floors < elevator.floor  -> elevator.state = MOVE_DOWN;
		:: elevator.last_state == MOVE_DOWN && elevator.stopping_floors & (elevator.floor-1) > 0 -> elevator.state = MOVE_DOWN;
		:: elevator.last_state == MOVE_DOWN && elevator.stopping_floors & (elevator.floor-1) == 0 && elevator.stopping_floors > 0 -> elevator.state = MOVE_UP;
		:: else -> elevator.state = WAIT;
		fi;
		echo2();
		turn = participation;
	   };
  od;
};



init {

	Object passenger1;
	passenger1.id = 1;
	passenger1.floor=2;
	passenger1.destination=4;

	Object passenger2;
	passenger2.id = 2;
	passenger2.floor=4;
	passenger2.destination=1;
	
	Object passenger3;
	passenger3.id = 4;
	passenger3.floor=1;
	passenger3.destination=8;
	
	Object passenger4;
	passenger4.id = 8;
	passenger4.floor=1;
	passenger4.destination=4;
	
	run Passenger(passenger1);
	run Passenger(passenger2);
	run Passenger(passenger3);
	run Passenger(passenger4);
	
	elevator.floor = 1;
	run Elevator();
}


/* LTL */

ltl spec1 { Passenger@wait  -> <>Passenger@geton } 
ltl spec2 { Passenger@geton -> <>Passenger@getoff }
ltl spec3 { [](!elevator.number_of_passengers <= MAX_PASS) }
