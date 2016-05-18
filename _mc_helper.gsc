#include maps\_utility; 
#include common_scripts\utility;
#include maps\_zombiemode_utility;
/*
#####################
by: M.A.K.E C E N T S
#####################
Script:
Place the following
	#include maps\_mc_helper;

in the gsc you want to use these helper functions
or add the functions you want to use to the gsc to use in, or to _zombiemode_utility
#####################################################################################
*/


IsVal(arg1, arg2, forceit){//replaces: if(isdefined(arg1) && arg1), if(isdefined(arg1) && isdefined(arg2) && arg1==arg2)
/*	arg1 = first thing to check if defined and true
	arg2 = optional, second thing to check arg1 against and if defined, default checks arg1 only
	forceit = optional, if arg2 is not defined returns false, default checks arg1 only
	
	Check if arg1 is true and defined, and also == to arg2 (optional), 
	if arg2 undefined it can still return true if arg1 is true
	strings return true
	
	Called on player, optionally set return value to varible:
	    isVal(arg1); //arg1 can be number, boolean, or ent
	    isVal(arg1, arg2); //arg2 can be number, boolean, or ent
	    isVal(arg1, arg2, forceit); //forceit should be boolean or nothing
	    result = isVal(arg1);//optional var set to return
*/
	if(!IsDefined( arg1 )){
		// /# IPrintLn( "IsVal, arg1 not defined" ); #/
		return false;
	}
	if(IsDefined( arg2 )){
		if(arg1==arg2) return true;
		return false;
	}
	if(IsDefined( forceit ) && forceit){
		// /# IPrintLn( "IsVal, arg1 defined, but arg2 not defined" ); #/
		return false;
	}
	if(arg1) return true;
	return false;
}

CanAfford(cost, subscore){//replaces: if(player.score>=score)
/*	cost = cost for this purchase or ent
	subscore = optional, subtract score true or false, default subtracts score unless otherwise told
	
	Check if the player can afford this purchase by calling on the player passing the cost or ent
	with zombie_cost defined. If cost is not defined, it will return true and print not defined.
	
	Called on player, optionally set return value to varible:
	    player CanAfford(cost);//cost would be replaced by number that it cost
		player CanAfford(ent);//passing the ent with zombie_cost defined
		player CanAfford(cost,subscore);//passing a 0 will not subtract score
		afford = player CanAfford(1250);//optional var set to return
*/
	if(!IsDefined( self ) || self == level) return false;
	if(!is_player_valid( self )) return false;
	if(IsDefined( cost ) && IsDefined( cost.zombie_cost )) cost = cost.zombie_cost;
	if(!IsDefined( cost )){
		IPrintLn( "-- ^1cost is not defined" );
		return true;
	}
	if(self.score+5>=cost){
		if((IsDefined( subscore ) && !subscore) || cost==0) return true;
		self maps\_zombiemode_score::minus_to_player_score( cost );
		return true;
	}
	return false;
}


GiveWeaponOrAmmo(gun){//replaces self GiveWeapon( Weaponfile Name ), self GiveStartAmmo( Weaponfile Name )
/*  gun = gun to give or give ammo for

	Requires: CanAfford(cost,subscore)
	Check if player can afford gun or ammo depending if player has gun, checks for mulekick, plays sound 
	and subtracts points, returns what it gave player for use if necessary

	Called on player, optionally set return value to varible:
		player GiveWeaponOrAmmo(nameofguntogive);//replace nameofguntogive with name of gun to give, gives ammo or gun
		player GiveWeaponOrAmmo();//gives ammo for current gun
		gave = player GiveWeaponOrAmmo(nameofguntogive);//optional var set to return
*/
	if(!IsDefined( gun )) gun=self GetCurrentWeapon();
	currentGun = self GetCurrentWeapon();
	if(!is_player_valid(self) || !isDefined(level.zombie_include_weapons[gun]) || !isDefined(gun) || !isDefined(currentGun) || gun == "none" || WeaponClass(gun) == "grenade" || currentGun == "none" || WeaponClass(currentGun) == "grenade" ) return "none";
	if(self HasWeapon(gun) && self CandAfford(level.zombie_include_weapons[gun].ammo_cost,false)){
		if(WeaponClass(gun) == "gas" || weaponStartAmmo(gun) <= self getWeaponAmmoStock(gun)) return "none";
		self GiveStartAmmo(gun);
		if(gun != currentGun) self SwitchToWeapon(gun);
		self maps\_zombiemode_score::minus_to_player_score( level.zombie_include_weapons[gun].ammo_cost );
		self playLocalSound("cha_ching");
		return "ammo";
	}else if(self CandAfford(level.zombie_include_weapons[gun].cost,false)){
		weapons = self GetWeaponsListPrimaries();
		maxguns = 2;
		if(self HasPerk("specialty_extraammo")) maxguns = 3;
		if(weapons.size >= maxguns) self TakeWeapon(currentGun);
		self GiveWeapon(gun);
		self SwitchToWeapon(gun);
		self GiveStartAmmo(gun);
		self maps\_zombiemode_score::minus_to_player_score( level.zombie_include_weapons[gun].cost );
		self playLocalSound("cha_ching");
		return "gun";
	}
	self playLocalSound("no_cha_ching");
	return "none";
}

