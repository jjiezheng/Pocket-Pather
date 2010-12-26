//
//  WorldMeshDumper.mm
//  Pocket-Pather
//
//  Created by Joonas Trussmann on 12/26/10.
//  Copyright 2010 Finestmedia OÜ. All rights reserved.
//

#import "WorldMeshDumper.h"


//for mkdir
#include <sys/stat.h>
#include <sys/types.h>

@implementation WorldMeshDumper

-(id)initWithDataPath:(NSString *)_path {
	self = [super init];
	if(self) {
		mpq_h = new MpqHandler( std::string([_path cString]) );
		
		dumpAll = NO;
	}
	
	return self;
}

-(void)dump:(NSString *)wdtPath withZoneId:(uint32_t)areaId {
	[self loadAllMpqs];
	
	// load WDT file which tells us what ADT tiles to load
	BufferS_t file_buffer;
	std::string zone_path( [wdtPath cString] );
	mpq_h->getFile( zone_path + ".wdt", &file_buffer );
	
	// Others Option
	//uint32_t areaId = 14;
	uint32_t xTile = -1;
	uint32_t yTile = -1;
	dumpAll = (areaId == -1);
	bool saveTile = true; // Save to .obj file
	
	// create geometry buffer
	Vertices_t vertices;
	Indices32_t indices;
	Normals_t normals;
	
	// parse WDT files
	Wdt *wdt = new Wdt( file_buffer );
	
	// GET COORDS BY AREA ID! AREA ID -> 12 (Elwynn Forrest), 14 (Durotar)
	AdtCoords_t coords;
	[self getCoordsByAreaId:areaId withOriginalCoords:&wdt->getAdtCoords() andZonePath:wdtPath andCoords:&coords andX:xTile andY:yTile];
	
	if ( coords.size() <= 0 ) {
		std::cout << "Zone not found." << std::endl;
		return;
	}
	
	mkdir("dump", 0777);
	
	// load found areas and get geometry
	for ( AdtCoords_t::const_iterator iter = coords.begin();
		 iter != coords.end();
		 ++iter ) {
		// clear buffers
		adt_buf.clear();
		obj_buf.clear();
		// create file string
		std::stringstream adt_ss;
		adt_ss << zone_path << "_" << iter->x << "_" << iter->y;
		
		// load adt and obj files from mpq
		[self loadAdt:[NSString stringWithCString:adt_ss.str().c_str()] adtBuffer:&adt_buf objectBuffer:&obj_buf];
		//--loadAdt( mpq_h, adt_ss.str(), &adt_buf, &obj_buf );
		Adt adt( adt_buf );
		
		// get terrain geometry
		if (saveTile)
		{
			vertices.clear();
			indices.clear();
			normals.clear();
		}
		const AdtTerrain_t &adt_terr = adt.getTerrain();
		for ( AdtTerrain_t::const_iterator terr = adt_terr.begin();
			 terr != adt_terr.end();
			 ++terr ) {
			mergeIndices( terr->indices, vertices.size(), &indices );
			mergeVertices( terr->vertices, &vertices );
			mergeNormals( terr->normals, &normals );
		}
		
		// parse object references
		if ( obj_buf.size() ) {
			Obj0 obj0( obj_buf );
			MeshPointers meshPointers;
			meshPointers.indices = &indices;
			meshPointers.vertices = &vertices;
			meshPointers.normals = &normals;
			[self loadObjectReferences:&obj0 withMeshPointers:meshPointers];
			//--loadObjectReferences( mpq_h, obj0, &indices, &vertices, &normals );
		}
		
		if (saveTile)
		{
			// Save to .obj
			std::stringstream fileName;
			fileName.clear();
			fileName << "dump/" << iter->y << "_" << iter->x << ".obj";
			std::cout << "Save to \"" << fileName.str() << "\" file." << std::endl;
			
			std::fstream fs1((const char*)(fileName.str().c_str()), std::fstream::out|std::fstream::binary);
			for (int i = 0; i < vertices.size(); i++)
			{
				fs1 << "v " << (vertices[i].x) << ' ' << vertices[i].y << ' ' << (vertices[i].z) << '\n';
			}
			for (int i = 0; i < indices.size();)
			{
				fs1 << "f " << indices[i++]+1;
				fs1 << ' ' << indices[i++]+1;
				fs1 << ' ' << indices[i++]+1 << '\n';
			}
		}
	}
	
	std::cout << "Finished" << std::endl;
	std::cin ;
	
}

