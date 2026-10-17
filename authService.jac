node AccountProfile {
    has role: str = "user";
    has display_name: str = "";
    has shop_name: str = "";
}

obj AuthResult {
    has ok: bool;
    has message: str;
    has role: str = "";
    has destination: str = "";
}

def:protect registerAccount(account_type: str, display_name: str, shop_name: str) -> AuthResult {
    if account_type != "user" and account_type != "shop" {
        return AuthResult(ok=False, message="Developer accounts require administrator provisioning.");
    }
    if account_type == "shop" and not shop_name.strip() {
        return AuthResult(ok=False, message="Enter a shop name to register a shop account.");
    }
    profiles = [root -->][?:AccountProfile];
    if len(profiles) > 0 {
        return AuthResult(ok=False, message="A SmartCart role is already assigned to this account.");
    }
    root ++> AccountProfile(role=account_type, display_name=display_name.strip(), shop_name=shop_name.strip());
    destination = "/dashboard/user";
    if account_type == "shop" { destination = "/dashboard/shop"; }
    return AuthResult(ok=True, message="Account profile created", role=account_type, destination=destination);
}

def:protect getAuthenticatedRole() -> AuthResult {
    profiles = [root -->][?:AccountProfile];
    if len(profiles) == 0 {
        return AuthResult(ok=False, message="This account has no SmartCart role profile. Create a user or shop profile after signup, or ask an administrator to provision developer access.");
    }
    account = profiles[0];
    destination = "/dashboard/user";
    if account.role == "shop" { destination = "/dashboard/shop"; }
    elif account.role == "developer" { destination = "/dashboard/developer"; }
    return AuthResult(ok=True, message="Authorized", role=account.role, destination=destination);
}

def:protect authorizeDashboard(requested_role: str) -> AuthResult {
    profiles = [root -->][?:AccountProfile];
    if len(profiles) == 0 {
        return AuthResult(ok=False, message="No application role is assigned. Contact an administrator.");
    }
    actual_role = profiles[0].role;
    if requested_role != actual_role {
        destination = "/dashboard/user";
        if actual_role == "shop" { destination = "/dashboard/shop"; }
        elif actual_role == "developer" { destination = "/dashboard/developer"; }
        return AuthResult(ok=False, message="This dashboard is not available to your account.", role=actual_role, destination=destination);
    }
    return AuthResult(ok=True, message="Authorized", role=actual_role);
}
