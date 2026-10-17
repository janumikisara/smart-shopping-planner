import from services.shopService { ShopProfile, InventoryEntry, listShopInventory, getPublicShopProfile }

obj ShopItem {
    has id: str;
    has name: str;
    has category: str;
    has shop: str;
    has area: str;
    has price: int;
    has stock: str;
    has updated: str;
}

obj ShoppingRequest {
    has name: str;
    has category: str;
    has brand: str = "";
    has details: str = "";
    has quantity: int = 1;
}

obj PlanLine {
    has item: str;
    has shop: str;
    has area: str;
    has price: int;
    has stock: str;
    has quantity: int = 1;
    has details: str = "";
}

obj ShoppingPlan {
    has lines: list[PlanLine];
    has total: int;
    has stops: int;
    has explanation: str;
}

def:pub getShopInventory() -> list[ShopItem] {
    records = listShopInventory();
    listings: list[ShopItem] = [];
    for record in records {
        if record.stock_status != "Out of stock" {
            product_name = record.product_name;
            if record.brand.strip() { product_name = product_name + " · " + record.brand.strip(); }
            if record.model.strip() { product_name = product_name + " " + record.model.strip(); }
            shop_area = "Address not provided";
            profile = getPublicShopProfile(record.account_id);
            if profile is not None { shop_area = profile.address; }
            listings.append(ShopItem(id=jid(record), name=product_name, category=record.category, shop=record.shop_name, area=shop_area, price=record.price_lkr, stock=record.stock_status + " · Qty " + str(record.quantity), updated=record.updated_at));
        }
    }
    return listings;
}

def:pub generateShoppingPlan(items: list[ShoppingRequest], priority: str) -> ShoppingPlan {
    inventory = getShopInventory();
    lines: list[PlanLine] = [];
    total = 0;
    seen_shops: list[str] = [];
    for request in items {
        request_name = request.name.strip();
        request_category = request.category.strip();
        if request_name == "" or request_category == "" or request.quantity < 1 or request.quantity > 99 { continue; }
        best: ShopItem | None = None;
        for product in inventory {
            if product.name.lower() == request_name.lower() and product.category == request_category and product.stock.startswith("In stock") {
                if best is None { best = product; }
                else {
                    selected_best = best as ShopItem;
                    if product.price < selected_best.price { best = product; }
                }
            }
        }
        if best is not None {
            selected = best as ShopItem;
            line_total = selected.price * request.quantity;
            line_details = "";
            if request.brand.strip() { line_details = "Brand: " + request.brand.strip(); }
            if request.details.strip() {
                if line_details { line_details = line_details + " · "; }
                line_details = line_details + request.details.strip();
            }
            lines.append(PlanLine(item=request_name, shop=selected.shop, area=selected.area, price=line_total, quantity=request.quantity, details=line_details, stock=selected.stock));
            total += line_total;
            if selected.shop not in seen_shops { seen_shops.append(selected.shop); }
        }
    }
    explanation = "Plans use current shop-managed listings. Price, stock, quantity, and update time are provided by the shop. Travel routing estimates are unavailable.";
    if len(inventory) == 0 { explanation = "No shop-managed inventory is currently published. Ask a Moratuwa shop to add product listings before generating a matched plan."; }
    elif priority == "time" { explanation = "Exact in-stock listings are grouped by shop. Shop details and custom specifications are shown, but road travel routing is not connected."; }
    return ShoppingPlan(lines=lines, total=total, stops=len(seen_shops), explanation=explanation);
}