isFacing( facee, player ){// copied from _laststand.gsc and modified
	if(!IsDefined( facee )||!IsDefined( player )) return false;
	if( distancesquared( player.origin, facee.origin ) < (110*110) ) return false;
	player_angles = player GetPlayerAngles();;
	forwardVec = anglesToForward( player_angles );
	forwardVec2D = ( forwardVec[0], forwardVec[1], 0 );
	unitForwardVec2D = VectorNormalize( forwardVec2D );
	toFaceeVec = facee.origin - player.origin;
	toFaceeVec2D = ( toFaceeVec[0], toFaceeVec[1], 0 );
	unitToFaceeVec2D = VectorNormalize( toFaceeVec2D );
	dotProduct = VectorDot( unitForwardVec2D, unitToFaceeVec2D );
	return ( dotProduct > 0.95 );
}

isSprinting(){//player isSprinting();
	velocity = self GetVelocity();
	player_speed = abs(velocity[0]) + abs(velocity[1]); 
	if(player_speed > 225) return true;
	return false;
}

MyWaitTillTrig(cost){//replaces trigger waittill("trigger", player)
/*	cost = optional, will look at zombie_cost if not defined, and continue if neither is defined
	
	Requires: CanAfford(cost,subscore)
	Return the player that just bought something if they can afford it, adds small wait for controllers

	Calls:
		player = trigger MyWaitTillTrig();
		player = trigger MyWaitTillTrig();
*/
	if(!IsDefined( self ) || self == level){
		IPrintLn( "-- ^1This trigger was not defined, or this function was called on level and not a trigger" );
		IPrintLn( "-- ^1The host will be returned" );
		return get_players()[0];//returns host to limit errors
	}
	while(1){
		self waittill("trigger",player);
		if(!is_player_valid( player )){
			wait(.1);
			continue;
		}
		for( t=0;t<.15;t=t+.05 ){
			wait(.05);
			if(!player UseButtonPressed()) continue;
		}
		if(!player UseButtonPressed()) continue;
		if(!IsDefined( cost ) && isDefined(self.zombie_cost)) cost = self.zombie_cost;
		if(!IsDefined( cost )) cost = 0;
		if(player CanAfford(cost)){
			if(cost>0) player playLocalSound("cha_ching");
			return player;
		}else{
			player playLocalSound("no_cha_ching");
			wait(.1);
			continue;
		}
		wait(.1);
	}
}

ProgressBars(timer, knuckle, deleteit){
/*	timer = optional, int or float for time to finish progress bar
	knuckle = optional, boolean to have knuckle crack during or not
	deleteit = optional, delete this trigger when done, boolean, default deletes it

	Requires: knuckle_crack() and #include maps\_hud_util;
	Displays a progress bar while player is holding use button until time is up, notifies
	stop_building when progress bar is done, used for knuckle crack timer

	Calls:
		trig ProgressBars();
		trig ProgressBars(timer);
		trig ProgressBars(timer, knuckle);
		trig ProgressBars(timer, knuckle, deleteit);
*/
	if(!IsDefined( self )) return false;
	if(!isDefined(timer)) timer=3;
	constTime = timer;
	player = undefined;
	while(timer>0){
		self waittill("trigger", player);
		if(!is_player_valid( player )) return false;
		if(isDefined(knuckle) && knuckle){
			player thread knuckle_crack();
			while(player GetCurrentWeapon() != "zombie_knuckle_crack") wait(.1);
		}
		player.PBar = player CreatePrimaryProgressBar();
		player.PBar.color = ( .5, 1, 1 );
		player.PBar UpdateBar( 0.01, 1/constTime );
		while(player UseButtonPressed() && distance(player.origin, self.origin)<100 && player isOnGround() && !player maps\_laststand::player_is_in_laststand() && timer>0){
			wait(.1);
			timer = timer-.1;
		}
		player notify("stopped_building");
		player.PBar destroyElem();
		player.PBar = undefined;
	}
	if(!IsDefined( deleteit ) || deleteit) self delete();
}

