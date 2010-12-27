//
//  PPCoords.mm
//  Pocket-Pather
//
//  Created by Joonas Trussmann on 12/26/10.
//

#import "PPCoords.h"


@implementation PPCoords

@synthesize x,y,z;

-(id)initWithX:(float)_x Y:(float)_y Z:(float)_z {
	self = [super init];
	if(self) {
		self.x = _x;
		self.y = _y;
		self.z = _z;
	}
	return self;
}
-(id)initWithPGX:(float)_x Y:(float)_y Z:(float)_z {
	self = [super init];
	if(self) {
		self.pgX = _x;
		self.pgY = _y;
		self.pgZ = _z;
	}
	return self;
}

-(NSString *)tile {
	return [NSString stringWithFormat:@"%d_%d", 
			floor(32.0-(self.pgX/533.33333)),
			floor(32.0-(self.pgY/533.33333)), 
			nil];
}

-(NSDictionary *)pgDict {
	return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithFloat:self.pgX], @"x",
				[NSNumber numberWithFloat:self.pgY], @"y",
				[NSNumber numberWithFloat:self.pgZ], @"z",
			    nil];
}

-(void)setPgX:(float)val {
	self.z = -val;
}
-(float)pgX {
	return -self.z;
}
-(void)setPgY:(float)val {
	self.x = -val;
}
-(float)pgY {
	return -self.x;
}
-(void)setPgZ:(float)val {
	self.y = val;
}
-(float)pgZ {
	return self.y;
}

/* for refrence in case i fucked up the property methods
inline PPCoords PGCoordsToNavmesh(PPCoords coords) {
	
	PPCoords res;
	res.x = -coords[1];
	res.y = coords[2];
	res.z = -coords[0];
	
	return res;
}
inline PPCoords navmeshCoordsToPG(PPCoords coords) {
	
	PPCoords res;
	res.x = -coords[2];
	res.y = -coords[0];
	res.z = coords[1];

}
inline void PGCoordsToADT(float coords[]) {
 int res[2];
 res[0] = floor(32.0-(coords[0]/533.33333));
 res[1] = floor(32.0-(coords[1]/533.33333));
 return res;
 }
 
*/
 

@end
