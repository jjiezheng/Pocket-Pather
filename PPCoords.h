//
//  PPCoords.h
//  Pocket-Pather
//
//  Created by Joonas Trussmann on 12/26/10.
//

#import <Cocoa/Cocoa.h>


@interface PPCoords : NSObject {
	float x;
	float y;
	float z;
}

-(id)initWithX:(float)_x Y:(float)_y Z:(float)_z;
-(id)initWithPGX:(float)_x Y:(float)_y Z:(float)_z;

@property(readonly) NSString *tile;
@property(readonly) NSDictionary *pgDict;

@property(nonatomic, assign) float x;
@property(nonatomic, assign) float y;
@property(nonatomic, assign) float z;

@property(nonatomic, assign) float pgX;
@property(nonatomic, assign) float pgY;
@property(nonatomic, assign) float pgZ;

@end
