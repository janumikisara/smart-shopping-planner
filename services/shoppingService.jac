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
    return [
        ShopItem(id="laptop", name="Everyday laptop · 16GB / 512GB", category="Electronics", shop="Moratuwa Tech Hub", area="Katubedda", price=189900, stock="In stock · 2", updated="Updated 25 min ago"),
        ShopItem(id="laptop", name="Everyday laptop · 16GB / 512GB", category="Electronics", shop="Coastal Computers", area="Moratuwa town", price=194500, stock="In stock · 4", updated="Updated 1 hr ago"),
        ShopItem(id="mouse", name="Wireless mouse · silent click", category="Electronics", shop="Moratuwa Tech Hub", area="Katubedda", price=4250, stock="Low stock · 2", updated="Updated 25 min ago"),
        ShopItem(id="mouse", name="Wireless mouse · silent click", category="Electronics", shop="Coastal Computers", area="Moratuwa town", price=3900, stock="In stock · 8", updated="Updated 1 hr ago"),
        ShopItem(id="charger", name="USB-C phone charger · 25W", category="Electronics", shop="Moratuwa Tech Hub", area="Katubedda", price=3200, stock="In stock · 6", updated="Updated 25 min ago"),
        ShopItem(id="charger", name="USB-C phone charger · 25W", category="Electronics", shop="Coastal Computers", area="Moratuwa town", price=2950, stock="Out of stock", updated="Updated 1 hr ago"),
        ShopItem(id="groceries", name="Weekly grocery essentials", category="Groceries", shop="People's Market", area="Rawathawatta", price=5850, stock="In stock · 12", updated="Updated 40 min ago"),
        ShopItem(id="groceries", name="Weekly grocery essentials", category="Groceries", shop="Townside Supermarket", area="Moratuwa town", price=6120, stock="Availability unconfirmed", updated="Updated yesterday")
    ];
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
                if best is None {
                    best = product;
                } else {
                    selected_best = best as ShopItem;
                    if product.price < selected_best.price {
                        best = product;
                    }
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
            if selected.shop not in seen_shops {
                seen_shops.append(selected.shop);
            }
        }
    }
    explanation = "Only exact product-name and category matches with confirmed in-stock demo records are included. Custom brand/specification details are shown but are not verified by demo inventory. Road route times are not available.";
    if priority == "time" {
        explanation = "Exact in-stock matches are grouped by shop. Custom brand/specification details are not verified by demo inventory, and road routing is not connected.";
    }
    return ShoppingPlan(lines=lines, total=total, stops=len(seen_shops), explanation=explanation);
}
