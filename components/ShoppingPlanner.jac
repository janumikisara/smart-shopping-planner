sv import from ..services.shoppingService { ShopItem, PlanLine, ShoppingPlan, getShopInventory, generateShoppingPlan }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.button { Button }
import from .ui.input { Input }
import from .ui.badge { Badge }

def:pub ShoppingPlanner() -> JsxElement {
    has inventory: list[ShopItem] = [],
        selected_items: list[dict] = [
            {"name": "Everyday laptop · 16GB / 512GB", "category": "Electronics", "brand": "", "details": "", "quantity": 1},
            {"name": "Wireless mouse · silent click", "category": "Electronics", "brand": "", "details": "", "quantity": 1},
            {"name": "USB-C phone charger · 25W", "category": "Electronics", "brand": "", "details": "", "quantity": 1},
            {"name": "Weekly grocery essentials", "category": "Groceries", "brand": "", "details": "", "quantity": 1}
        ],
        plan: ShoppingPlan | None = None,
        item_name: str = "",
        item_category: str = "Other",
        item_brand: str = "",
        item_details: str = "",
        item_quantity: str = "1",
        form_error: str = "",
        priority: str = "time";

    async can with entry {
        inventory = await getShopInventory();
    }

    def handle_item_name(e: ChangeEvent) { item_name = e.target.value; form_error = ""; }
    def handle_item_category(e: ChangeEvent) { item_category = e.target.value; }
    def handle_item_brand(e: ChangeEvent) { item_brand = e.target.value; }
    def handle_item_details(e: ChangeEvent) { item_details = e.target.value; }
    def handle_item_quantity(e: ChangeEvent) { item_quantity = e.target.value; form_error = ""; }
    def handle_priority(e: ChangeEvent) { priority = e.target.value; }

    def add_item(e: FormEvent) {
        e.preventDefault();
        clean_name = item_name.strip();
        if not clean_name {
            form_error = "Enter a product name.";
            return;
        }
        quantity_value = 1;
        try {
            quantity_value = int(item_quantity);
        } except ValueError {
            form_error = "Enter a whole-number quantity from 1 to 99.";
            return;
        }
        if quantity_value < 1 or quantity_value > 99 {
            form_error = "Quantity must be between 1 and 99.";
            return;
        }
        duplicate = False;
        for existing in selected_items {
            if existing["name"] == clean_name and existing["category"] == item_category and existing["brand"] == item_brand.strip() and existing["details"] == item_details.strip() {
                duplicate = True;
            }
        }
        if duplicate {
            form_error = "That exact item is already on your list. Change its details to add a separate item.";
            return;
        }
        selected_items = selected_items + [{"name": clean_name, "category": item_category, "brand": item_brand.strip(), "details": item_details.strip(), "quantity": quantity_value}];
        plan = None;
        item_name = "";
        item_brand = "";
        item_details = "";
        item_quantity = "1";
        form_error = "";
    }

    def remove_item(item: dict) {
        selected_items = [value for value in selected_items if not (value["name"] == item["name"] and value["category"] == item["category"] and value["brand"] == item["brand"] and value["details"] == item["details"])];
        plan = None;
    }

    async def make_plan {
        plan = await generateShoppingPlan(selected_items, priority);
    }

    return <div className="min-h-svh bg-muted/40">
        <header className="border-b bg-background"><div className="mx-auto flex h-16 w-full max-w-7xl items-center justify-between px-5 sm:px-8"><div className="flex items-center gap-3"><div className="flex size-9 items-center justify-center rounded-xl bg-primary text-primary-foreground font-semibold">S</div><div><p className="font-semibold tracking-tight">SmartCart</p><p className="text-xs text-muted-foreground">Shopping planner</p></div></div><Badge variant="secondary">Moratuwa demo</Badge></div></header>
        <main className="mx-auto flex w-full max-w-7xl flex-col gap-6 px-5 py-8 sm:px-8">
            <section className="flex flex-wrap items-end justify-between gap-4"><div className="flex flex-col gap-2"><p className="text-sm font-medium text-primary">PLAN A BETTER SHOPPING TRIP</p><h1 className="text-3xl font-semibold tracking-tight sm:text-4xl">Your list, thoughtfully planned.</h1><p className="max-w-2xl text-muted-foreground">Compare demo inventory from Moratuwa shops and group your purchases before you head out.</p></div><div className="rounded-xl border bg-card px-4 py-3 shadow-sm"><p className="text-xs text-muted-foreground">Planning area</p><p className="font-medium">Moratuwa, Sri Lanka</p></div></section>
            <div className="grid gap-5 lg:grid-cols-[0.9fr_1.1fr]">
                <Card className="shadow-sm">
                    <CardHeader><CardTitle>Shopping list</CardTitle><CardDescription>Add a product with its category, brand, specifications, and quantity.</CardDescription></CardHeader>
                    <CardContent className="flex flex-col gap-5">
                        <form onSubmit={add_item} className="flex flex-col gap-4">
                            <div className="flex flex-col gap-2"><label htmlFor="item-name" className="text-sm font-medium">Product name</label><Input id="item-name" aria-label="Product name" value={item_name} onChange={handle_item_name} placeholder="Enter the exact product name" /></div>
                            <div className="grid gap-4 sm:grid-cols-2">
                                <div className="flex flex-col gap-2"><label htmlFor="item-category" className="text-sm font-medium">Category</label><select id="item-category" value={item_category} onChange={handle_item_category} className="h-10 rounded-md border border-input bg-background px-3 text-sm"><option>Electronics</option><option>Computers & accessories</option><option>Mobile phones</option><option>Groceries</option><option>Clothing</option><option>Footwear</option><option>Stationery</option><option>Household</option><option>Hardware</option><option>Other</option></select></div>
                                <div className="flex flex-col gap-2"><label htmlFor="item-quantity" className="text-sm font-medium">Quantity</label><Input id="item-quantity" type="number" min="1" max="99" value={item_quantity} onChange={handle_item_quantity} /></div>
                            </div>
                            <div className="grid gap-4 sm:grid-cols-2">
                                <div className="flex flex-col gap-2"><label htmlFor="item-brand" className="text-sm font-medium">Preferred brand</label><Input id="item-brand" value={item_brand} onChange={handle_item_brand} placeholder="Optional brand" /></div>
                                <div className="flex flex-col gap-2"><label htmlFor="item-details" className="text-sm font-medium">Specifications or details</label><Input id="item-details" value={item_details} onChange={handle_item_details} placeholder="Model, size, color, or notes" /></div>
                            </div>
                            {form_error and <p role="alert" className="rounded-md border border-destructive/30 bg-destructive/5 p-3 text-sm text-destructive">{form_error}</p>}
                            <Button type="submit" variant="outline" className="w-full sm:w-fit">Add item to list</Button>
                        </form>
                        <div className="flex flex-col gap-2">
                            {if len(selected_items) == 0 {<div className="rounded-lg border border-dashed bg-background p-5"><p className="font-medium">Your list is empty</p><p className="mt-1 text-sm text-muted-foreground">Add a product above to start planning.</p></div>}}
                            {for (index, item) in enumerate(selected_items) {
                                <div key={str(index)} className="flex items-start justify-between gap-3 rounded-lg border bg-background px-3 py-3">
                                    <div className="min-w-0"><p className="font-medium">{item["name"]}</p><p className="text-xs text-muted-foreground">{item["category"]} · Qty {str(item["quantity"])}</p>{item["brand"] and <p className="text-xs text-muted-foreground">Brand: {item["brand"]}</p>}{item["details"] and <p className="text-xs text-muted-foreground">{item["details"]}</p>}</div>
                                    <button type="button" onClick={lambda { remove_item(item); }} className="shrink-0 rounded-md px-2 py-1 text-sm text-muted-foreground hover:bg-muted">Remove</button>
                                </div>
                            }}
                        </div>
                        <div className="flex flex-col gap-2"><label htmlFor="priority" className="text-sm font-medium">Planning priority</label><select id="priority" value={priority} onChange={handle_priority} className="h-10 rounded-md border border-input bg-background px-3 text-sm"><option value="time">Fewer stops · time-aware fallback</option><option value="cost">Lowest confirmed item prices</option></select><p className="text-xs text-muted-foreground">Road routing and calendar integration are not connected; estimates are clearly labeled.</p></div>
                        <Button onClick={make_plan} disabled={len(selected_items) == 0} className="h-11 w-full shadow-sm">Generate shopping plan</Button>
                    </CardContent>
                </Card>
                <div className="flex flex-col gap-5">
                    {if plan is not None {chosen = plan as ShoppingPlan;<Card className="border-primary/30 shadow-sm"><CardHeader><div className="flex flex-wrap items-start justify-between gap-3"><div><CardTitle>Your suggested plan</CardTitle><CardDescription>Grouped using exact product name and category matches</CardDescription></div><Badge variant="secondary">Estimate · simulated data</Badge></div></CardHeader><CardContent className="flex flex-col gap-4">
                        {if len(chosen.lines) == 0 {<div className="rounded-lg border border-dashed p-5 text-sm text-muted-foreground">No exact name and category matches are currently confirmed in stock. Keep your requested item on the list and check its alternatives manually below.</div>}}
                        {for (index, line) in enumerate(chosen.lines) {<div key={str(index)} className="flex items-center justify-between gap-3 border-b pb-3 last:border-0"><div><p className="font-medium">{line.item}</p><p className="text-sm text-muted-foreground">{line.shop} · {line.area}</p><p className="text-xs text-muted-foreground">Qty {str(line.quantity)} · {line.stock}</p>{line.details and <p className="text-xs text-muted-foreground">{line.details}</p>}</div><p className="shrink-0 font-semibold tabular-nums">LKR {str(line.price)}</p></div>}}
                        <div className="flex flex-wrap items-end justify-between gap-3 rounded-lg bg-muted/60 p-4"><div><p className="text-xs text-muted-foreground">Estimated items total</p><p className="text-2xl font-semibold tabular-nums">LKR {str(chosen.total)}</p></div><p className="text-sm text-muted-foreground">{str(chosen.stops)} shop stops</p></div><p className="text-sm leading-relaxed text-muted-foreground">{chosen.explanation}</p><p className="text-xs text-muted-foreground">Simulated demonstration data. Prices and availability are not verified real-world listings.</p>
                    </CardContent></Card>} else {<Card className="shadow-sm"><CardHeader><CardTitle>Ready when you are</CardTitle><CardDescription>Your list will be matched against local demo inventory.</CardDescription></CardHeader><CardContent><div className="rounded-xl border border-dashed bg-background p-6"><p className="font-medium">A clearer trip starts with a comparison.</p><p className="mt-1 text-sm text-muted-foreground">Generate a plan to see available shops, current demo prices and a grouped-stop estimate.</p></div></CardContent></Card>}}
                    <Card className="shadow-sm"><CardHeader><div className="flex flex-wrap items-center justify-between gap-2"><div><CardTitle>Shop inventory</CardTitle><CardDescription>Sample listings across Moratuwa</CardDescription></div><Badge variant="outline">Demo data</Badge></div></CardHeader><CardContent className="flex flex-col gap-3">
                        {if len(inventory) == 0 {<p className="text-sm text-muted-foreground">Loading shop inventory…</p>}}
                        {for (index, product) in enumerate(inventory) {<div key={str(index)} className="flex flex-wrap items-center justify-between gap-3 rounded-lg border bg-background p-3"><div className="min-w-0"><p className="font-medium">{product.name}</p><p className="text-sm text-muted-foreground">{product.shop} · {product.area}</p><p className="text-xs text-muted-foreground">{product.stock} · {product.updated}</p></div><span className="shrink-0 text-sm font-semibold tabular-nums">LKR {str(product.price)}</span></div>}}
                        <p className="text-xs text-muted-foreground">Availability and prices are simulated for demonstration only.</p>
                    </CardContent></Card>
                </div>
            </div>
        </main>
    </div>;
}
