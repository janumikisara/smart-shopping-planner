import from "@jac/runtime" { useNavigate, jacLogout }
sv import from ..authService { authorizeDashboard }
sv import from ..services.shopService { ShopProfile, InventoryEntry, getShopProfile, saveShopProfile, saveShopLocation, listOwnInventory, addInventoryEntry, updateInventoryEntry, deleteInventoryEntry }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.button { Button }
import from .ui.input { Input }
import from .ui.badge { Badge }
import from .ShopMap { ShopMap }

def:pub ShopDashboard() -> JsxElement {
    has profile: ShopProfile | None = None,
        inventory: list[InventoryEntry] = [],
        profile_name: str = "",
        profile_category: str = "Other",
        profile_address: str = "",
        profile_contact: str = "",
        profile_description: str = "",
        profile_lat: str = "",
        profile_lon: str = "",
        product_name: str = "",
        product_brand: str = "",
        product_model: str = "",
        product_category: str = "Other",
        product_description: str = "",
        product_price: str = "",
        product_quantity: str = "0",
        product_status: str = "Availability unconfirmed",
        editing_id: str = "",
        loading: bool = True,
        busy: bool = False,
        error_message: str = "",
        success_message: str = "";
    nav = useNavigate();
    async can with entry {
        result = await authorizeDashboard("shop");
        if result["ok"] { await load_shop_data(); }
        elif result["destination"] as str { nav(result["destination"] as str, {"replace": True}); }
        else { nav("/login", {"replace": True}); }
    }
    async def load_shop_data {
        loading = True; profile = await getShopProfile(); inventory = await listOwnInventory();
        if profile is not None { saved = profile as ShopProfile; profile_name = saved.shop_name; profile_category = saved.category; profile_address = saved.address; profile_contact = saved.contact; profile_description = saved.description; profile_lat = str(saved.latitude); profile_lon = str(saved.longitude); }
        loading = False;
    }
    def sign_out(e: MouseEvent) { jacLogout(); nav("/login", {"replace": True}); }
    def handle_shop_name(e: ChangeEvent) { profile_name = e.target.value; }
    def handle_shop_category(e: ChangeEvent) { profile_category = e.target.value; }
    def handle_shop_address(e: ChangeEvent) { profile_address = e.target.value; }
    def handle_shop_contact(e: ChangeEvent) { profile_contact = e.target.value; }
    def handle_shop_description(e: ChangeEvent) { profile_description = e.target.value; }
    def handle_shop_lat(e: ChangeEvent) { profile_lat = e.target.value; }
    def handle_shop_lon(e: ChangeEvent) { profile_lon = e.target.value; }
    def handle_product_name(e: ChangeEvent) { product_name = e.target.value; }
    def handle_product_brand(e: ChangeEvent) { product_brand = e.target.value; }
    def handle_product_model(e: ChangeEvent) { product_model = e.target.value; }
    def handle_product_category(e: ChangeEvent) { product_category = e.target.value; }
    def handle_product_description(e: ChangeEvent) { product_description = e.target.value; }
    def handle_product_price(e: ChangeEvent) { product_price = e.target.value; }
    def handle_product_quantity(e: ChangeEvent) { product_quantity = e.target.value; }
    def handle_product_status(e: ChangeEvent) { product_status = e.target.value; }
    def pick_location(lat: float, lon: float) { profile_lat = str(lat); profile_lon = str(lon); success_message = "Pin selected. Save your profile to keep this location."; }
    def locate_me(e: MouseEvent) {
        geo: any = navigator as any;
        if geo.geolocation { geo.geolocation.getCurrentPosition(lambda (position: any) { profile_lat = str(position.coords.latitude); profile_lon = str(position.coords.longitude); success_message = "Current coordinates added. Save your profile to keep this location."; }, lambda (error: any) { error_message = "Location unavailable. Allow browser location access and try again."; }); }
        else { error_message = "Geolocation is not supported by this browser."; }
    }
    async def save_profile_form(e: FormEvent) {
        e.preventDefault(); lat_value = 0.0; lon_value = 0.0;
        try { lat_value = float(profile_lat); } except ValueError { error_message = "Enter a valid latitude between -90 and 90."; return; }
        try { lon_value = float(profile_lon); } except ValueError { error_message = "Enter a valid longitude between -180 and 180."; return; }
        busy = True; error_message = ""; success_message = "";
        response = await saveShopProfile(profile_name, profile_category, profile_address, profile_contact, profile_description, lat_value, lon_value);
        busy = False;
        if response["ok"] { success_message = response["message"] as str; await load_shop_data(); } else { error_message = response["message"] as str; }
    }
    async def save_map_location(e: MouseEvent) {
        lat_value = 0.0; lon_value = 0.0;
        try { lat_value = float(profile_lat); } except ValueError { error_message = "Choose a map point or enter valid coordinates."; return; }
        try { lon_value = float(profile_lon); } except ValueError { error_message = "Choose a map point or enter valid coordinates."; return; }
        if profile is None { error_message = "Save your shop name and address before setting its location."; return; }
        busy = True; response = await saveShopLocation(lat_value, lon_value); busy = False;
        if response["ok"] { success_message = response["message"] as str; await load_shop_data(); } else { error_message = response["message"] as str; }
    }
    async def save_inventory_form(e: FormEvent) {
        e.preventDefault();
        if product_name.strip() == "" { error_message = "Enter a product name."; return; }
        price_value = 0; quantity_value = 0;
        try { price_value = int(product_price); } except ValueError { error_message = "Enter a whole-number price in LKR."; return; }
        try { quantity_value = int(product_quantity); } except ValueError { error_message = "Enter a whole-number quantity."; return; }
        busy = True; error_message = ""; success_message = ""; response: dict = {};
        if editing_id == "" { response = await addInventoryEntry(product_name, product_brand, product_model, product_category, product_description, price_value, quantity_value, product_status) as dict; }
        else { response = await updateInventoryEntry(editing_id, product_name, product_brand, product_model, product_category, product_description, price_value, quantity_value, product_status) as dict; }
        busy = False;
        if response["ok"] { success_message = response["message"] as str; reset_product_form(); await load_shop_data(); } else { error_message = response["message"] as str; }
    }
    def reset_product_form { editing_id = ""; product_name = ""; product_brand = ""; product_model = ""; product_category = "Other"; product_description = ""; product_price = ""; product_quantity = "0"; product_status = "Availability unconfirmed"; }
    def start_edit(record: InventoryEntry) { editing_id = jid(record); product_name = record.product_name; product_brand = record.brand; product_model = record.model; product_category = record.category; product_description = record.description; product_price = str(record.price_lkr); product_quantity = str(record.quantity); product_status = record.stock_status; error_message = ""; success_message = ""; }
    async def remove_entry(entry_id: str) { busy = True; response: dict = await deleteInventoryEntry(entry_id) as dict; busy = False; if response["ok"] { success_message = response["message"] as str; await load_shop_data(); } else { error_message = response["message"] as str; } }

    has map_location: dict = {};
    if profile_lat and profile_lon { try { map_location = {"shop_name": profile_name or "Your storefront", "address": profile_address, "latitude": float(profile_lat), "longitude": float(profile_lon)}; } except ValueError { map_location = {}; } }
    map_locations: list[dict] = [map_location] if map_location else [];
    latitude_value = 6.773; longitude_value = 79.882;
    try { latitude_value = float(profile_lat); } except ValueError {}
    try { longitude_value = float(profile_lon); } except ValueError {}

    return <div className="min-h-svh bg-muted/40">
        <header className="flex items-center justify-between border-b bg-background px-5 py-4 sm:px-8"><div><p className="font-semibold">SmartCart · Shop portal</p><p className="text-xs text-muted-foreground">Profile and inventory management</p></div><Button variant="outline" onClick={sign_out}>Sign out</Button></header>
        <main className="mx-auto flex w-full max-w-7xl flex-col gap-6 px-5 py-8 sm:px-8"><div><h1 className="text-3xl font-semibold tracking-tight">Shop dashboard</h1><p className="mt-2 text-muted-foreground">Manage your storefront location and live product information.</p></div>
            {error_message and <p role="alert" className="rounded-md border border-destructive/30 bg-destructive/5 p-3 text-sm text-destructive">{error_message}</p>}{success_message and <p role="status" className="rounded-md border border-primary/30 bg-primary/5 p-3 text-sm">{success_message}</p>}
            {loading and <Card><CardContent className="p-6 text-sm text-muted-foreground">Loading your shop profile and inventory…</CardContent></Card>}
            {not loading and <Card className="shadow-sm"><CardHeader><CardTitle>Shop profile and storefront pin</CardTitle><CardDescription>Click the map to place your pin, or use Locate Me. Save your profile to publish the coordinates.</CardDescription></CardHeader><CardContent className="flex flex-col gap-5"><div className="flex flex-wrap gap-3"><Button type="button" variant="outline" onClick={locate_me}>Locate Me</Button><Button type="button" variant="outline" disabled={busy or profile is None} onClick={save_map_location}>Save map location</Button></div><ShopMap locations={map_locations} selected_lat={latitude_value} selected_lon={longitude_value} on_pick={pick_location} /><form onSubmit={save_profile_form} className="grid gap-4 md:grid-cols-2">
                <div className="flex flex-col gap-2"><label htmlFor="shop-name" className="text-sm font-medium">Shop name</label><Input id="shop-name" value={profile_name} onChange={handle_shop_name} placeholder="Shop name" /></div><div className="flex flex-col gap-2"><label htmlFor="shop-category" className="text-sm font-medium">Category</label><Input id="shop-category" value={profile_category} onChange={handle_shop_category} placeholder="Electronics, groceries, etc." /></div>
                <div className="flex flex-col gap-2 md:col-span-2"><label htmlFor="shop-address" className="text-sm font-medium">Street address</label><Input id="shop-address" value={profile_address} onChange={handle_shop_address} placeholder="Street address in Moratuwa" /></div><div className="flex flex-col gap-2"><label htmlFor="shop-contact" className="text-sm font-medium">Contact information</label><Input id="shop-contact" value={profile_contact} onChange={handle_shop_contact} placeholder="Phone or email" /></div><div className="flex flex-col gap-2"><label htmlFor="shop-description" className="text-sm font-medium">Description</label><Input id="shop-description" value={profile_description} onChange={handle_shop_description} placeholder="Short shop description" /></div>
                <div className="flex flex-col gap-2"><label htmlFor="shop-latitude" className="text-sm font-medium">Latitude</label><Input id="shop-latitude" type="number" step="any" value={profile_lat} onChange={handle_shop_lat} placeholder="6.773" /></div><div className="flex flex-col gap-2"><label htmlFor="shop-longitude" className="text-sm font-medium">Longitude</label><Input id="shop-longitude" type="number" step="any" value={profile_lon} onChange={handle_shop_lon} placeholder="79.882" /></div><div className="md:col-span-2"><Button type="submit" disabled={busy}>{"Saving profile…" if busy else "Save shop profile"}</Button></div>
            </form></CardContent></Card>}
            {not loading and <Card className="shadow-sm"><CardHeader><CardTitle>{"Edit inventory item" if editing_id else "Inventory manager"}</CardTitle><CardDescription>Published product information shoppers can compare.</CardDescription></CardHeader><CardContent className="flex flex-col gap-5"><form onSubmit={save_inventory_form} className="grid gap-4 md:grid-cols-2">
                <div className="flex flex-col gap-2"><label htmlFor="product-name" className="text-sm font-medium">Product name</label><Input id="product-name" value={product_name} onChange={handle_product_name} placeholder="Exact product name" /></div><div className="flex flex-col gap-2"><label htmlFor="product-category" className="text-sm font-medium">Category</label><Input id="product-category" value={product_category} onChange={handle_product_category} placeholder="Product category" /></div><div className="flex flex-col gap-2"><label htmlFor="product-brand" className="text-sm font-medium">Brand</label><Input id="product-brand" value={product_brand} onChange={handle_product_brand} placeholder="Brand, if applicable" /></div><div className="flex flex-col gap-2"><label htmlFor="product-model" className="text-sm font-medium">Model or identifier</label><Input id="product-model" value={product_model} onChange={handle_product_model} placeholder="Model or SKU" /></div><div className="flex flex-col gap-2"><label htmlFor="product-description" className="text-sm font-medium">Description/specifications</label><Input id="product-description" value={product_description} onChange={handle_product_description} placeholder="Relevant specifications" /></div><div className="grid grid-cols-2 gap-4"><div className="flex flex-col gap-2"><label htmlFor="product-price" className="text-sm font-medium">Price (LKR)</label><Input id="product-price" type="number" min="0" step="1" value={product_price} onChange={handle_product_price} /></div><div className="flex flex-col gap-2"><label htmlFor="product-quantity" className="text-sm font-medium">Quantity</label><Input id="product-quantity" type="number" min="0" step="1" value={product_quantity} onChange={handle_product_quantity} /></div></div><div className="flex flex-col gap-2"><label htmlFor="product-status" className="text-sm font-medium">Availability status</label><select id="product-status" value={product_status} onChange={handle_product_status} className="h-10 rounded-md border border-input bg-background px-3 text-sm"><option>In stock</option><option>Low stock</option><option>Out of stock</option><option>Availability unconfirmed</option></select></div><div className="flex items-end gap-2"><Button type="submit" disabled={busy}>{"Saving…" if busy else ("Update inventory item" if editing_id else "Add product")}</Button>{editing_id and <Button type="button" variant="outline" onClick={reset_product_form}>Cancel edit</Button>}</div>
            </form><div className="flex flex-col gap-3">{if len(inventory) == 0 {<div className="rounded-lg border border-dashed p-6"><p className="font-medium">No products in your inventory yet</p><p className="mt-1 text-sm text-muted-foreground">Add your first product above.</p></div>}}{for (index, product_record) in enumerate(inventory) {<div key={str(index)} className="flex flex-wrap items-start justify-between gap-4 rounded-lg border bg-background p-4"><div className="min-w-0"><p className="font-medium">{product_record.product_name}</p><p className="text-sm text-muted-foreground">{product_record.category} · LKR {str(product_record.price_lkr)} · Qty {str(product_record.quantity)}</p><p className="text-xs text-muted-foreground">{product_record.stock_status} · {product_record.updated_at}</p></div><div className="flex gap-2"><Button type="button" variant="outline" size="sm" onClick={lambda { start_edit(product_record); }}>Edit</Button><Button type="button" variant="outline" size="sm" disabled={busy} onClick={lambda { remove_entry(jid(product_record)); }}>Remove</Button></div></div>}}</div></CardContent></Card>}
        </main>
    </div>;
}
