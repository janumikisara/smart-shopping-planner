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

obj PlanLine {
    has item: str;
    has shop: str;
    has area: str;
    has price: int;
    has stock: str;
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

def:pub generateShoppingPlan(items: list[str], priority: str) -> ShoppingPlan {
    inventory = getShopInventory();
    lines: list[PlanLine] = [];
    total = 0;
    seen_shops: list[str] = [];
    for item in items {
        best: ShopItem | None = None;
        for product in inventory {
            if product.id == item and product.stock.startswith("In stock") {
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
            lines.append(PlanLine(item=selected.name, shop=selected.shop, area=selected.area, price=selected.price, stock=selected.stock));
            total += selected.price;
            if selected.shop not in seen_shops {
                seen_shops.append(selected.shop);
            }
        }
    }
    explanation = "Lowest listed prices among demo shops with confirmed stock. Route times are not available yet, so this is a shop grouping, not a road route.";
    if priority == "time" {
        explanation = "Grouped purchases by shop to limit stops. Road routing is not connected, so travel-time optimization is not claimed.";
    }
    return ShoppingPlan(lines=lines, total=total, stops=len(seen_shops), explanation=explanation);
}
