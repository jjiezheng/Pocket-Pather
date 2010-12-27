//
//  WorldMeshDumper.h
//  Pocket-Pather
//
//  Created by Joonas Trussmann on 12/26/10.
//

#import <Cocoa/Cocoa.h>

#include "mpqhandler.h"
#include "wdt.h"
#include "adt.h"
#include "obj0.h"
#include "m2.h"
#include "wmomodel.h"

#ifndef MESH_POINTER_STRUCT
#define MESH_POINTER_STRUCT

struct MeshPointers {
	Indices32_t *indices;
	Vertices_t *vertices;
	Normals_t *normals;
};

#endif

@interface WorldMeshDumper : NSObject {
	MpqHandler *mpq_h;
	bool dumpAll;
		
	//wut?
	UidMap_t uid_map;
	BufferS_t adt_buf, obj_buf;
}

-(id)initWithDataPath:(NSString *)_path;

-(void)dump:(NSString *)wdtPath withZoneId:(uint32_t)zoneId;

/* stolen from mmowned */
-(void)loadAllMpqs;
-(void)loadMpq:(NSString*)fileName;
-(bool)loadAdt:(NSString *)fileName adtBuffer:(BufferS_t *)adt_buf objectBuffer:(BufferS_t *)obj_buf;
-(void)loadObjectReferences:(Obj0 *)obj0 withMeshPointers:(MeshPointers)meshPointers;

-(void)getCoordsByAreaId:(uint32_t)area_id withOriginalCoords:(const AdtCoords_t *)original_coords andZonePath:(NSString *)zonePath
			   andCoords:(AdtCoords_t *)coords andX:(uint32_t)x andY:(uint32_t)y;

-(bool)doodadGemometryFor:(NSString *)doodad_name withMeshPointers:(MeshPointers)meshPointers;


@end
