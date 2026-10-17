import from "react-leaflet" { MapContainer, TileLayer, Marker, Popup, Tooltip, Polyline, useMapEvents }
import "leaflet/dist/leaflet.css";

def:pub ShopMap(locations: list[dict], selected_lat: float = 6.773, selected_lon: float = 79.882, user_lat: float | None = None, user_lon: float | None = None, on_pick: Callable[[float, float], None] | None = None, on_select: Callable[[float, float], None] | None = None) -> JsxElement {
    has route_points: list[list[float]] = [],
        route_status: str = "";

    safe_lat: float = 6.773;
    safe_lon: float = 79.882;
    has_selected: bool = False;
    if selected_lat >= -90.0 and selected_lat <= 90.0 and selected_lon >= -180.0 and selected_lon <= 180.0 and (selected_lat != 0.0 or selected_lon != 0.0) {
        safe_lat = selected_lat;
        safe_lon = selected_lon;
        has_selected = True;
    }

    async can with [user_lat, user_lon, safe_lat, safe_lon] entry {
        if user_lat is not None and user_lon is not None and has_selected {
            route_status = "Finding a road route…";
            try {
                response = await fetch("https://router.project-osrm.org/route/v1/driving/" + str(user_lon) + "," + str(user_lat) + ";" + str(safe_lon) + "," + str(safe_lat) + "?overview=full&geometries=geojson");
                data = await response.json();
                if data["routes"] and len(data["routes"]) > 0 {
                    coords = data["routes"][0]["geometry"]["coordinates"] as list[list[float]];
                    route_points = [[point[1], point[0]] for point in coords];
                    route_status = "Road route provided by OSRM.";
                } else { route_points = []; route_status = "No driving route found for these locations."; }
            } except Exception { route_points = []; route_status = "Road routing is temporarily unavailable."; }
        } else { route_points = []; route_status = ""; }
    }

    def choose_map_point(lat: float, lon: float) { if on_pick { on_pick(lat, lon); } }
    def choose_shop(lat: float, lon: float) { if on_select { on_select(lat, lon); } }

    return <div className="flex flex-col gap-2">
        <MapContainer center={[6.773, 79.882]} zoom={13} scrollWheelZoom={True} className="h-[320px] w-full rounded-xl border sm:h-[420px]">
            <TileLayer attribution="&copy; OpenStreetMap contributors" url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
            <MapPicker onPick={choose_map_point} />
            {for (index, place) in enumerate(locations) {
                lat_value: float = place["latitude"] as float;
                lon_value: float = place["longitude"] as float;
                if lat_value >= -90.0 and lat_value <= 90.0 and lon_value >= -180.0 and lon_value <= 180.0 and (lat_value != 0.0 or lon_value != 0.0) {
                    <Marker key={str(index)} position={[lat_value, lon_value]} eventHandlers={{"click": lambda { choose_shop(lat_value, lon_value); }}}>
                        <Tooltip>{str(place["shop_name"])}</Tooltip>
                        <Popup><strong>{str(place["shop_name"])}</strong><br />{str(place["address"])}</Popup>
                    </Marker>
                }
            }}
            {has_selected and <Marker position={[safe_lat, safe_lon]}><Tooltip>Selected shop location</Tooltip></Marker>}
            {user_lat is not None and user_lon is not None and <Marker position={[user_lat, user_lon]}><Tooltip>Your location</Tooltip></Marker>}
            {len(route_points) > 0 and <Polyline positions={route_points} pathOptions={{"color": "#0f766e", "weight": 5, "opacity": 0.8}} />}
        </MapContainer>
        {route_status and <p role="status" className="text-xs text-muted-foreground">{route_status}</p>}
        <p className="text-xs text-muted-foreground">Map tiles © OpenStreetMap contributors. Select a shop marker to plan a route.</p>
    </div>;
}

def:pub MapPicker(onPick: Callable[[float, float], None]) -> JsxElement {
    useMapEvents({"click": lambda (e: any) { onPick(e.latlng.lat, e.latlng.lng); }});
    return <span />;
}