knuckle_crack(){// self is player
/*	no vars

	Requires: AllowMoving(cond) and zombie_knuckle_crack
	Cracks players knuckles, checks if has deathmachine before giving back last weapon

	Calls:
		player thread knuckle_crack();

*/
	if(is_player_valid( self )) return;
	self DisableOffhandWeapons();
	self AllowMoving(false);
	if( self GetStance() == "prone" ) self SetStance("crouch");
	gun = self GetCurrentWeapon();
	self GiveWeapon( "zombie_knuckle_crack" );
	self SwitchToWeapon( "zombie_knuckle_crack" );
	self waittill_any( "fake_death", "death", "player_downed", "stopped_building", "weapon_change_complete");
	self EnableOffhandWeapons();
	if(self GetCurrentWeapon()=="zombie_knuckle_crack" && IsSubStr( gun,"deathmachine" ) && (self !HasWeapon( "deathmachine" ) && self !HasWeapon( "deathmachine_upgraded" ))) self SwitchToWeapon( self GetWeaponsListPrimaries()[0] );
	if(self GetCurrentWeapon()=="zombie_knuckle_crack" && is_player_valid(self)) self SwitchToWeapon( gun );
	self TakeWeapon( "zombie_knuckle_crack" );
	self AllowMoving(true);
}

AllowMoving(cond){//true to allow moving, false to not allow moving
/*	cond = true or false, true will allow moving, false will prevent it

*/
	self AllowLean(cond);
	self AllowAds(cond);
	self AllowSprint(cond);
	self AllowProne(cond);		
	self AllowMelee(cond);
}

GiveMaxAmmo(){
/*	no vars

	Calls:
	ammoTrigs = GetEntArray("ammo_trigs", "targetname");//get the array of triggers to buy max ammo
		array_thread(ammoTrigs, ::GiveMaxAmmo);//get array of triggers called ammoTrigs
*/
	self UseTriggerRequireLookAt();
	self SetCursorHint( "HINT_NOICON" );
	flag_wait( "electricity_on" );//comment out if you do not want power on first
	cost = 500;
	if(IsDefined( self.zombie_cost )) cost = self.zombie_cost;
	self SetHintString( "Press &&1 to buy ammo [Cost: " + cost + "]" );
	while(1)
	{
		self waittill("trigger",player);
		if(player.score+5<cost) continue;
		if(! maps\_zombiemode_utility::is_player_valid(player)) continue;
		gun = player GetCurrentWeapon();
		if(player GetWeaponAmmoStock( gun )>= WeaponStartAmmo( gun )) continue;
		if(WeaponClass( gun ) == "grenade"||gun == "none") continue;
		player maps\_zombiemode_score::minus_to_player_score( cost );
		player GiveStartAmmo(gun);
		wait(.01);
	}
}

GivePap(cost){
/*	cost = optional, cost of pap

	Requires: CanAfford(cost, subscore), MyWaitTillTrig(cost)
	Gives the player a papped version of the current gun from a trigger_use

	Calls:
	papTrigs = GetEntArray("pap_trigs", "targetname");//get the array of triggers to buy pap
		array_thread(papTrigs, ::GivePap);//get array of triggers called papTrigs
	trig = getent("papTrig", "targetname");//if only on trigger on map with this targetname does it
		trig thread GivePap();

*/
	self UseTriggerRequireLookAt();
	self SetCursorHint( "HINT_NOICON" );
	flag_wait( "electricity_on" );
	self SetHintString( &"ZOMBIE_PERK_PACKAPUNCH" );
	if(!IsDefined( cost ) && IsDefined( self.zombie_cost )) cost = self.zombie_cost;
	if(!IsDefined( cost )) cost = 5000;
	self SetHintString( "Press &&1 for pack-a-punch. Cost[" + cost + "]" );
	while(1){
		gun = undefined;
		player = self MyWaitTillTrig(cost);
		if(!is_player_valid( player )) gun = "none";
		else gun = player GetCurrentWeapon();
		if(!IsDefined( gun ) || gun == "none" || !IsDefined( level.zombie_include_weapons[gun + "_upgraded"]) || WeaponClass( gun ) == "grenade"){
			wait(.1);
			continue;
		}
		if(player CanAfford(cost)){
			player GiveWeapon(gun+"_upgraded");
			player TakeWeapon( gun );
			player SwitchToWeapon(gun+"_upgraded");
			player GiveStartAmmo(gun+"_upgraded");
		}
		wait(.1);
	}
}

