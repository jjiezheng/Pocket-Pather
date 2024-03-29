/*
 *  meshandler.h
 *  Pocket-Pather
 *
 *  Created by Joonas Trussmann on 12/24/10.
 *  Copyright 2010 Finestmedia OÜ. All rights reserved.
 *
 */


#define _USE_MATH_DEFINES
#include <math.h>
#include <stdio.h>
#include <string.h>
#import "DetourNavMesh.h"
#import "DetourNavMeshQuery.h"



inline void PGCoordsToNavmesh(float coords[3]) {
	
	float x, y, z;
	
	x = -coords[1];
	y = coords[2];
	z = -coords[0];
	
	coords[0] = x;
	coords[1] = y;
	coords[2] = z;
	
}
inline void navmeshCoordsToPG(float coords[3]) {
	float x, y, z;
	
	x = -coords[2];
	y = -coords[0];
	z = coords[1];
	
	coords[0] = x;
	coords[1] = y;
	coords[2] = z;	
	
}
//i hate C++
/*inline void PGCoordsToADT(float coords[]) {
	int res[2];
	res[0] = floor(32.0-(coords[0]/533.33333));
	res[1] = floor(32.0-(coords[1]/533.33333));
	return res;
}*/

inline void calculateRoute () {
	
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
	
	m_spos[0] = 4732.1665;
	m_spos[1] = 9.67551422;
	m_spos[2] = -397.981598;
	
	m_epos[0] = 4620.11768;
	m_epos[1] = 46.175499;
	m_epos[2] = -359.786194;
	
	
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
	m_navQuery->init(getNavMesh("all_tiles_navmesh.bin"), 2048);
	
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
	
	printf("n straight path: %d\n", m_nstraightPath);

	NSMutableArray *routeArr = [NSMutableArray arrayWithCapacity:m_nstraightPath];
	for (int i = 0; i < m_nstraightPath-1; ++i) {
		float coords[3];
		coords[0] = m_straightPath[i*3];
		coords[1] = m_straightPath[i*3+1];
		coords[2] = m_straightPath[i*3+2];
		navmeshCoordsToPG(coords);
		[routeArr addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithFloat:coords[0]], @"x",
							 [NSNumber numberWithFloat:coords[1]], @"y",
							 [NSNumber numberWithFloat:coords[2]], @"z",
							 nil
		]];
		
		
		printf("%f, %f, %f\n", coords[0], coords[1], coords[2]);
	}
	[routeArr writeToURL:[NSURL fileURLWithPath:@"testroute.plist"] atomically:NO];
	
}


