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
###############################################################################
*/

CanAfford(){//player = CanAfford();
    cost = 0;
    if(isDefined(self.zombie_cost)) cost = self.zombie_cost;
    player = undefined;
    for(;;){
        self waittill("trigger", player);
        if( player.score >= cost ){
            if(cost>0){ 
                player maps\_zombiemode_score::minus_to_player_score( cost );
                player playLocalSound( "cha_ching" ); 
            }
            return player;
        }else{
            player playLocalSound( "no_cha_ching" );
        }       
    }
}

isSprinting()//player isSprinting();
{
	velocity = self GetVelocity(); 
	// originHeight = self.origin[2] - 40;
	player_speed = abs(velocity[0]) + abs(velocity[1]); 
	if(player_speed > 225) return true;
	return false;
}

isFacing( facee, player )     // copied from _laststand.gsc and modified
{
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

GiveWeaponOrAmmo(gun){//gave = player GiveWeaponOrAmmo(nameofguntogive);
	if( gun == "none" || WeaponClass(gun) == "grenade" ) return "none";
	if(self HasWeapon(gun)){
		if(WeaponClass(gun) == "gas" ) return "none";
		self GiveStartAmmo(gun);
		return "ammo";
	}
	weapons = self GetWeaponsListPrimaries();
	maxguns = 2;
	if(self HasPerk("specialty_extraammo")) maxguns = 3;
	if(weapons.size >= maxguns) self TakeWeapon(self GetCurrentWeapon());
	self GiveWeapon(gun);
	self SwitchToWeapon(gun);
	self GiveStartAmmo(gun);
	return "gun";
}

MyWaitTillTrig(){//player = trigger MyWaitTillTrig();
	while(1){
		self waittill("trigger",player);
		if(isDefined(player.revivetrigger)) continue;
		if(isDefined(self.zombie_cost) && self.zombie_cost>0){
			if(player.score+5<self.zombie_cost){
				player playLocalSound("no_cha_ching");
				continue;
			}
		}
		return player;
		wait(.01);
	}
}

ProgressBars(timer, knuckle){//trig ProgressBars(3,1);
	if(!isDefined(timer)) timer=3;
	constTime = timer;
	player = undefined;
	while(timer>0){
		self waittill("trigger", player);
		if(isDefined(knuckle)) player thread do_knuckle_crack();
		gun = player GetCurrentWeapon(); 
		while(gun != "zombie_knuckle_crack"){
			gun = player GetCurrentWeapon();
			wait(.1);
		}
		player thread do_knuckle_crack();
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
	self delete();
}

do_knuckle_crack(){// self is player
	self DisableOffhandWeapons();
	self AllowMoving(false);
	if( self GetStance() == "prone" ) self SetStance("crouch");
	gun = self GetCurrentWeapon();
	self GiveWeapon( "zombie_knuckle_crack" );
	self SwitchToWeapon( "zombie_knuckle_crack" );
	self waittill_any( "fake_death", "death", "player_downed", "stopped_building", "weapon_change_complete");
	self EnableOffhandWeapons();
	if(self GetCurrentWeapon()=="zombie_knuckle_crack" && is_player_valid(self)) self SwitchToWeapon( gun );
	self TakeWeapon( "zombie_knuckle_crack" );
	self AllowMoving(true);
}

AllowMoving(cond){//true to allow moving, false to not allow moving
	self AllowLean(cond);
	self AllowAds(cond);
	self AllowSprint(cond);
	self AllowProne(cond);		
	self AllowMelee(cond);
