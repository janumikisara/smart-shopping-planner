import from services.shoppingService { ShopItem, PlanLine, ShoppingPlan, getShopInventory }

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
    has priority: str = "cost";
    has area: str = "Moratuwa";
    has updated_at: str = "";
}

node SavedShoppingPlan {
    has owner_id: str = "";
    has priority: str = "cost";
    has area: str = "Moratuwa";
    has item_summary: str = "";
    has total: int = 0;
    has stops: int = 0;
    has explanation: str = "";
    has created_at: str = "";
    has route_stops: list[str] = [];
}

obj PlanResult {
    has plan: ShoppingPlan;
    has alternatives: list[dict];
    has saved: bool;
}

def _valid_planning_item(item: dict) -> bool {
    return "name" in item and "category" in item and "quantity" in item and str(item["name"]).strip() != "" and int(item["quantity"]) >= 1 and int(item["quantity"]) <= 99;
}

def:protect getShoppingList() -> list[dict] {
    owner = jid(root);
    results: list[dict] = [];
    for stored in [root -->][?:SavedListItem] {
        if stored.owner_id == owner {
            results.append({"name": stored.name, "category": stored.category, "brand": stored.brand, "details": stored.details, "quantity": stored.quantity});
        }
    }
    return results;
}

def:protect saveShoppingList(items: list[dict]) -> dict {
    owner = jid(root);
    for stored in [root -->][?:SavedListItem] {
        if stored.owner_id == owner { del stored; }
    }
    for item in items {
        if _valid_planning_item(item) {
            root ++> SavedListItem(owner_id=owner, name=str(item["name"]).strip(), category=str(item["category"]).strip(), brand=str(item["brand"]) if "brand" in item else "", details=str(item["details"]) if "details" in item else "", quantity=int(item["quantity"]));
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
    return {"priority": "cost", "area": "Moratuwa"};
}

def:protect savePlanningPreferences(priority: str, area: str) -> dict {
    if priority != "cost" and priority != "time" and priority != "distance" and priority != "stops" { return {"ok": False, "message": "Choose a supported planning priority."}; }
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

def _saved_plan_created_at(saved_plan: SavedShoppingPlan) -> str { return saved_plan.created_at; }

def:protect getSavedPlans() -> list[SavedShoppingPlan] {
    owner = jid(root);
    results: list[SavedShoppingPlan] = [];
    for saved in [root -->][?:SavedShoppingPlan] {
        if saved.owner_id == owner { results.append(saved); }
    }
    results.sort(key=_saved_plan_created_at, reverse=True);
    return results;
}

def:protect createSavedShoppingPlan(items: list[dict], priority: str, area: str) -> PlanResult {
    inventory = getShopInventory();
    lines: list[PlanLine] = [];
    alternatives: list[dict] = [];
    total = 0;
    route_stops: list[str] = [];
    for request in items {
        if not _valid_planning_item(request) or not ("category" in request) { continue; }
        request_name = str(request["name"]).strip();
        request_category = str(request["category"]).strip();
        request_quantity = int(request["quantity"]);
        request_brand = str(request["brand"]) if "brand" in request else "";
        request_details = str(request["details"]) if "details" in request else "";
        cheapest: ShopItem | None = None;
        first_available: ShopItem | None = None;
        matching: list[ShopItem] = [];
        for listing in inventory {
            if listing.name.lower() == request_name.lower() and listing.category == request_category and listing.stock.startswith("In stock") {
                matching.append(listing);
                if first_available is None { first_available = listing; }
                if cheapest is None { cheapest = listing; }
                else { if listing.price < (cheapest as ShopItem).price { cheapest = listing; } }
            }
        }
        selected: ShopItem | None = first_available;
        if priority == "cost" { selected = cheapest; }
        elif priority == "stops" and len(route_stops) > 0 {
            for listing in matching { if listing.shop in route_stops { selected = listing; } }
        }
        if selected is not None {
            chosen = selected as ShopItem;
            line_total = chosen.price * request_quantity;
            line_details = "";
            if request_brand.strip() { line_details = "Brand: " + request_brand.strip(); }
            if request_details.strip() { line_details = line_details + (" · " if line_details else "") + request_details.strip(); }
            lines.append(PlanLine(item=request_name, shop=chosen.shop, area=chosen.area, price=line_total, stock=chosen.stock, quantity=request_quantity, details=line_details));
            total += line_total;
            if chosen.shop not in route_stops { route_stops.append(chosen.shop); }
            for alternative in matching {
                if alternative.shop != chosen.shop { alternatives.append({"item": request_name, "shop": alternative.shop, "area": alternative.area, "price": alternative.price * request_quantity, "stock": alternative.stock}); }
            }
        }
    }
    explanation = "Plan uses current shop-managed listings and the selected " + priority + " priority. Road routing and travel-time estimates are not connected.";
    if len(inventory) == 0 { explanation = "No shop-managed listings are currently published. No simulated prices were used."; }
    plan = ShoppingPlan(lines=lines, total=total, stops=len(route_stops), explanation=explanation);
    summary: list[str] = [];
    for requested in items { if _valid_planning_item(requested) { summary.append(str(requested["quantity"]) + "x " + str(requested["name"])); } }
    root ++> SavedShoppingPlan(owner_id=jid(root), priority=priority, area=area.strip() if area.strip() != "" else "Moratuwa", item_summary="; ".join(summary), total=total, stops=len(route_stops), explanation=explanation, created_at="Saved just now", route_stops=route_stops);
    return PlanResult(plan=plan, alternatives=alternatives, saved=True);
}
