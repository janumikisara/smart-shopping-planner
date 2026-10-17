import from "@jac/runtime" { useNavigate, jacLogout }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.button { Button }

def:pub ShopDashboard() -> JsxElement {
    nav = useNavigate();
    def sign_out(e: MouseEvent) { jacLogout(); nav("/login", {"replace": True}); }

    return <div className="min-h-svh bg-muted/40">
        <header className="flex items-center justify-between border-b bg-background px-6 py-4"><div><p className="font-semibold">SmartCart · Shop portal</p><p className="text-xs text-muted-foreground">Inventory workspace</p></div><Button variant="outline" onClick={sign_out}>Sign out</Button></header>
        <main className="mx-auto flex max-w-5xl flex-col gap-6 px-5 py-8 sm:px-8">
            <div><h1 className="text-3xl font-semibold tracking-tight">Shop dashboard</h1><p className="mt-2 text-muted-foreground">A dedicated workspace for your shop profile and product availability.</p></div>
            <div className="grid gap-4 sm:grid-cols-2">
                <Card className="shadow-sm"><CardHeader><CardTitle>Shop profile</CardTitle><CardDescription>Manage the details customers use to find your store.</CardDescription></CardHeader><CardContent><p className="text-sm text-muted-foreground">Your shop account is authenticated. Profile editing needs persistent shop storage, which is not connected yet.</p></CardContent></Card>
                <Card className="shadow-sm"><CardHeader><CardTitle>Inventory</CardTitle><CardDescription>Keep prices and availability current.</CardDescription></CardHeader><CardContent><p className="text-sm text-muted-foreground">Shop-specific inventory editing is not connected yet. Demo listings remain simulated.</p></CardContent></Card>
            </div>
        </main>
    </div>;
}
