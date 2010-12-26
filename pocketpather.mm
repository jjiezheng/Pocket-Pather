#import <Cocoa/Cocoa.h>
#import <objc/objc-auto.h>

#import "WorldMeshDumper.h"
#import "PPNavmeshQuery.h"

int main( int argc, char **argv ) {
	objc_startCollectorThread();
	
	NSAutoreleasePool *autoReleasePool = [[NSAutoreleasePool alloc] init];

	//WorldMeshDumper *dumper = [[WorldMeshDumper alloc] initWithDataPath:@"/Applications/World of Warcraft/Data"];
	//[dumper dump:@"world\\maps\\Kalimdor\\Kalimdor" withZoneId:440];
	
	PPNavmeshQuery *navQuery = [[PPNavmeshQuery alloc] initWithNavmesh:@"all_tiles_navmesh.bin"];
	
	//Use initWithPGX Y Z instead ;)
	PPCoords *start = [[PPCoords alloc] initWithX:4732.1665 Y:9.67551422 Z:-397.981598];
	PPCoords *end = [[PPCoords alloc] initWithX:4620.11768 Y:46.175499 Z:-359.786194];
	NSArray *wayPoints = [navQuery routeFrom:start to:end];
	
	if(wayPoints == nil)
		return 1;
	
	NSMutableArray *arrOut = [NSMutableArray arrayWithCapacity:[wayPoints count]];
	for(PPCoords *wp in wayPoints) {
		[arrOut addObject:wp.pgDict];
	}
	[arrOut writeToURL:[NSURL fileURLWithPath:@"testroute.plist"] atomically:NO];
	
	[autoReleasePool release];
	
	return 0;
}
