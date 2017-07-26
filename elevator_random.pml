#define NUM_PASS 8
#define MAX_PASS 3
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
    byte floor = 0;			// bit wise current floor
   
    /* elevator fields */
    byte stopping_floors = 0;		// bit wise floors to be stopping
    byte number_of_passengers = 0;	// count wise

    /* passenger fields */
    byte destination = 0;		// bit wise destination
    short id = 0;			// bit wise id
    
};

short participation = 0;		// bit wise
short turn = 0;				// bit wise
Object elevator;

inline echo0() {
	printf("passenger.state :%e, turn :%d, passenger.id :%d  passenger.floor :%d, destination :%d\n",passenger.state, turn, passenger.id, passenger.floor , passenger.destination);
}

inline echo1() {
	printf("passenger.state :%e, turn :%d, passenger.id :%d  stopping_floors:%d, floor:%d\n",passenger.state, turn, passenger.id, elevator.stopping_floors , elevator.floor);
}

inline echo2() {
	printf("elevator.state :%e, turn :%d, elevator   stopping_floors:%d, floor:%d\n",elevator.state, turn, elevator.stopping_floors , elevator.floor);
}

proctype Passenger(Object passenger)
{
  echo0();
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
		:: elevator.stopping_floors > 0 && elevator.stopping_floors > elevator.floor && elevator.floor < HEIGHT -> elevator.state = MOVE_UP;
		:: elevator.stopping_floors > 0 && elevator.stopping_floors < elevator.floor && elevator.floor > 1      -> elevator.state = MOVE_DOWN;
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
		elevator.state = FLOOR;
		echo2();
		turn = participation;
	   };
  	:: elevator.state == MOVE_DOWN ->
	   turn == 0;
	   atomic {
		elevator.floor = elevator.floor >> 1;
		elevator.stopping_floors = (elevator.stopping_floors ^ elevator.floor) & elevator.stopping_floors;
		elevator.state = FLOOR;
		echo2();
		turn = participation;
	   };
  	:: elevator.state == FLOOR -> 
	   turn == 0;
	   atomic {
		if
		:: elevator.state == MOVE_UP && elevator.stopping_floors > elevator.floor && elevator.floor < HEIGHT -> elevator.state = MOVE_UP;
		:: elevator.state == MOVE_UP && elevator.stopping_floors < elevator.floor  -> elevator.state = MOVE_DOWN;
		:: elevator.state == MOVE_DOWN && elevator.stopping_floors & (elevator.floor-1) > 0 && elevator.floor > 0 -> elevator.state = MOVE_DOWN;
		:: elevator.state == MOVE_DOWN && elevator.stopping_floors & (elevator.floor-1) == 0 && elevator.stopping_floors > 0 -> elevator.state = MOVE_UP;
		:: else -> elevator.state = WAIT;
		fi;
		echo2();
		turn = participation;
	   };
  od;
};



init {
	byte i = 0;
	short id = 1;
	byte floor = 1;
	byte destination = 1;

	do
	:: i < NUM_PASS -> 
	  if
	  :: floor = 1;
	  :: floor = 2;
	  :: floor = 4;
	  fi;
	  if
	  :: destination = 1;
	  :: destination = 2;
	  :: destination = 4;
	  fi;

	  atomic{
		Object passenger;
		passenger.id = id;
		passenger.floor = floor;
		passenger.destination = destination;
	 	i++;
		id = id << 1;
 
	  	run Passenger(passenger);
	  };
	:: else -> break;
	od;

	elevator.floor = 1;
	run Elevator();
}


/* LTL */

ltl spec1 { Passenger@wait  -> <>Passenger@geton } 
ltl spec2 { Passenger@geton -> <>Passenger@getoff }
ltl spec3 { [](!elevator.number_of_passengers <= MAX_PASS) }
