import from "@jac/runtime" { useNavigate, jacLogout }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.button { Button }

def:pub UserDashboard() -> JsxElement {
    nav = useNavigate();
    def sign_out(e: MouseEvent) { jacLogout(); nav("/login", {"replace": True}); }
    def go_planner(e: MouseEvent) { nav("/planner"); }

    return <div className="min-h-svh bg-muted/40">
        <header className="flex items-center justify-between border-b bg-background px-6 py-4"><div><p className="font-semibold">SmartCart · User</p><p className="text-xs text-muted-foreground">Moratuwa shopping planner</p></div><Button variant="outline" onClick={sign_out}>Sign out</Button></header>
        <main className="mx-auto flex max-w-5xl flex-col gap-6 px-5 py-8 sm:px-8">
            <div><h1 className="text-3xl font-semibold tracking-tight">Your shopping dashboard</h1><p className="mt-2 text-muted-foreground">Create a list, compare shop inventory, and plan your next trip.</p></div>
            <Card className="shadow-sm"><CardHeader><CardTitle>Shopping planner</CardTitle><CardDescription>Compare Moratuwa demo inventory and generate a grouped shopping plan.</CardDescription></CardHeader><CardContent><Button onClick={go_planner}>Open shopping planner</Button></CardContent></Card>
            <Card><CardHeader><CardTitle>Account access</CardTitle><CardDescription>Your user role was confirmed by the server for this session.</CardDescription></CardHeader></Card>
        </main>
    </div>;
}
