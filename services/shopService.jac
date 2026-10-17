import from authService { AccountProfile }

node ShopProfile {
    has account_id: str = "";
    has shop_name: str = "";
    has category: str = "Other";
    has address: str = "";
    has contact: str = "";
    has description: str = "";
    has latitude: float = 0.0;
    has longitude: float = 0.0;
    has updated_at: str = "";
}

node InventoryEntry {
    has account_id: str = "";
    has shop_name: str = "";
    has product_name: str = "";
    has brand: str = "";
    has model: str = "";
    has category: str = "Other";
    has description: str = "";
    has price_lkr: int = 0;
    has quantity: int = 0;
    has stock_status: str = "Availability unconfirmed";
    has source: str = "Shop managed";
    has updated_at: str = "";
}

def _shop_role_ok() -> bool {
    accounts = [root -->][?:AccountProfile];
    return len(accounts) > 0 and accounts[0].role == "shop" and accounts[0].account_id == jid(root);
}

def:protect getShopProfile() -> ShopProfile | None {
    if not _shop_role_ok() { return None; }
    profiles = [root -->][?:ShopProfile];
    if len(profiles) == 0 { return None; }
    return profiles[0];
}

def:protect saveShopProfile(shop_name: str, category: str, address: str, contact: str, description: str, latitude: float, longitude: float) -> dict {
    if not _shop_role_ok() { return {"ok": False, "message": "Shop role required."}; }
    if shop_name.strip() == "" or address.strip() == "" { return {"ok": False, "message": "Shop name and address are required."}; }
    if latitude < -90.0 or latitude > 90.0 or longitude < -180.0 or longitude > 180.0 { return {"ok": False, "message": "Enter valid latitude and longitude coordinates."}; }
    accounts = [root -->][?:AccountProfile];
    profiles = [root -->][?:ShopProfile];
    if len(profiles) > 0 {
        profiles[0].shop_name = shop_name.strip();
        profiles[0].category = category.strip();
        profiles[0].address = address.strip();
        profiles[0].contact = contact.strip();
        profiles[0].description = description.strip();
        profiles[0].latitude = latitude;
        profiles[0].longitude = longitude;
        profiles[0].updated_at = "Updated just now";
    } else {
        new_profile = root ++> ShopProfile(account_id=accounts[0].account_id, shop_name=shop_name.strip(), category=category.strip(), address=address.strip(), contact=contact.strip(), description=description.strip(), latitude=latitude, longitude=longitude, updated_at="Updated just now");
        grant(new_profile, level=ReadPerm);
    }
    for profile in [root -->][?:ShopProfile] {
        grant(profile, level=ReadPerm);
    }
    return {"ok": True, "message": "Shop profile saved."};
}

def:protect listOwnInventory() -> list[InventoryEntry] {
    if not _shop_role_ok() { return []; }
    owned: list[InventoryEntry] = [];
    account_id = jid(root);
    for entry in [root -->][?:InventoryEntry] {
        if entry.account_id == account_id { owned.append(entry); }
    }
    return owned;
}

def:protect addInventoryEntry(product_name: str, brand: str, model: str, category: str, description: str, price_lkr: int, quantity: int, stock_status: str) -> dict {
    if not _shop_role_ok() { return {"ok": False, "message": "Shop role required."}; }
    if product_name.strip() == "" or price_lkr < 0 or quantity < 0 { return {"ok": False, "message": "Enter a product name and non-negative price and quantity."}; }
    if stock_status != "In stock" and stock_status != "Low stock" and stock_status != "Out of stock" and stock_status != "Availability unconfirmed" { return {"ok": False, "message": "Choose a supported availability status."}; }
    profiles = [root -->][?:ShopProfile];
    if len(profiles) == 0 { return {"ok": False, "message": "Save your shop profile before adding inventory."}; }
    new_entry = root ++> InventoryEntry(account_id=jid(root), shop_name=profiles[0].shop_name, product_name=product_name.strip(), brand=brand.strip(), model=model.strip(), category=category.strip(), description=description.strip(), price_lkr=price_lkr, quantity=quantity, stock_status=stock_status, source="Shop managed", updated_at="Updated just now");
    grant(new_entry, level=ReadPerm);
    return {"ok": True, "message": "Inventory item added."};
}

def:protect updateInventoryEntry(entry_id: str, product_name: str, brand: str, model: str, category: str, description: str, price_lkr: int, quantity: int, stock_status: str) -> dict {
    if not _shop_role_ok() { return {"ok": False, "message": "Shop role required."}; }
    if price_lkr < 0 or quantity < 0 { return {"ok": False, "message": "Price and quantity cannot be negative."}; }
    if stock_status != "In stock" and stock_status != "Low stock" and stock_status != "Out of stock" and stock_status != "Availability unconfirmed" { return {"ok": False, "message": "Choose a supported availability status."}; }
    for entry in [root -->][?:InventoryEntry] {
        if jid(entry) == entry_id and entry.account_id == jid(root) {
            entry.product_name = product_name.strip();
            entry.brand = brand.strip();
            entry.model = model.strip();
            entry.category = category.strip();
            entry.description = description.strip();
            entry.price_lkr = price_lkr;
            entry.quantity = quantity;
            entry.stock_status = stock_status;
            entry.updated_at = "Updated just now";
            profiles = [root -->][?:ShopProfile];
            if len(profiles) > 0 { entry.shop_name = profiles[0].shop_name; }
            return {"ok": True, "message": "Inventory item updated."};
        }
    }
    return {"ok": False, "message": "Inventory item was not found in this shop."};
}

def:protect deleteInventoryEntry(entry_id: str) -> dict {
    if not _shop_role_ok() { return {"ok": False, "message": "Shop role required."}; }
    for entry in [root -->][?:InventoryEntry] {
        if jid(entry) == entry_id and entry.account_id == jid(root) {
            del entry;
            return {"ok": True, "message": "Inventory item removed."};
        }
    }
    return {"ok": False, "message": "Inventory item was not found in this shop."};
}

def:pub getPublicShopProfile(account_id: str) -> ShopProfile | None {
    for account_root in allroots() {
        if jid(account_root) == account_id {
            profiles = [account_root -->][?:ShopProfile];
            if len(profiles) > 0 { return profiles[0]; }
        }
    }
    return None;
}

def:pub listShopInventory() -> list[InventoryEntry] {
    entries: list[InventoryEntry] = [];
    for account_root in allroots() {
        for account in [account_root -->][?:AccountProfile] {
            if account.role == "shop" and account.account_id == jid(account_root) {
                for entry in [account_root -->][?:InventoryEntry] {
                    if entry.account_id == account.account_id and entry.stock_status != "Out of stock" {
                        entries.append(entry);
                    }
                }
            }
        }
    }
    return entries;
}
