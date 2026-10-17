import from "@jac/runtime" { jacLogin, jacIsLoggedIn, useNavigate }
sv import from ..authService { AuthResult, getAuthenticatedRole }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter }
import from .ui.button { Button }
import from .ui.input { Input }


def:pub RoleLogin() -> JsxElement {
    has email: str = "",
        password: str = "",
        selected_role: str = "user",
        error_message: str = "",
        busy: bool = False;
    nav = useNavigate();

    async can with entry {
        if jacIsLoggedIn() {
            result: AuthResult = await getAuthenticatedRole();
            if result.ok { nav(result.destination, {"replace": True}); }
        }
    }

    def update_email(e: ChangeEvent) { email = e.target.value; error_message = ""; }
    def update_password(e: ChangeEvent) { password = e.target.value; error_message = ""; }
    def select_role(role: str) { selected_role = role; error_message = ""; }

    async def submit_login(e: FormEvent) {
        e.preventDefault();
        if not email.strip() or not password {
            error_message = "Enter your email and password.";
            return;
        }
        busy = True;
        login_ok: bool = False;
        login_ok = await jacLogin(email.strip().lower(), password);
        if not login_ok {
            error_message = "Email or password is incorrect.";
            busy = False;
            return;
        }
        role_result: AuthResult = await getAuthenticatedRole();
        if not role_result.ok {
            error_message = role_result.message;
            busy = False;
            return;
        }
        if role_result.role != selected_role {
            error_message = "This account is registered as a " + role_result.role + " account. Choose that login option.";
            busy = False;
            return;
        }
        nav(role_result.destination, {"replace": True});
    }

    return <div className="grid min-h-svh bg-muted/40 lg:grid-cols-2">
        <section className="hidden flex-col justify-between bg-primary p-10 text-primary-foreground lg:flex">
            <div className="flex items-center gap-3"><div className="flex size-10 items-center justify-center rounded-xl bg-primary-foreground/15 font-semibold">S</div><span className="text-lg font-semibold">SmartCart</span></div>
            <div className="flex max-w-lg flex-col gap-5"><p className="text-sm font-medium text-primary-foreground/80">SHOP SMARTER IN MORATUWA</p><h1 className="text-balance text-4xl font-semibold tracking-tight">A more considered way to shop.</h1><p className="leading-relaxed text-primary-foreground/80">Compare local inventory, plan your stops, and make every trip count.</p></div>
            <p className="text-sm text-primary-foreground/75">A local-first shopping planner for Moratuwa.</p>
        </section>
        <main className="flex items-center justify-center p-5 sm:p-8">
            <Card className="w-full max-w-md shadow-sm">
                <CardHeader><CardTitle className="text-2xl">Sign in to SmartCart</CardTitle><CardDescription>Choose your account type before signing in.</CardDescription></CardHeader>
                <CardContent className="flex flex-col gap-5">
                    <div className="grid grid-cols-3 gap-2">
                        <Button type="button" variant={selected_role == "user" and "default" or "outline"} onClick={lambda { select_role("user"); }}>User</Button>
                        <Button type="button" variant={selected_role == "shop" and "default" or "outline"} onClick={lambda { select_role("shop"); }}>Shop</Button>
                        <Button type="button" variant={selected_role == "developer" and "default" or "outline"} onClick={lambda { select_role("developer"); }}>Developer</Button>
                    </div>
                    <form onSubmit={submit_login} className="flex flex-col gap-4">
                        <div className="flex flex-col gap-2"><label htmlFor="login-email" className="text-sm font-medium">Email</label><Input id="login-email" type="email" autoComplete="username" value={email} onChange={update_email} placeholder="you@example.com" /></div>
                        <div className="flex flex-col gap-2"><label htmlFor="login-password" className="text-sm font-medium">Password</label><Input id="login-password" type="password" autoComplete="current-password" value={password} onChange={update_password} placeholder="Your password" /></div>
                        {error_message and <p role="alert" className="rounded-md border border-destructive/30 bg-destructive/5 p-3 text-sm text-destructive">{error_message}</p>}
                        <Button type="submit" disabled={busy} className="w-full">{"Checking account…" if busy else "Sign in as " + selected_role}</Button>
                    </form>
                </CardContent>
                <CardFooter className="flex-col gap-3 border-t pt-4">
                    <p className="text-center text-sm text-muted-foreground">New to SmartCart? Create a user or shop account.</p>
                    <div className="flex w-full gap-3"><Button variant="outline" className="flex-1" onClick={lambda { nav("/register?type=user"); }}>Register user</Button><Button variant="outline" className="flex-1" onClick={lambda { nav("/register?type=shop"); }}>Register shop</Button></div>
                    <p className="text-xs text-muted-foreground">Developer access is provisioned by an administrator; public developer registration is disabled.</p>
                </CardFooter>
            </Card>
        </main>
    </div>;
}
