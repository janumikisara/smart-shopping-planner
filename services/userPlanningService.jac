
import from .shoppingService { ShopItem, PlanLine, ShoppingPlan, getShopInventory }

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

obj PlanOption {
    has name: str;
    has focus: str;
    has lines: list[PlanLine];
    has total: int;
    has stops: int;
    has travel_estimate: str;
}

obj PlanResult {
    has plan: ShoppingPlan;
    has alternatives: list[dict];
    has options: list[PlanOption];
    has saved: bool;
}

def _valid_planning_item(item: dict) -> bool {
    return "name" in item and "category" in item and "quantity" in item and str(item["name"]).strip() != "" and int(item["quantity"]) >= 1 and int(item["quantity"]) <= 99;
}

def _normalize_text(value: str) -> str {
    return " ".join(value.lower().replace("stationary", "stationery").replace("&", "and").replace("-", " ").split());
}

def _item_match_score(requested: str, listed: str) -> int {
    wanted = _normalize_text(requested);
    candidate = _normalize_text(listed);
    if wanted == candidate { return 100; }
    score = 0;
    for word in wanted.split() {
        if len(word) > 1 and word in candidate { score += 3; }
        elif len(word) > 3 {
            for candidate_word in candidate.split() {
                if len(candidate_word) > 3 and candidate_word[0] == word[0] and (word in candidate_word or candidate_word in word) { score += 2; }
            }
        }
    }
    return score;
}

def _category_synonym_match(requested: str, listed: str) -> bool {
    wanted = _normalize_text(requested);
    candidate = _normalize_text(listed);
    if wanted == "computers and accessories" and ("computer" in candidate or "laptop" in candidate) { return True; }
    if wanted == "mobile phones" and ("phone" in candidate or "mobile" in candidate or "charger" in candidate) { return True; }
    if wanted == "stationery" and ("stationery" in candidate or "stationary" in candidate or "school" in candidate or "office" in candidate) { return True; }
    if wanted == "household" and ("household" in candidate or "home" in candidate or "grocery" in candidate) { return True; }
    return False;
}

def:protect getShoppingList() -> list[dict] {
    owner = jid(root);
    results: list[dict] = [];
    for stored in [root -->][?:SavedListItem] {
        if stored.owner_id == owner { results.append({"name": stored.name, "category": stored.category, "brand": stored.brand, "details": stored.details, "quantity": stored.quantity}); }
    }
    return results;
}

def:protect saveShoppingList(items: list[dict]) -> dict {
    owner = jid(root);
    for stored in [root -->][?:SavedListItem] { if stored.owner_id == owner { del stored; } }
    for item in items {
        if _valid_planning_item(item) {
            root ++> SavedListItem(owner_id=owner, name=str(item["name"]).strip(), category=str(item["category"]).strip(), brand=str(item["brand"]) if "brand" in item else "", details=str(item["details"]) if "details" in item else "", quantity=int(item["quantity"]));
        }
    }
    return {"ok": True, "message": "Shopping list saved."};
}

def:protect getPlanningPreferences() -> dict {
    owner = jid(root);
    for preference in [root -->][?:PlanningPreference] { if preference.owner_id == owner { return {"priority": preference.priority, "area": preference.area}; } }
    return {"priority": "cost", "area": "Moratuwa"};
}

def:protect savePlanningPreferences(priority: str, area: str) -> dict {
    if priority != "cost" and priority != "time" and priority != "distance" and priority != "stops" { return {"ok": False, "message": "Choose a supported planning priority."}; }
    owner = jid(root);
    for preference in [root -->][?:PlanningPreference] {
        if preference.owner_id == owner { preference.priority = priority; preference.area = area.strip() if area.strip() != "" else "Moratuwa"; preference.updated_at = "Updated just now"; return {"ok": True, "message": "Preferences saved."}; }
    }
    root ++> PlanningPreference(owner_id=owner, priority=priority, area=area.strip() if area.strip() != "" else "Moratuwa", updated_at="Updated just now");
    return {"ok": True, "message": "Preferences saved."};
}

def _saved_plan_created_at(saved_plan: SavedShoppingPlan) -> str { return saved_plan.created_at; }

def:protect getSavedPlans() -> list[SavedShoppingPlan] {
    owner = jid(root);
    results: list[SavedShoppingPlan] = [];
    for saved in [root -->][?:SavedShoppingPlan] { if saved.owner_id == owner { results.append(saved); } }
    results.sort(key=_saved_plan_created_at, reverse=True);
    return results;
}