-(void)loadAllMpqs {
	[self loadMpq:@"wow-update-13329.MPQ"];
	[self loadMpq:@"wow-update-13205.MPQ"];
	[self loadMpq:@"wow-update-13164.MPQ"];
	[self loadMpq:@"expansion3.MPQ"];
	[self loadMpq:@"expansion2.MPQ"];
	[self loadMpq:@"expansion1.MPQ"];
	[self loadMpq:@"world.MPQ"];
	[self loadMpq:@"art.MPQ"];
	
}
-(void)loadMpq:(NSString*)_fileName {
	NSLog(@"loading mpq: %@", _fileName);
	mpq_h->addFile( std::string([_fileName cString] ));
}
-(bool)loadAdt:(NSString *)_fileName adtBuffer:(BufferS_t *)adt_buf objectBuffer:(BufferS_t *)obj_buf {
	std::string adt_str = std::string([_fileName cString]) + std::string( ".adt" );
	std::string obj_str = std::string([_fileName cString]) + std::string( "_obj0.adt" );
	
	return mpq_h->getFile( adt_str, adt_buf ) && mpq_h->getFile( obj_str, obj_buf );
}
-(void)loadObjectReferences:(Obj0 *)obj0 withMeshPointers:(MeshPointers)meshPointers {
	// get doodads/WMOs of ADT
	const ObjectReferences_t &obj_refs = obj0->getObjectRefs();
	for ( ObjectReferences_t::const_iterator ref = obj_refs.begin();
		 ref != obj_refs.end();
		 ++ref ) {
		// get unique doodads here, notice: you can speed things up if you buffer
		// already loaded objects here :)
		for ( int d = 0; d < ref->doodadIndices.size(); d++ ) {
			Doodad_s doodad;
			obj0->getDoodad( ref->doodadIndices[d], &doodad );
			
			// find unique identifier in map, only one uid can be present
			UidMap_t::iterator found = uid_map.find( doodad.info.uid );
			
			// unique identifier not found: insert UID in map
			if ( found == uid_map.end() ) {
				uid_map.insert( UidMap_t::value_type( doodad.info.uid, 0 ) );
				
				BufferS_t doodad_buf;
				mpq_h->getFile( doodad.name, &doodad_buf );
				
				// doodad buffers
				Indices32_t m2_i;
				Vertices_t m2_v;
				Normals_t m2_n;
				
				MeshPointers doodadMeshPointers;
				doodadMeshPointers.indices = &m2_i;
				doodadMeshPointers.vertices = &m2_v;
				doodadMeshPointers.normals = &m2_n;
				
				// if doodad geometry is present: transform and merge
				if( [self doodadGemometryFor:[NSString stringWithCString:doodad.name.c_str()] withMeshPointers:doodadMeshPointers] ) {
				//if ( getDoodadGeometry( mpq_h, doodad.name, &m2_i, &m2_v, &m2_n ) ) {
					// bring vertices to our coordinate system
					transformVertices( doodad.info.pos, doodad.info.rot,
									  doodad.info.scale / 1024, &m2_v ); 
					
					
					mergeIndices( m2_i, meshPointers.vertices->size(), meshPointers.indices );
					mergeVertices( m2_v, meshPointers.vertices );
					mergeNormals( m2_n, meshPointers.normals );
				}
			}
		}
		
		// get unique WMOs here, same thing as above: buffer -> +speed !
		for ( int d = 0; d < ref->wmoIndices.size(); d++ ) {
			uint32_t obj_index = ref->wmoIndices[d];
			// get wmo from object file
			Wmo_s wmo;
			obj0->getWmo( obj_index, &wmo );
			
			// find WMOs UID in our map
			UidMap_t::iterator found = uid_map.find( wmo.info.uid );
			
			// same procedure as above
			if ( found == uid_map.end() ) {
				uid_map.insert( UidMap_t::value_type( wmo.info.uid, 0 ) );
				
				BufferS_t wmo_buf;
				mpq_h->getFile( wmo.name, &wmo_buf );
				
				// parse wmo data
				WmoModel *wmo_model = new WmoModel( wmo_buf );
				wmo_model->loadGroups( wmo.name, *mpq_h );
				
				// wmo buffers
				Indices32_t wmo_i;
				Vertices_t wmo_v;
				Normals_t wmo_n;
				
				wmo_model->getIndices( &wmo_i );
				wmo_model->getVertices( &wmo_v );
				wmo_model->getNormals( &wmo_n );
				
				// bring vertices to our coordinate system
				const ModfChunk_s::WmoInfo_s &info = obj0->wmoInfo()[obj_index];
				transformVertices( info.pos, info.rot, 1.0f, &wmo_v );
				
				mergeIndices( wmo_i, meshPointers.vertices->size(), meshPointers.indices );
				mergeVertices( wmo_v, meshPointers.vertices );
				mergeNormals( wmo_n, meshPointers.normals );
				
				// get interior doodads for WMOs
				const ModnChunk_s &modn_chunk = wmo_model->getModnChunk();
				const ModdChunk_s::DoodadInformations_t &modd_infos = wmo_model->getModdChunk().infos;        
				for ( ModdChunk_s::DoodadInformations_t::const_iterator iter = modd_infos.begin();
					 iter != modd_infos.end();
					 ++iter ) {
					// doodad name
					std::string doodad_name( (const char*)&modn_chunk.doodadNames[iter->id] );
					doodad_name.replace( doodad_name.size() - 4, 4, ".M2" );
					BufferS_t doodad_buf;
					mpq_h->getFile( doodad_name, &doodad_buf );
					
					// load doodad if buffer has data
					if ( doodad_buf.size() ) {
						M2 m2( doodad_buf );
						
						Indices32_t m2_i;
						Vertices_t m2_v;
						Normals_t m2_n;
						
						m2.getBoundingIndices( &m2_i );
						m2.getBoundingVertices( &m2_v );
						m2.getBoundingNormals( &m2_n );
						
						// interior doodads have to be transformed by their parent WMO's
						// transformation first
						for ( int i = 0; i < m2_v.size(); i++ ) {
							glm::vec3 &vtx = m2_v[i];
							vtx = glm::rotate( iter->rotation, vtx ) * iter->scale + iter->position;
						}
						
						// now transform by 
						transformVertices( info.pos, info.rot, 1.0f, &m2_v );
						
						mergeIndices( m2_i, meshPointers.vertices->size(), meshPointers.indices );
						mergeVertices( m2_v, meshPointers.vertices );
						mergeNormals( m2_n, meshPointers.normals );
					}
				}
			}
		}
	}
}

