//Enum for the Status
abstract sig Status {}
one sig OPTIMAL extends Status {}
one sig MEDIUM extends Status {}
one sig SUFFICIENT extends Status {}
one sig REQUIRES_MAINTENACE extends Status {}
one sig BLOCKED extends Status {}

//Enum for Boolean
abstract sig Boolean {}
one sig TRUE extends Boolean {}
one sig FALSE extends Boolean {}

sig Coordinate {} 
 
/*
* An Obstacle can be present on a crossroad --> on multiple streets at the same time
*/
sig Obstacle { 
	var on: set Street,
	var coord: lone Coordinate
} 

sig Street {
	var partOf: set BikePath,
	var status : one Status
} {
	#partOf > 0
}


sig BikePath{
	var isPublic: one Boolean,
	var score: lone Int,
	startingPoint: one Coordinate,
	endingPoint: one Coordinate,
	var createdBy: lone User
} {
	endingPoint != startingPoint
	isPublic = TRUE iff score != none
}

sig MeteoData {
	
}

sig Record {
	belongsTo: one User,
	recordedOn: one BikePath,
	associatedTo : lone MeteoData
}

var sig DeletedRecord in Record {}


sig User{
	var isRegistered : one Boolean
} 


//--

//A meteoData is always associated to a record
fact MeteoDataConsistency {
	always (all m: MeteoData | #m.~associatedTo != 0)
}

fact ObstacleConsistency {
	always (all o: Obstacle | o.on != none iff o.coord != none)
}


//Once a Record is deleated it cannot be recovered
fact {
	always (all r: Record | r in DeletedRecord implies after always r in DeletedRecord)
}

//Record associated to a DeletedUser, i.e. an user that is not Registered, are also eliminated
fact RecordConsistency {
	always (all r: Record | r.belongsTo.isRegistered = FALSE implies r in DeletedRecord)
}

//the set of BikePaths of which a road is part can only increase 
fact {
	always (all s: Street | s.partOf in s.partOf')
}

//every BikePath is composed of at least one street
fact BikePathConsistency1 {
	always (all b: BikePath | #b.~partOf > 0)
}

//Once the creator of a BikePath delete its account the BikePath will lose forever its creator
fact BikePathConsistency2 {
	always (all b: BikePath | b.createdBy = none implies always b.createdBy = none)
	always (all b: BikePath, u: User | u.isRegistered = TRUE and u in b.createdBy and u.isRegistered' = FALSE implies b.createdBy' = none)
}

//Cannot be present private BikePath for non registered users
fact BikePathConsistency3 {
    always (all b: BikePath, u: User |
        (b.isPublic = FALSE and u in b.createdBy) implies u.isRegistered = TRUE
    )
}

//Once a BikePath is public it remains public
fact BikePathConsistency4 {
	always (all b: BikePath | b.isPublic = TRUE implies after always b.isPublic = TRUE)
}

//No unRegistered User can be the creator of a BikePath
fact BikePathConsistency5 {
	always (no u: User | some b: BikePath | u.isRegistered = FALSE and u in b.createdBy)
}

//A BikePath, if private, can only be in a Record associated to its owner
fact RecordConsistency {
	always (all r: Record, b: BikePath | b.isPublic = FALSE implies b.createdBy = r.belongsTo)
}



//A street with Obstacles can never be in OPTIMAL status
fact StreetConsistency {
	always (all s: Street | #s.~on > 0 implies s.status != OPTIMAL)
}

//The score changes olnly when:
//The state of a street that compose the path change
//The path is published
fact ScoreChange {
	always (all s: Street, b: BikePath |
			b in s.partOf and s.status = s.status' and b.isPublic = b.isPublic'implies b.score = b.score')
}


//--

pred removeObstacle[o: Obstacle] {
	o.on = none
}

pred SigUp[u: User] {
	u.isRegistered = TRUE
}

pred deleteAccount[u: User] {
	u.isRegistered = FALSE
}

pred deleteRecord[r: Record] {
	r in DeletedRecord
}

pred receiveMaintenance[s: Street] {
	s.status' = OPTIMAL
}

//Scenarios

pred firstScenario {
	some o: Obstacle, s: Street | {
		s not in o.on and after {
			s in o.on and after {
				removeObstacle[o]
			}
		}
	}
}

pred secondScenario {
	some u: User, b: BikePath | {
		u in b.createdBy and b.isPublic = FALSE and after {
			b.isPublic = TRUE
		}
	}
}

pred thirdScenario {
	some u: User, r: Record | {
		u.isRegistered = TRUE and r.belongsTo in u and r.recordedOn.isPublic = TRUE and r not in DeletedRecord 
		and after {
			u.isRegistered = FALSE and after {
				u.isRegistered = TRUE
			}
		} 
	}
}

pred fourthScenario {
	some u: User, b: BikePath | {
		u in b.createdBy and b.isPublic = FALSE and after {
			u in b.createdBy and b.isPublic = TRUE and after {
				u.isRegistered = FALSE
			}
		}
	}
}

//run fourthScenario for 3 but 1 User, 1 BikePath, 0 Record

//run thirdScenario for 3 but 1 User, 1 Record, 1 BikePath

//run secondScenario for 2 but 1 BikePath, 1 User,  0 Record

//run firstScenario for 3 but 1 Street, 1 BikePath, 1 Obstacle, 0 Record


/*
* If a Record is non-deleted and the owner is not 
* the creator of the BikePath than the BikePath must be public
*/
assert CanAccessOnlyPublicPath {
    always (all r: Record | r not in DeletedRecord and r.belongsTo != r.recordedOn.createdBy
        implies
			r.recordedOn.isPublic = TRUE)
}
//check CanAccessOnlyPublicPath


/*
* An unregistered user cannot have non-deleted records associated to them
*/
assert NoExistingRecordsForDeletedUser {
	no r: Record | r not in DeletedRecord and r.belongsTo.isRegistered = FALSE
}
//check NoExistingRecordsForDeletedUser



//A deleted user can have deleted records? 
pred FifthScenario {
	some u: User, r: Record | r in DeletedRecord and u.isRegistered = FALSE and u in r.belongsTo
}
//run FifthScenario


