//
//  TGMarker.mm
//  TangramMap
//
//  Created by Karim Naaji on 2/17/17.
//  Copyright (c) 2017 Mapzen. All rights reserved.
//

#import "TGMarker.h"
#import "TGMapViewController.h"
#import "TGMapViewController+Internal.h"
#import "TGHelpers.h"
#import "tangram.h"

enum class TGMarkerType {
    point,
    polygon,
    polyline,
    none,
};

@interface TGMarker () {
    Tangram::Map* tangramInstance;
    Tangram::MarkerID identifier;
    TGMarkerType type;
}

@end

@implementation TGMarker

- (instancetype)init
{
    self = [super init];

    if (self) {
        self.visible = YES;
        type = TGMarkerType::none;
    }

    return self;
}

- (void)setStyling:(NSString *)styling
{
    _styling = styling;

    if (!tangramInstance || !identifier) { return; }

    tangramInstance->markerSetStyling(identifier, [styling UTF8String]);
}

- (void)setPoint:(TGGeoPoint)coordinates
{
    _point = coordinates;
    type = TGMarkerType::point;

    if (!tangramInstance || !identifier) { return; }

    Tangram::LngLat lngLat(coordinates.longitude, coordinates.latitude);

    tangramInstance->markerSetPoint(identifier, lngLat);
}

- (BOOL)setPointEased:(TGGeoPoint)coordinates seconds:(float)seconds easeType:(TGEaseType)ease
{
    _point = coordinates;
    type = TGMarkerType::point;

    if (!tangramInstance || !identifier) { return; }

    Tangram::LngLat lngLat(coordinates.longitude, coordinates.latitude);

    tangramInstance->markerSetPointEased(identifier, lngLat, seconds, [TGHelpers convertEaseTypeFrom:ease]);
}

- (void)setPolyline:(TGGeoPolyline *)polyline
{
    _polyline = polyline;
    type = TGMarkerType::polyline;

    if (polyline.count < 2 || !tangramInstance || !identifier) { return; }

    tangramInstance->markerSetPolyline(identifier, reinterpret_cast<Tangram::LngLat*>([polyline coordinates]), polyline.count);
}

- (void)setPolygon:(TGGeoPolygon *)polygon
{
    _polygon = polygon;
    type = TGMarkerType::polygon;

    if (polygon.count < 3 || !tangramInstance || !identifier) { return; }

    auto coords = reinterpret_cast<Tangram::LngLat*>([polygon coordinates]);

    tangramInstance->markerSetPolygon(identifier, coords, [polygon rings], [polygon ringsCount]);
}

- (void)setVisible:(BOOL)visible
{
    _visible = visible;

    if (!tangramInstance || !identifier) { return; }

    tangramInstance->markerSetVisible(identifier, visible);
}

- (void)setIcon:(UIImage *)icon
{
    if (!tangramInstance) { return; }

    CGImage* cgImage = [icon CGImage];
    size_t w = CGImageGetHeight(cgImage);
    size_t h = CGImageGetWidth(cgImage);
    std::vector<unsigned int> bitmap;

    bitmap.resize(w * h);

    CGColorSpaceRef colorSpace = CGImageGetColorSpace(cgImage);
    CGContextRef cgContext = CGBitmapContextCreate(bitmap.data(), w, h, 8, w * 4, colorSpace, kCGImageAlphaPremultipliedLast);

    // Flip image upside down-horizontally
    CGAffineTransform flipAffineTransform = CGAffineTransformMake(1, 0, 0, -1, 0, h);
    CGContextConcatCTM(cgContext, flipAffineTransform);

    CGContextDrawImage(cgContext, CGRectMake(0, 0, w, h), cgImage);
    CGContextRelease(cgContext);

    tangramInstance->markerSetBitmap(identifier, w, h, bitmap.data());
}

- (void)setMap:(TGMapViewController *)mapView
{
    // remove marker from current view
    if (!mapView && tangramInstance && identifier) {
        tangramInstance->markerRemove(identifier);
        tangramInstance = nullptr;
        return;
    }

    if (![mapView map] || [mapView map] == tangramInstance) { return; }

    // Removes the marker from the previous map view
    if (tangramInstance) {
        tangramInstance->markerRemove(identifier);
    }

    tangramInstance = [mapView map];

    // Create a new marker identifier for this view
    identifier = tangramInstance->markerAdd();

    if (!identifier) { return NO; }

    // Set the geometry type
    switch (type) {
        case TGMarkerType::point: {
            [self setPoint:self.point];

            if (self.icon) {
                [self setIcon:self.icon];
            }
        }
        break;
        case TGMarkerType::polygon: {
            [self setPolygon:self.polygon];
        }
        break;
        case TGMarkerType::polyline: {
            [self setPolyline:self.polyline];
        }
        case TGMarkerType::none:
        break;
    }

    // Update styling
    if (self.styling) {
        tangramInstance->markerSetStyling(identifier, [self.styling UTF8String]);
    }

    tangramInstance->markerSetVisible(identifier, self.visible);
}

@end

