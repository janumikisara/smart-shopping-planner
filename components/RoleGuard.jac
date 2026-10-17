import from "@jac/runtime" { jacIsLoggedIn, Navigate }
sv import from ..authService { AuthResult, getAuthenticatedRole }

def:pub RoleGuard(role: str, children: any = None) -> JsxElement {
    has checked: bool = False,
        allowed: bool = False,
        destination: str = "",
        message: str = "";

    async can with [role] entry {
        if not jacIsLoggedIn() {
            destination = "/login";
            checked = True;
        } else {
            result: AuthResult = await getAuthenticatedRole();
            checked = True;
            if result.ok and result.role == role {
                allowed = True;
            } elif result.ok {
                destination = result.destination;
            } else {
                message = result.message;
            }
        }
    }

    if not checked { return <div className="flex min-h-svh items-center justify-center text-sm text-muted-foreground">Checking account access…</div>; }
    if destination { return <Navigate to={destination} replace={True} />; }
    if not allowed { return <div className="flex min-h-svh items-center justify-center p-6"><div role="alert" className="max-w-lg rounded-lg border border-destructive/30 bg-background p-6 text-sm text-destructive">{message if message else "You do not have permission to open this dashboard."}</div></div>; }
    return <>{children}</>;
}
