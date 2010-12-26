#import "WorldMeshDumper.h"
#import <objc/objc-auto.h>

int main( int arch, char **argv ) {
	//dumpMeshes("/Applications/World of Warcraft/Data", "world\\maps\\Kalimdor\\Kalimdor", 440);
	//calculateRoute();
	objc_startCollectorThread();
	
	NSAutoreleasePool *autoReleasePool = [[NSAutoreleasePool alloc] init];

	WorldMeshDumper *dumper = [[WorldMeshDumper alloc] initWithDataPath:@"/Applications/World of Warcraft/Data"];
	[dumper dump:@"world\\maps\\Kalimdor\\Kalimdor" withZoneId:440];
	
	[autoReleasePool release];
	
	return 0;
}
