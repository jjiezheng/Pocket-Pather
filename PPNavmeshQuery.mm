//
//  PPNavmeshQuery.m
//  Pocket-Pather
//
//  Created by Joonas Trussmann on 12/26/10.
//

#import "PPNavmeshQuery.h"

#define _USE_MATH_DEFINES
#include <math.h>
#include <stdio.h>
#include <string.h>


struct NavMeshSetHeader
{
	int magic;
	int version;
	int numTiles;
	dtNavMeshParams params;
};

struct NavMeshTileHeader
{
	dtTileRef tileRef;
	int dataSize;
};
static const int NAVMESHSET_MAGIC = 'M'<<24 | 'S'<<16 | 'E'<<8 | 'T'; //'MSET';
static const int NAVMESHSET_VERSION = 1;


@implementation PPNavmeshQuery

-(id)initWithNavmesh:(NSString *)navMeshPath {
	self = [super init];
	if(self) {
		navMesh = [PPNavmeshQuery getNavMesh:navMeshPath];
	}
	
	return self;
}

+(dtNavMesh*) getNavMesh:(NSString *)navMeshPath {
	const char* path = [navMeshPath cString];
	FILE* fp = fopen(path, "rb");
	if (!fp) return 0;
	
	// Read header.
	NavMeshSetHeader header;
	fread(&header, sizeof(NavMeshSetHeader), 1, fp);
	if (header.magic != NAVMESHSET_MAGIC)
	{
		fclose(fp);
		return 0;
	}
	if (header.version != NAVMESHSET_VERSION)
	{
		fclose(fp);
		return 0;
	}
	
	dtNavMesh* mesh = dtAllocNavMesh();
	if (!mesh)
	{
		fclose(fp);
		return 0;
	}
	dtStatus status = mesh->init(&header.params);
	if (dtStatusFailed(status))
	{
		fclose(fp);
		return 0;
	}
	
	// Read tiles.
	for (int i = 0; i < header.numTiles; ++i)
	{
		NavMeshTileHeader tileHeader;
		fread(&tileHeader, sizeof(tileHeader), 1, fp);
		if (!tileHeader.tileRef || !tileHeader.dataSize)
			break;
		
		unsigned char* data = (unsigned char*)dtAlloc(tileHeader.dataSize, DT_ALLOC_PERM);
		if (!data) break;
		memset(data, 0, tileHeader.dataSize);
		fread(data, tileHeader.dataSize, 1, fp);
		
		mesh->addTile(data, tileHeader.dataSize, DT_TILE_FREE_DATA, tileHeader.tileRef, 0);
	}
	
	fclose(fp);
	
	return mesh;
}

-(NSArray *)routeFrom:(PPCoords *)start to:(PPCoords *)end {
	
	if(navMesh == nil) 
		return nil;
	
	static const int MAX_POLYS = 256;
	
	//mesh querier
	class dtNavMeshQuery* m_navQuery;
	m_navQuery = dtAllocNavMeshQuery();;
	
	dtQueryFilter m_filter = dtQueryFilter();
	m_filter.setIncludeFlags(0xffff);
	m_filter.setExcludeFlags(0);
	
	//poly refs required for route calculation
	dtPolyRef m_startRef; 
	dtPolyRef m_endRef; 
	
	//starting and ending position xyz ?
	float m_spos[3];
	float m_epos[3];
	
	m_spos[0] = start.x;
	m_spos[1] = start.y;
	m_spos[2] = start.z;

	m_epos[0] = end.x;
	m_epos[1] = end.y;
	m_epos[2] = end.z;
	
	
	//number of points in our straight path?
	int m_nstraightPath = 0;
	
	//final path
	float m_straightPath[MAX_POLYS*3];
	
	//no fucking clue
	float m_polyPickExt[3];
	m_polyPickExt[0] = 2;
	m_polyPickExt[1] = 4;
	m_polyPickExt[2] = 2;
	
	//swim, jump, door? not really applicable
	unsigned char m_straightPathFlags[MAX_POLYS];
	
	//the navmesh polys that are used for the path?
	dtPolyRef m_straightPathPolys[MAX_POLYS];
	
	dtPolyRef m_polys[MAX_POLYS];
	
	
	//get the nav mesh and init a query object
	m_navQuery->init(navMesh, 2048);
	
	//required for findPath
	m_navQuery->findNearestPoly(m_spos, m_polyPickExt, &m_filter, &m_startRef, 0);
	m_navQuery->findNearestPoly(m_epos, m_polyPickExt, &m_filter, &m_endRef, 0);
	
	int m_npolys = 0;
	
	//fuck if i know, this is how it's done in the example :)
	m_navQuery->findPath(m_startRef, m_endRef, m_spos, m_epos, &m_filter, m_polys, &m_npolys, MAX_POLYS);
	
	//find that fucker
	m_navQuery->findStraightPath(m_spos, m_epos, m_polys, m_npolys,
							 m_straightPath, m_straightPathFlags,
							 m_straightPathPolys, &m_nstraightPath, MAX_POLYS);

	if(m_nstraightPath < 2)
		return nil;
	
	NSMutableArray *routeArr = [NSMutableArray arrayWithCapacity:m_nstraightPath];
	for (int i = 0; i < m_nstraightPath-1; ++i) {
		
		[routeArr addObject:[[PPCoords alloc] initWithX: m_straightPath[i*3] Y: m_straightPath[i*3+1] Z: m_straightPath[i*3+2]]];
	
	}
	return (NSArray *)routeArr;
}

@end
