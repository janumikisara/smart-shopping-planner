import from "@jac/runtime" { useNavigate, jacLogout }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }


def:pub DeveloperDashboard() -> JsxElement {
    nav = useNavigate();
    def sign_out(e: MouseEvent) { jacLogout(); nav("/login", {"replace": True}); }

    return <div className="min-h-svh bg-muted/40">
        <header className="flex items-center justify-between border-b bg-background px-6 py-4"><div><p className="font-semibold">SmartCart · Developer</p><p className="text-xs text-muted-foreground">Authorized system workspace</p></div><button type="button" onClick={sign_out} className="rounded-md border bg-background px-4 py-2 text-sm">Sign out</button></header>
        <main className="mx-auto flex max-w-6xl flex-col gap-6 px-5 py-8 sm:px-8">
            <div><h1 className="text-3xl font-semibold tracking-tight">Developer dashboard</h1><p className="mt-2 text-muted-foreground">System diagnostics available only to a server-provisioned developer account.</p></div>
            <div className="grid gap-4 md:grid-cols-2">
                <Card className="shadow-sm"><CardHeader><CardTitle>Account inspection</CardTitle><CardDescription>Access is protected by a server-side developer profile check.</CardDescription></CardHeader><CardContent><p className="text-sm text-muted-foreground">Public developer registration is disabled. Provision a developer profile from trusted server administration only.</p></CardContent></Card>
                <Card className="shadow-sm"><CardHeader><CardTitle>Service status</CardTitle><CardDescription>Optional integrations and current scope.</CardDescription></CardHeader><CardContent><p className="text-sm text-muted-foreground">Gemini, maps, and persistent inventory integrations are not configured in this build.</p></CardContent></Card>
            </div>
        </main>
    </div>;
}
