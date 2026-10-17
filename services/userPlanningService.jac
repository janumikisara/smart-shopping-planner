import from services.shoppingService { ShopItem, ShoppingRequest, PlanLine, ShoppingPlan, getShopInventory }

node SavedListItem {
    has owner_id: str = "";
    has name: str = "";
    has category: str = "Other";
    has brand: str = "";
    has details: str = "";
    has quantity: int = 1;
}

node PlanningPreference {
    has owner_id: str = "";
    has priority: str = "time";
    has area: str = "Moratuwa";
    has updated_at: str = "";
}

node SavedShoppingPlan {
    has owner_id: str = "";
    has priority: str = "time";
    has area: str = "Moratuwa";
    has item_summary: str = "";
    has total: int = 0;
    has stops: int = 0;
    has explanation: str = "";
    has created_at: str = "";
}

obj PlanResult {
    has plan: ShoppingPlan;
    has alternatives: list[dict];
    has saved: bool;
}

def:protect getShoppingList() -> list[ShoppingRequest] {
    owner = jid(root);
    results: list[ShoppingRequest] = [];
    for stored in [root -->][?:SavedListItem] {
        if stored.owner_id == owner {
            results.append(ShoppingRequest(name=stored.name, category=stored.category, brand=stored.brand, details=stored.details, quantity=stored.quantity));
        }
    }
    return results;
}

def:protect saveShoppingList(items: list[ShoppingRequest]) -> dict {
    owner = jid(root);
    for stored in [root -->][?:SavedListItem] {
        if stored.owner_id == owner { del stored; }
    }
    for item in items {
        if item.name.strip() != "" and item.quantity >= 1 and item.quantity <= 99 {
            root ++> SavedListItem(owner_id=owner, name=item.name.strip(), category=item.category.strip(), brand=item.brand.strip(), details=item.details.strip(), quantity=item.quantity);
        }
    }
    return {"ok": True, "message": "Shopping list saved."};
}

def:protect getPlanningPreferences() -> dict {
    owner = jid(root);
    prefs = [root -->][?:PlanningPreference];
    for preference in prefs {
        if preference.owner_id == owner { return {"priority": preference.priority, "area": preference.area}; }
    }
    return {"priority": "time", "area": "Moratuwa"};
}

def:protect savePlanningPreferences(priority: str, area: str) -> dict {
    if priority != "cost" and priority != "time" and priority != "distance" and priority != "stops" {
        return {"ok": False, "message": "Choose a supported planning priority."};
    }
    owner = jid(root);
    prefs = [root -->][?:PlanningPreference];
    for preference in prefs {
        if preference.owner_id == owner {
            preference.priority = priority;
            preference.area = area.strip() if area.strip() != "" else "Moratuwa";
            preference.updated_at = "Updated just now";
            return {"ok": True, "message": "Preferences saved."};
        }
    }
    root ++> PlanningPreference(owner_id=owner, priority=priority, area=area.strip() if area.strip() != "" else "Moratuwa", updated_at="Updated just now");
    return {"ok": True, "message": "Preferences saved."};
}

def:protect getSavedPlans() -> list[SavedShoppingPlan] {
    owner = jid(root);
    results: list[SavedShoppingPlan] = [];
    for saved in [root -->][?:SavedShoppingPlan] {
        if saved.owner_id == owner { results.append(saved); }
    }
    return results;
}

def:protect createSavedShoppingPlan(items: list[ShoppingRequest], priority: str, area: str) -> PlanResult {
    inventory = getShopInventory();
    lines: list[PlanLine] = [];
    total = 0;
    shops: list[str] = [];
    for item in items {
        if item.name.strip() == "" or item.category.strip() == "" or item.quantity < 1 or item.quantity > 99 { continue; }
        selected: ShopItem | None = None;
        for listing in inventory {
            if listing.name.lower() == item.name.lower() and listing.category == item.category and listing.stock.startswith("In stock") {
                if selected is None { selected = listing; }
                elif priority == "cost" and listing.price < (selected as ShopItem).price { selected = listing; }
            }
        }
        if selected is not None {
            chosen = selected as ShopItem;
            row_total = chosen.price * item.quantity;
            line_details = "";
            if item.brand.strip() { line_details = "Brand: " + item.brand.strip(); }
            if item.details.strip() { line_details = line_details + (" · " if line_details else "") + item.details.strip(); }
            lines.append(PlanLine(item=item.name, shop=chosen.shop, area=chosen.area, price=row_total, stock=chosen.stock, quantity=item.quantity, details=line_details));
            total += row_total;
            if chosen.shop not in shops { shops.append(chosen.shop); }
        }
    }
    why = "Matches exact product name and category against current shop-managed stock. Road distance and travel time are not available.";
    if len(inventory) == 0 { why = "No shop-managed listings are currently published. Add shops or check back later; no simulated prices were used."; }
    elif priority == "cost" { why = "Matched exact products in stock and selected the lowest listed prices where there was a match. Road travel cost is not included."; }
    elif priority == "stops" { why = "Grouped confirmed matches by shop to reduce the number of stops. Road route estimates are unavailable."; }
    elif priority == "distance" { why = "Distance priority selected, but coordinates or road-distance routing are unavailable; matches are grouped without claiming an optimized route."; }
    plan = ShoppingPlan(lines=lines, total=total, stops=len(shops), explanation=why);
    summary: list[str] = [];
    for item in items { summary.append(str(item.quantity) + "x " + item.name); }
    owner = jid(root);
    root ++> SavedShoppingPlan(owner_id=owner, priority=priority, area=area.strip() if area.strip() != "" else "Moratuwa", item_summary="; ".join(summary), total=total, stops=len(shops), explanation=why, created_at="Saved just now");
    return PlanResult(plan=plan, alternatives=[], saved=True);
}
