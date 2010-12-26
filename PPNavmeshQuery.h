//
//  PPNavmeshQuery.h
//  Pocket-Pather
//
//  Created by Joonas Trussmann on 12/26/10.
//  Copyright 2010 Finestmedia OÜ. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PPCoords.h"

#import "DetourNavMesh.h"
#import "DetourNavMeshQuery.h"



@interface PPNavmeshQuery : NSObject {
	dtNavMesh *navMesh;
}

-(id)initWithNavmesh:(NSString *)navMeshPath;
-(NSArray *)routeFrom:(PPCoords *)start to:(PPCoords *)end;

+(dtNavMesh*) getNavMesh:(NSString *)navMeshPath;

@end
