node AccountProfile {
    has account_id: str = "";
    has role: str = "user";
    has display_name: str = "";
    has shop_name: str = "";
}

def:protect createUserProfile() -> dict {
    profiles = [root -->][?:AccountProfile];
    if len(profiles) > 0 {
        existing = profiles[0];
        if existing.account_id != jid(root) {
            return {"ok": False, "message": "Stored profile does not match this account.", "destination": ""};
        }
        if existing.role != "user" {
            return {"ok": False, "message": "This account already has a different SmartCart role.", "destination": ""};
        }
        return {"ok": True, "message": "User profile already exists", "role": "user", "destination": "/dashboard/user"};
    }
    root ++> AccountProfile(account_id=jid(root), role="user");
    return {"ok": True, "message": "User profile created", "role": "user", "destination": "/dashboard/user"};
}

def:protect registerAccount(account_type: str, display_name: str, shop_name: str) -> dict {
    if account_type != "user" and account_type != "shop" {
        return {"ok": False, "message": "Developer accounts require administrator provisioning.", "destination": ""};
    }
    if account_type == "shop" and not shop_name.strip() {
        return {"ok": False, "message": "Enter a shop name to register a shop account.", "destination": ""};
    }
    profiles = [root -->][?:AccountProfile];
    if len(profiles) > 0 {
        existing = profiles[0];
        destination = "/dashboard/user";
        if existing.role == "shop" { destination = "/dashboard/shop"; }
        elif existing.role == "developer" { destination = "/dashboard/developer"; }
        return {"ok": True, "message": "Account profile already exists", "role": existing.role, "destination": destination};
    }
    root ++> AccountProfile(account_id=jid(root), role=account_type, display_name=display_name.strip(), shop_name=shop_name.strip());
    destination = "/dashboard/user";
    if account_type == "shop" { destination = "/dashboard/shop"; }
    return {"ok": True, "message": "Account profile created", "role": account_type, "destination": destination};
}

def:protect getAuthenticatedRole() -> dict {
    profiles = [root -->][?:AccountProfile];
    if len(profiles) == 0 {
        return {"ok": False, "message": "This account has no SmartCart role profile.", "destination": ""};
    }
    account = profiles[0];
    destination = "/dashboard/user";
    if account.role == "shop" { destination = "/dashboard/shop"; }
    elif account.role == "developer" { destination = "/dashboard/developer"; }
    return {"ok": True, "message": "Authorized", "role": account.role, "destination": destination};
}

def:protect authorizeDashboard(requested_role: str) -> dict {
    profiles = [root -->][?:AccountProfile];
    if len(profiles) == 0 {
        return {"ok": False, "message": "No application role is assigned.", "destination": ""};
    }
    actual_role = profiles[0].role;
    if requested_role != actual_role {
        destination = "/dashboard/user";
        if actual_role == "shop" { destination = "/dashboard/shop"; }
        elif actual_role == "developer" { destination = "/dashboard/developer"; }
        return {"ok": False, "message": "This dashboard is not available to your account.", "role": actual_role, "destination": destination};
    }
    return {"ok": True, "message": "Authorized", "role": actual_role, "destination": ""};
}