-(void)getCoordsByAreaId:(uint32_t)area_id withOriginalCoords:(const AdtCoords_t *)original_coords andZonePath:(NSString *)zonePath
			   andCoords:(AdtCoords_t *)coords andX:(uint32_t)x andY:(uint32_t)y {
	
	int count = 0;
	for ( AdtCoords_t::const_iterator iter = original_coords->begin();
		 iter != original_coords->end();
		 ++iter ) {
		count++;
		//if ( count < 256 || count > 512 ) continue;
		
		// create file string
		std::stringstream adt_ss;
		adt_ss << [zonePath cString] << "_" << iter->x << "_" << iter->y;
		std::cout << count << " " << adt_ss.str();
		
		adt_buf.clear();
		obj_buf.clear();
		// loading obj files here is pointless, but it's a reused function so live with it :p
		[self loadAdt:[NSString stringWithCString:adt_ss.str().c_str()] adtBuffer:&adt_buf objectBuffer:&obj_buf];
		//--loadAdt( mpq_h, adt_ss.str(), &adt_buf, &obj_buf );
		
		Adt adt( adt_buf );
		const AdtTerrain_t &adt_terr = adt.getTerrain();
		for ( AdtTerrain_t::const_iterator terr = adt_terr.begin();
			 terr != adt_terr.end();
			 ++terr ) {
			if ( terr->areaId == area_id || dumpAll || x == iter->x && y == iter->y) {
				std::cout << " found area";
				coords->push_back( *iter );
				break;
			}
		}
		std::cout << std::endl;
	}
	
	
}

-(bool)doodadGemometryFor:(NSString *)doodad_name withMeshPointers:(MeshPointers)meshPointers {
	
	BufferS_t doodad_buf;
	mpq_h->getFile( [doodad_name cString], &doodad_buf );
	
	// load doodad if buffer has data
	if ( doodad_buf.size() ) {
		M2 m2( doodad_buf );
		
		// only get data if parameter is passed
		if ( meshPointers.indices ) {
			m2.getBoundingIndices( meshPointers.indices );
		}
		
		if ( meshPointers.vertices ) {
			m2.getBoundingVertices( meshPointers.vertices );
		}
		
		if ( meshPointers.normals ) {
			m2.getBoundingNormals( meshPointers.normals );
		}
		
		return true;
	}
	
	return false;
	
}

@end