def:protect createSavedShoppingPlan(items: list[dict], priority: str, area: str, selected_option: str = "") -> PlanResult {
    inventory = getShopInventory();
    cheapest_lines: list[PlanLine] = [];
    convenience_lines: list[PlanLine] = [];
    backup_lines: list[PlanLine] = [];
    alternatives: list[dict] = [];
    cheapest_total = 0;
    convenience_total = 0;
    backup_total = 0;
    cheapest_stops: list[str] = [];
    convenience_stops: list[str] = [];
    backup_stops: list[str] = [];
    for request in items {
        if not _valid_planning_item(request) or not ("category" in request) { continue; }
        request_name = str(request["name"]).strip();
        request_category = str(request["category"]).strip();
        request_quantity = int(request["quantity"]);
        request_brand = str(request["brand"]) if "brand" in request else "";
        request_details = str(request["details"]) if "details" in request else "";
        if request_brand.strip() != "" {
            brand_tokens = request_brand.split();
            if len(brand_tokens) > 1 { request_brand = brand_tokens[0]; request_details = " ".join(brand_tokens[1:]) + " " + request_details; }
        }
        matches: list[ShopItem] = [];
        for listing in inventory {
            score = _item_match_score(request_name + " " + request_details, listing.name);
            category_ok = _normalize_text(request_category) == _normalize_text(listing.category) or _category_synonym_match(request_category, listing.category);
            if category_ok and score >= 3 and listing.stock.startswith("In stock") { matches.append(listing); }
        }
        if len(matches) == 0 { continue; }
        low: ShopItem | None = None;
        for candidate in matches { if low is None or candidate.price < (low as ShopItem).price { low = candidate; } }
        cheapest = low as ShopItem;
        preferred: ShopItem | None = None;
        for candidate in matches {
            if candidate.shop in convenience_stops { preferred = candidate; }
        }
        if preferred is None { preferred = matches[0]; }
        convenient = preferred as ShopItem;
        alternate = cheapest;
        if len(matches) > 1 { alternate = matches[1]; }
        for candidate in matches {
            if candidate.shop != convenient.shop { alternatives.append({"item": request_name, "matched_name": candidate.name, "shop": candidate.shop, "area": candidate.area, "price": candidate.price * request_quantity, "stock": candidate.stock}); }
        }
        details = "";
        if request_brand.strip() { details = "Brand/model preference: " + request_brand.strip(); }
        if request_details.strip() { details = details + (" · " if details else "") + request_details.strip(); }
        cheapest_lines.append(PlanLine(item=request_name + " → " + cheapest.name, shop=cheapest.shop, area=cheapest.area, price=cheapest.price * request_quantity, stock=cheapest.stock, quantity=request_quantity, details=details));
        convenience_lines.append(PlanLine(item=request_name + " → " + convenient.name, shop=convenient.shop, area=convenient.area, price=convenient.price * request_quantity, stock=convenient.stock, quantity=request_quantity, details=details));
        backup_lines.append(PlanLine(item=request_name + " → " + alternate.name, shop=alternate.shop, area=alternate.area, price=alternate.price * request_quantity, stock=alternate.stock, quantity=request_quantity, details=details));
        cheapest_total += cheapest.price * request_quantity;
        convenience_total += convenient.price * request_quantity;
        backup_total += alternate.price * request_quantity;
        if cheapest.shop not in cheapest_stops { cheapest_stops.append(cheapest.shop); }
        if convenient.shop not in convenience_stops { convenience_stops.append(convenient.shop); }
        if alternate.shop not in backup_stops { backup_stops.append(alternate.shop); }
    }
    chosen_lines = cheapest_lines;
    chosen_total = cheapest_total;
    chosen_stops = cheapest_stops;
    if priority == "time" or priority == "distance" or priority == "stops" { chosen_lines = convenience_lines; chosen_total = convenience_total; chosen_stops = convenience_stops; }
    if selected_option == "Plan A · Convenience" { chosen_lines = convenience_lines; chosen_total = convenience_total; chosen_stops = convenience_stops; }
    elif selected_option == "Plan B · Lowest price" { chosen_lines = cheapest_lines; chosen_total = cheapest_total; chosen_stops = cheapest_stops; }
    elif selected_option == "Plan C · Backup" { chosen_lines = backup_lines; chosen_total = backup_total; chosen_stops = backup_stops; }
    elif selected_option != "" { return PlanResult(plan=ShoppingPlan(lines=[], total=0, stops=0, explanation="Unknown plan option."), alternatives=[], options=[], saved=False); }
    explanation = "Three plans are generated from current shop-managed in-stock records. Plan A groups purchases to reduce shop visits; Plan B chooses the lowest listed unit price; Plan C uses alternate available listings where possible. Travel time and road distance are unavailable because no routing service is connected; no travel estimate is invented. Prices are shop-provided and may change.";
    if len(inventory) == 0 { explanation = "No shop-managed listings are currently published. No prices or recommendations were fabricated."; }
    chosen_plan = ShoppingPlan(lines=chosen_lines, total=chosen_total, stops=len(chosen_stops), explanation=explanation);
    options: list[PlanOption] = [];
    options.append(PlanOption(name="Plan A · Convenience", focus="Group purchases at shared shops to reduce visits", lines=convenience_lines, total=convenience_total, stops=len(convenience_stops), travel_estimate="Not available · road routing is not connected"));
    options.append(PlanOption(name="Plan B · Lowest price", focus="Choose the lowest listed in-stock price per item", lines=cheapest_lines, total=cheapest_total, stops=len(cheapest_stops), travel_estimate="Not available · road routing is not connected"));
    options.append(PlanOption(name="Plan C · Backup", focus="Use alternative available shop listings where possible", lines=backup_lines, total=backup_total, stops=len(backup_stops), travel_estimate="Not available · road routing is not connected"));
    summary: list[str] = [];
    for requested in items { if _valid_planning_item(requested) { summary.append(str(requested["quantity"]) + "x " + str(requested["name"])); } }
    root ++> SavedShoppingPlan(owner_id=jid(root), priority=priority, area=area.strip() if area.strip() != "" else "Moratuwa", item_summary="; ".join(summary), total=chosen_total, stops=len(chosen_stops), explanation=explanation, created_at="Saved just now", route_stops=chosen_stops);
    return PlanResult(plan=chosen_plan, alternatives=alternatives, options=options, saved=True);
}