/*
--- Status functions ---
In any function add:
iprinln("ent-string-array description", ObjStatus(ent-string-array,kvp0,kvp1,kvp2,kvp3,kvp4));
 - only use kvps if you want to check kvps of object

Example:
testarray = getentarray("initial_spawn_points", "targetname");
iprintln("test array",ObjStatus(testarray));//should print "test array is an array of: 4"
iprintln("0th ent of array", ObjStatus(testarray[0],"origin", "angles"));//should print "0th ent of array, origin (# # #), angles (# # #)"
*/
ObjStatus(obj, kvp0, kvp1, kvp2, kvp3, kvp4){
	if(!IsDefined( obj )) return " is not defined";
	if(IsArray( obj ) && IsDefined( obj.size )) return " is an array of: " + obj.size;
	if(IsString( obj )) return " is a string: " ;
	stat = " is defined";
	stat = stat+Stats(obj,kvp0);
	stat = stat+Stats(obj,kvp1);
	stat = stat+Stats(obj,kvp2);
	stat = stat+Stats(obj,kvp3);
	stat = stat+Stats(obj,kvp4);
	return stat;
}

Stats(obj,stat){
	if(IsDefined( obj ) && IsDefined( stat )){
		switch(stat){
			case "origin":
				if(IsDefined( obj.origin )) return ", origin: " + obj.origin;
				else return " no origin";
			case "angles":
				if(IsDefined( obj.angles )) return ", angles: " + obj.angles;
				else return " no angles";
			case "script_noteworthy":
				if(IsDefined( obj.script_noteworthy )) return ", script_noteworthy: " + obj.script_noteworthy;
				else return " no script_noteworthy";
			case "targetname":
				if(IsDefined( obj.targetname )) return ", targetname: " + obj.targetname;
				else return " no targetname";
			case "target":
				if(IsDefined( obj.target )) return ", target: " + obj.target;
				else return " no target";
			case "script_string":
				if(IsDefined( obj.script_string )) return ", script_string: " + obj.script_string;
				else return " no script_string";
			case "script_fxid":
				if(IsDefined( obj.script_fxid )) return ", script_fxid: " + obj.script_fxid;
				else return " no script_fxid";
			case "speed":
				if(IsDefined( obj.speed )) return ", speed: " + obj.speed;
				else return " no speed";
			case "xyz":
				xyzStats = "";
				xyz = [];
				xyz[0] = ", (x: ";
				xyz[1] = " y: ";
				xyz[2] = " z: )";
				for(i=0;i<3;i++){
					if(IsDefined( obj.origin ) && IsDefined( obj.origin[i] )) xyzStats = xyzStats + xyz[i] + obj.origin[i];
					else xyzStats=xyzStats + xyz[i] + "error";
				}
				return xyzStats;
			// case "your kvp added here":
			// 	if(IsDefined( obj.your kvp added here )) return ", your kvp added here: " + obj.your kvp added here;
			// 	else return " no your kvp added here";
			default:
				return ", kvp not defined in Stats function";
		}
	}
	if(IsDefined( obj )) return "";
	return ", object no longer defined";
}


//Fire Damage
FireInit(){
	level.firedamage = 50;//change for damage for fire
	fire = GetEntArray( "fire","targetname" );//trigger multiples with targetname fire
	array_thread( fire,::FireBad );
}
FireBad(){
	damageDelay = .5;
	while(1) {
	    self waittill("trigger", who);
	    if(!IsPlayer( who )){
	    	who DoDamage( level.firedamage, self.origin);
	    	// who thread animscripts\death::flame_death_fx();//could do something to set zombies on fire
	    }else{
	    	if(is_player_valid( who ){
				if(who.health > level.firedamage+1){
					who dodamage( level.firedamage, self.origin );
					who SetBurn( damageDelay );
				}else{
					RadiusDamage( who.origin, 50, level.firedamage, level.firedamage );
				}
		    }
	    } 
	   wait(damageDelay);
	}
}
	
