#pragma once

#include "scene/styleContext.h"
#include "scene/drawRule.h"
#include "util/ease.h"
#include "util/fastmap.h"
#include "util/types.h"

#include <memory>
#include <vector>

namespace Tangram {

class MapProjection;
class Marker;
class Scene;
class StyleBuilder;

class MarkerManager {

public:

    // Set the Scene object whose styling information will be used to build markers.
    void setScene(std::shared_ptr<Scene> scene);

    // Create a new, empty marker and return its ID. An ID of 0 indicates an invalid marker.
    MarkerID add();

    // Try to remove the marker with the given ID; returns true if the marker was found and removed.
    bool remove(MarkerID markerID);

    // Set the styling string for a marker; returns true if the marker was found and updated.
    bool setStyling(MarkerID markerID, const char* styling);

    bool setBitmap(MarkerID markerID, int width, int height, const unsigned int* bitmapData);

    // Set whether a marker should be visible; returns true if the marker was found and updated.
    bool setVisible(MarkerID markerID, bool visible);

    // Set the ordering of this marker relative to other markers. Higher values are drawn 'above' others.
    bool setDrawOrder(MarkerID markerID, int drawOrder);

    // Set a marker to a point feature at the given position; returns true if the marker was found and updated.
    bool setPoint(MarkerID markerID, LngLat lngLat);

    // Set a marker to a point feature at the given position; if the marker was previously set to a point, this
    // eases from the old position to the new one over the given duration with the given ease type; returns true if
    // the marker was found and updated.
    bool setPointEased(MarkerID markerID, LngLat lngLat, float duration, EaseType ease);

    // Set a marker to a polyline feature at the given position; returns true if the marker was found and updated.
    bool setPolyline(MarkerID markerID, LngLat* coordinates, int count);

    // Set a marker to a polygon feature at the given position; returns true if the marker was found and updated.
    bool setPolygon(MarkerID markerID, LngLat* coordinates, int* counts, int rings);

    // Update the zoom level for all markers; markers are built for one zoom level at a time so when the current zoom
    // changes, all marker meshes are rebuilt.
    bool update(int zoom);

    // Remove and destroy all markers.
    void removeAll();

    // Rebuild all markers.
    void rebuildAll();

    const std::vector<std::unique_ptr<Marker>>& markers() const;

    const Marker* getMarkerOrNullBySelectionColor(uint32_t selectionColor) const;

private:

    Marker* getMarkerOrNull(MarkerID markerID);

    bool buildStyling(Marker& marker);
    bool buildGeometry(Marker& marker, int zoom);

    StyleContext m_styleContext;
    std::shared_ptr<Scene> m_scene;
    std::vector<std::unique_ptr<Marker>> m_markers;
    std::vector<std::string> m_jsFnList;
    fastmap<std::string, std::unique_ptr<StyleBuilder>> m_styleBuilders;
    MapProjection* m_mapProjection = nullptr;
    size_t m_jsFnIndex = 0;
    uint32_t m_idCounter = 0;
    int m_zoom = 0;

};

} // namespace Tangram
