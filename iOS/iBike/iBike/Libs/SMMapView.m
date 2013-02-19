//
//  SMMapView.m
//  iBike
//
//  Created by Ivan Pavlovic on 19/02/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMMapView.h"

#import "RMMapView.h"
#import "RMMapViewDelegate.h"
#import "RMPixel.h"

#import "RMFoundation.h"
#import "RMProjection.h"
#import "RMMarker.h"
#import "RMPath.h"
#import "RMCircle.h"
#import "RMShape.h"
#import "RMAnnotation.h"
#import "RMQuadTree.h"

#import "RMFractalTileProjection.h"
#import "RMOpenStreetMapSource.h"

#import "RMTileCache.h"
#import "RMTileSource.h"

#import "RMMapTiledLayerView.h"
#import "RMMapOverlayView.h"
#import "RMLoadingTileView.h"

#import "RMUserLocation.h"

#pragma mark --- begin constants ----

#define kZoomRectPixelBuffer 150.0

#define kDefaultInitialLatitude 47.56
#define kDefaultInitialLongitude 10.22

#define kDefaultMinimumZoomLevel 0.0
#define kDefaultMaximumZoomLevel 25.0
#define kDefaultInitialZoomLevel 13.0

#define kDefaultHeadingFilter 5

#pragma mark --- end constants ----

@interface RMMapView()

@property (nonatomic, retain) CLLocation *cachedLocation;

@end

@interface RMMapView (PrivateMethods) <UIScrollViewDelegate, UIGestureRecognizerDelegate, RMMapScrollViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, retain) RMUserLocation *userLocation;

- (void)createMapView;

- (void)registerMoveEventByUser:(BOOL)wasUserEvent;
- (void)registerZoomEventByUser:(BOOL)wasUserEvent;

- (void)correctPositionOfAllAnnotations;
- (void)correctPositionOfAllAnnotationsIncludingInvisibles:(BOOL)correctAllLayers animated:(BOOL)animated;
- (void)correctOrderingOfAllAnnotations;

- (void)correctMinZoomScaleForBoundingMask;

- (void)updateHeadingForDeviceOrientation;

@end

#pragma mark -

@interface RMUserLocation (PrivateMethods)

@property (nonatomic, getter=isUpdating) BOOL updating;
@property (nonatomic, retain) CLLocation *location;
@property (nonatomic, retain) CLHeading *heading;

@end

#pragma mark -

@interface RMAnnotation (PrivateMethods)

@property (nonatomic, assign) BOOL isUserLocationAnnotation;

@end


@implementation SMMapView

{
    id <RMMapViewDelegate> _delegate;
    
    BOOL _delegateHasBeforeMapMove;
    BOOL _delegateHasAfterMapMove;
    BOOL _delegateHasBeforeMapZoom;
    BOOL _delegateHasAfterMapZoom;
    BOOL _delegateHasMapViewRegionDidChange;
    BOOL _delegateHasDoubleTapOnMap;
    BOOL _delegateHasSingleTapOnMap;
    BOOL _delegateHasSingleTapTwoFingersOnMap;
    BOOL _delegateHasLongSingleTapOnMap;
    BOOL _delegateHasTapOnAnnotation;
    BOOL _delegateHasDoubleTapOnAnnotation;
    BOOL _delegateHasTapOnLabelForAnnotation;
    BOOL _delegateHasDoubleTapOnLabelForAnnotation;
    BOOL _delegateHasShouldDragMarker;
    BOOL _delegateHasDidDragMarker;
    BOOL _delegateHasDidEndDragMarker;
    BOOL _delegateHasLayerForAnnotation;
    BOOL _delegateHasWillHideLayerForAnnotation;
    BOOL _delegateHasDidHideLayerForAnnotation;
    BOOL _delegateHasWillStartLocatingUser;
    BOOL _delegateHasDidStopLocatingUser;
    BOOL _delegateHasDidUpdateUserLocation;
    BOOL _delegateHasDidFailToLocateUserWithError;
    BOOL _delegateHasDidChangeUserTrackingMode;
    
    UIView *_backgroundView;
    RMMapScrollView *_mapScrollView;
    RMMapOverlayView *_overlayView;
    UIView *_tiledLayersSuperview;
    RMLoadingTileView *_loadingTileView;
    
    RMProjection *_projection;
    RMFractalTileProjection *_mercatorToTileProjection;
    RMTileSourcesContainer *_tileSourcesContainer;
    
    NSMutableSet *_annotations;
    NSMutableSet *_visibleAnnotations;
    
    BOOL _constrainMovement;
    RMProjectedRect _constrainingProjectedBounds;
    
    double _metersPerPixel;
    float _zoom, _lastZoom;
    CGPoint _lastContentOffset, _accumulatedDelta;
    CGSize _lastContentSize;
    BOOL _mapScrollViewIsZooming;
    
    BOOL _enableDragging, _enableBouncing;
    
    CGPoint _lastDraggingTranslation;
    RMAnnotation *_draggedAnnotation;
    
    CLLocationManager *_locationManager;
    
    double lastLocUpdatedTime;
    
    RMAnnotation *_accuracyCircleAnnotation;
    RMAnnotation *_trackingHaloAnnotation;
    
    UIImageView *_userLocationTrackingView;
    UIImageView *_userHeadingTrackingView;
    UIImageView *_userHaloTrackingView;
    
    CGAffineTransform _mapTransform;
    CATransform3D _annotationTransform;
    
    NSOperationQueue *_moveDelegateQueue;
    NSOperationQueue *_zoomDelegateQueue;
}


@synthesize decelerationMode = _decelerationMode;

@synthesize boundingMask = _boundingMask;
@synthesize zoomingInPivotsAroundCenter = _zoomingInPivotsAroundCenter;
@synthesize minZoom = _minZoom, maxZoom = _maxZoom;
@synthesize screenScale = _screenScale;
@synthesize tileCache = _tileCache;
@synthesize quadTree = _quadTree;
@synthesize enableClustering = _enableClustering;
@synthesize positionClusterMarkersAtTheGravityCenter = _positionClusterMarkersAtTheGravityCenter;
@synthesize orderMarkersByYPosition = _orderMarkersByYPosition;
@synthesize orderClusterMarkersAboveOthers = _orderClusterMarkersAboveOthers;
@synthesize clusterMarkerSize = _clusterMarkerSize, clusterAreaSize = _clusterAreaSize;
@synthesize adjustTilesForRetinaDisplay = _adjustTilesForRetinaDisplay;
@synthesize userLocation = _userLocation;
@synthesize showsUserLocation = _showsUserLocation;
@synthesize userTrackingMode = _userTrackingMode;
@synthesize displayHeadingCalibration = _displayHeadingCalibration;
@synthesize missingTilesDepth = _missingTilesDepth;
@synthesize debugTiles = _debugTiles;
@synthesize triggerUpdateOnHeadingChange = _triggerUpdateOnHeadingChange;
@synthesize rotateOnHeadingChange = _rotateOnHeadingChange;
@synthesize cachedLocation = _cachedLocation;

/**
 * Set the user location layer to top
 */
- (void)setShowsUserLocation:(BOOL)newShowsUserLocation {
    [super setShowsUserLocation:newShowsUserLocation];    
    if (self.userLocation && newShowsUserLocation) {
        self.userLocation.layer.zPosition = MAXFLOAT;
    }
}   

@end
