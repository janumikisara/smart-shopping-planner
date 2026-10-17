import from "@jac/runtime" { jacSignup, jacLogin, useNavigate, useLocation }
sv import from ..authService { AuthResult, registerAccount }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter }
import from .ui.button { Button }
import from .ui.input { Input }


def:pub RoleRegistration() -> JsxElement {
    has account_type: str = "user",
        name: str = "",
        shop_name: str = "",
        email: str = "",
        password: str = "",
        confirm_password: str = "",
        error_message: str = "",
        busy: bool = False;
    nav = useNavigate();
    location = useLocation();

    can with entry {
        if "type=shop" in location.search { account_type = "shop"; }
    }

    def update_name(e: ChangeEvent) { name = e.target.value; error_message = ""; }
    def update_shop(e: ChangeEvent) { shop_name = e.target.value; error_message = ""; }
    def update_email(e: ChangeEvent) { email = e.target.value; error_message = ""; }
    def update_password(e: ChangeEvent) { password = e.target.value; error_message = ""; }
    def update_confirm(e: ChangeEvent) { confirm_password = e.target.value; error_message = ""; }

    async def submit_registration(e: FormEvent) {
        e.preventDefault();
        if not name.strip() or not email.strip() or not password {
            error_message = "Complete all required fields.";
            return;
        }
        if "@" not in email or "." not in email {
            error_message = "Enter a valid email address.";
            return;
        }
        if len(password) < 10 {
            error_message = "Use a password with at least 10 characters.";
            return;
        }
        if password != confirm_password {
            error_message = "The passwords do not match.";
            return;
        }
        if account_type == "shop" and not shop_name.strip() {
            error_message = "Enter your shop name.";
            return;
        }
        busy = True;
        signup_result: dict | None = None;
        signup_result = await jacSignup(email.strip().lower(), password);
        if signup_result is None or not signup_result["success"] {
            error_message = "Account creation failed. The email may already be registered.";
            busy = False;
            return;
        }
        login_ok: bool = False;
        login_ok = await jacLogin(email.strip().lower(), password);
        if not login_ok {
            error_message = "Account created, but sign-in failed. Return to login and sign in.";
            busy = False;
            return;
        }
        account_result: AuthResult = await registerAccount(account_type, name.strip(), shop_name.strip());
        if not account_result.ok {
            error_message = account_result.message;
            busy = False;
            return;
        }
        nav(account_result.destination, {"replace": True});
    }

    return <div className="grid min-h-svh bg-muted/40 lg:grid-cols-2">
        <section className="hidden flex-col justify-between bg-primary p-10 text-primary-foreground lg:flex">
            <div className="flex items-center gap-3"><div className="flex size-10 items-center justify-center rounded-xl bg-primary-foreground/15 font-semibold">S</div><span className="text-lg font-semibold">SmartCart</span></div>
            <div className="flex max-w-lg flex-col gap-5"><p className="text-sm font-medium text-primary-foreground/80">START PLANNING SMARTER</p><h1 className="text-balance text-4xl font-semibold tracking-tight">Shopping that fits your day.</h1><p className="leading-relaxed text-primary-foreground/80">Create a secure account to manage your lists or share your shop inventory.</p></div>
            <p className="text-sm text-primary-foreground/75">Developer accounts are created by administrators only.</p>
        </section>
        <main className="flex items-center justify-center p-5 sm:p-8">
            <Card className="w-full max-w-md shadow-sm">
                <CardHeader><CardTitle className="text-2xl">Create a {account_type} account</CardTitle><CardDescription>Register with a secure password. Role is assigned by the server.</CardDescription></CardHeader>
                <CardContent>
                    <div className="mb-5 grid grid-cols-2 gap-2"><Button type="button" variant={account_type == "user" and "default" or "outline"} onClick={lambda { account_type = "user"; error_message = ""; }}>User registration</Button><Button type="button" variant={account_type == "shop" and "default" or "outline"} onClick={lambda { account_type = "shop"; error_message = ""; }}>Shop registration</Button></div>
                    <form onSubmit={submit_registration} className="flex flex-col gap-4">
                        <div className="flex flex-col gap-2"><label htmlFor="reg-name" className="text-sm font-medium">{ "Your name" if account_type == "user" else "Contact name" }</label><Input id="reg-name" autoComplete="name" value={name} onChange={update_name} placeholder="Your full name" /></div>
                        {account_type == "shop" and <div className="flex flex-col gap-2"><label htmlFor="reg-shop" className="text-sm font-medium">Shop name</label><Input id="reg-shop" value={shop_name} onChange={update_shop} placeholder="Your shop name" /></div>}
                        <div className="flex flex-col gap-2"><label htmlFor="reg-email" className="text-sm font-medium">Email</label><Input id="reg-email" type="email" autoComplete="email" value={email} onChange={update_email} placeholder="you@example.com" /></div>
                        <div className="flex flex-col gap-2"><label htmlFor="reg-password" className="text-sm font-medium">Password</label><Input id="reg-password" type="password" autoComplete="new-password" value={password} onChange={update_password} placeholder="At least 10 characters" /></div>
                        <div className="flex flex-col gap-2"><label htmlFor="reg-confirm" className="text-sm font-medium">Confirm password</label><Input id="reg-confirm" type="password" autoComplete="new-password" value={confirm_password} onChange={update_confirm} placeholder="Enter password again" /></div>
                        {error_message and <p role="alert" className="rounded-md border border-destructive/30 bg-destructive/5 p-3 text-sm text-destructive">{error_message}</p>}
                        <Button type="submit" disabled={busy} className="w-full">{"Creating account…" if busy else "Create " + account_type + " account"}</Button>
                    </form>
                </CardContent>
                <CardFooter className="border-t pt-4"><p className="w-full text-center text-sm text-muted-foreground">Already have an account? <button type="button" onClick={lambda { nav("/login"); }} className="font-medium text-foreground underline underline-offset-4">Sign in</button></p></CardFooter>
            </Card>
        </main>
    </div>;
}
