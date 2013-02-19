//
//  SMOpenStreetMapTileSource.m
//  iBike
//
//  Created by Ivan Pavlovic on 14/02/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMOpenStreetMapTileSource.h"

@implementation SMOpenStreetMapTileSource

- (id)init
{
	if (!(self = [super init]))
        return nil;
    
    self.minZoom = 1;
    self.maxZoom = 18;
    
	return self;
}

- (NSURL *)URLForTile:(RMTile)tile
{
	NSAssert4(((tile.zoom >= self.minZoom) && (tile.zoom <= self.maxZoom)),
			  @"%@ tried to retrieve tile with zoomLevel %d, outside source's defined range %f to %f",
			  self, tile.zoom, self.minZoom, self.maxZoom);
    
	return [NSURL URLWithString:[NSString stringWithFormat:@"http://tile.openstreetmap.org/%d/%d/%d.png", tile.zoom, tile.x, tile.y]];
}

- (NSString *)uniqueTilecacheKey {
	return @"OpenStreetMap";
}

- (NSString *)shortName {
    return @"Open Street Map";
}

- (NSString *)longDescription {
    return @"Open Street Map, the free wiki world map, provides freely usable map data for all parts of the world, under the Creative Commons Attribution-Share Alike 2.0 license.";
}

- (NSString *)shortAttribution {
    return @"© OpenStreetMap CC-BY-SA";
}

- (NSString *)longAttribution {
    return @"Map data © OpenStreetMap, licensed under Creative Commons Share Alike By Attribution.";
}


@end
