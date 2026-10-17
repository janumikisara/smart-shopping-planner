import from "@jac/runtime" { useNavigate, jacLogout }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.button { Button }
sv import from ..services.shopService { ShopProfile, getSavedShopLocations }
import from .ShopMap { ShopMap }

def:pub UserDashboard() -> JsxElement {
    has locations: list[ShopProfile] = [],
        loading: bool = True,
        load_error: str = "";
    nav = useNavigate();

    async can with entry {
        try { locations = await getSavedShopLocations(); }
        except Exception { load_error = "Nearby shops could not be loaded. Please try again."; }
        loading = False;
    }

    def sign_out(e: MouseEvent) { jacLogout(); nav("/login", {"replace": True}); }
    def go_planner(e: MouseEvent) { nav("/planner"); }
    async def retry_load -> None { loading = True; load_error = ""; try { locations = await getSavedShopLocations(); } except Exception { load_error = "Nearby shops could not be loaded. Please try again."; } loading = False; }

    locations_data: list[dict] = [];
    for place in locations { locations_data.append({"shop_name": place.shop_name, "address": place.address, "latitude": place.latitude, "longitude": place.longitude}); }

    return <div className="min-h-svh bg-muted/40">
        <header className="flex items-center justify-between border-b bg-background px-5 py-4 sm:px-8"><div><p className="font-semibold">SmartCart · User</p><p className="text-xs text-muted-foreground">Moratuwa shopping planner</p></div><Button variant="outline" onClick={sign_out}>Logout</Button></header>
        <main className="mx-auto flex w-full max-w-7xl flex-col gap-6 px-5 py-8 sm:px-8">
            <div className="flex flex-wrap items-end justify-between gap-4"><div><h1 className="text-3xl font-semibold tracking-tight">Explore nearby shops</h1><p className="mt-2 text-muted-foreground">Find local storefronts and plan your next shopping trip.</p></div><Button onClick={go_planner}>Open shopping planner</Button></div>
            <Card className="shadow-sm"><CardHeader><CardTitle>Shop locations</CardTitle><CardDescription>Saved storefronts around Moratuwa. Select a marker for shop details.</CardDescription></CardHeader><CardContent>
                {loading and <div className="flex h-40 items-center justify-center rounded-lg border bg-muted/30 text-sm text-muted-foreground">Loading saved shop locations…</div>}
                {not loading and load_error and <div className="flex flex-col gap-3 rounded-lg border border-destructive/30 bg-destructive/5 p-5"><p role="alert" className="text-sm text-destructive">{load_error}</p><Button variant="outline" onClick={retry_load}>Retry</Button></div>}
                {not loading and not load_error and len(locations) == 0 and <div className="rounded-lg border border-dashed bg-muted/30 p-8"><p className="font-medium">No saved shop locations yet</p><p className="mt-1 text-sm text-muted-foreground">Shop storefronts will appear here once owners add their map location.</p></div>}
                {not loading and not load_error and len(locations) > 0 and <ShopMap locations={locations_data} />}
            </CardContent></Card>
            <Card className="shadow-sm"><CardHeader><CardTitle>Shopping planner</CardTitle><CardDescription>Build a list, compare shop inventory, and follow a road route to your selected shop.</CardDescription></CardHeader><CardContent><Button variant="outline" onClick={go_planner}>Plan a shopping trip</Button></CardContent></Card>
        </main>
    </div>;
}
