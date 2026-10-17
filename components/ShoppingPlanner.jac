sv import from ..services.shoppingService { ShopItem, PlanLine, ShoppingPlan, getShopInventory }
sv import from ..services.userPlanningService { SavedShoppingPlan, PlanOption, PlanResult, getShoppingList, saveShoppingList, getPlanningPreferences, savePlanningPreferences, getSavedPlans, createSavedShoppingPlan }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.button { Button }
import from .ui.input { Input }
import from .ui.badge { Badge }

def:pub ShoppingPlanner() -> JsxElement {
    has inventory: list[ShopItem] = [],
        selected_items: list[dict] = [],
        saved_plans: list[SavedShoppingPlan] = [],
        alternatives: list[dict] = [],
        plan_options: list[PlanOption] = [],
        plan: ShoppingPlan | None = None,
        item_name: str = "",
        item_category: str = "Other",
        item_brand: str = "",
        item_details: str = "",
        item_quantity: str = "1",
        form_error: str = "",
        status_message: str = "",
        priority: str = "time",
        planning_area: str = "Moratuwa",
        trip_date: str = "",
        trip_window: str = "",
        active_tab: str = "planner",
        loading: bool = True,
        saving: bool = False;

    async can with entry {
        inventory = await getShopInventory();
        saved_items = await getShoppingList();
        loaded_items: list[dict] = [];
        for saved_item in saved_items {
            loaded_items.append({"name": str(saved_item["name"]), "category": str(saved_item["category"]), "brand": str(saved_item["brand"]), "details": str(saved_item["details"]), "quantity": int(saved_item["quantity"])});
        }
        selected_items = loaded_items;
        preferences = await getPlanningPreferences();
        priority = str(preferences["priority"]);
        planning_area = str(preferences["area"]);
        saved_plans = await getSavedPlans();
        loading = False;
    }

    def handle_item_name(e: ChangeEvent) { item_name = e.target.value; form_error = ""; }
    def handle_item_category(e: ChangeEvent) { item_category = e.target.value; }
    def handle_item_brand(e: ChangeEvent) { item_brand = e.target.value; }
    def handle_item_details(e: ChangeEvent) { item_details = e.target.value; }
    def handle_item_quantity(e: ChangeEvent) { item_quantity = e.target.value; form_error = ""; }
    def handle_priority(e: ChangeEvent) { priority = e.target.value; }
    def handle_area(e: ChangeEvent) { planning_area = e.target.value; }
    def handle_trip_date(e: ChangeEvent) { trip_date = e.target.value; }
    def handle_trip_window(e: ChangeEvent) { trip_window = e.target.value; }

    async def persist_list -> None {
        payload: list[dict] = [];
        for value in selected_items {
            payload.append({"name": str(value["name"]), "category": str(value["category"]), "brand": str(value["brand"]), "details": str(value["details"]), "quantity": int(value["quantity"])});
        }
        response = await saveShoppingList(payload);
        if not response["ok"] { status_message = "List could not be saved to this account."; }
    }

    def add_item(e: FormEvent) {
        e.preventDefault();
        clean_name = item_name.strip();
        if not clean_name { form_error = "Enter a product name."; return; }
        quantity_value = 1;
        try { quantity_value = int(item_quantity); } except ValueError { form_error = "Enter a whole-number quantity from 1 to 99."; return; }
        if quantity_value < 1 or quantity_value > 99 { form_error = "Quantity must be between 1 and 99."; return; }
        duplicate = False;
        for existing in selected_items {
            if existing["name"] == clean_name and existing["category"] == item_category and existing["brand"] == item_brand.strip() and existing["details"] == item_details.strip() { duplicate = True; }
        }
        if duplicate { form_error = "That exact item is already on your list. Change its details to add a separate item."; return; }
        selected_items = selected_items + [{"name": clean_name, "category": item_category, "brand": item_brand.strip(), "details": item_details.strip(), "quantity": quantity_value}];
        plan = None;
        plan_options = [];
        alternatives = [];
        item_name = "";
        item_brand = "";
        item_details = "";
        item_quantity = "1";
        form_error = "";
        status_message = "List saved to your account.";
        persist_list();
    }

    def remove_item(item: dict) {
        selected_items = [value for value in selected_items if not (value["name"] == item["name"] and value["category"] == item["category"] and value["brand"] == item["brand"] and value["details"] == item["details"])];
        plan = None;
        plan_options = [];
        alternatives = [];
        status_message = "List saved to your account.";
        persist_list();
    }

    async def save_preferences -> None {
        saving = True;
        response = await savePlanningPreferences(priority, planning_area);
        saving = False;
        status_message = str(response["message"]);
    }

    async def select_plan(option_name: str) {
        request_payload: list[dict] = [];
        for value in selected_items { request_payload.append({"name": str(value["name"]), "category": str(value["category"]), "brand": str(value["brand"]), "details": str(value["details"]), "quantity": int(value["quantity"])}); }
        result = await createSavedShoppingPlan(request_payload, priority, planning_area, option_name);
        plan = result.plan;
        plan_options = result.options;
        alternatives = result.alternatives;
        saved_plans = await getSavedPlans();
        status_message = "Selected plan recalculated and saved.";
    }

    async def make_plan {
        request_payload: list[dict] = [];
        for value in selected_items {
            request_payload.append({"name": str(value["name"]), "category": str(value["category"]), "brand": str(value["brand"]), "details": str(value["details"]), "quantity": int(value["quantity"])});
        }
        result: PlanResult = await createSavedShoppingPlan(request_payload, priority, planning_area);
        plan = result.plan;
        plan_options = result.options;
        alternatives = result.alternatives;
        saved_plans = await getSavedPlans();
        status_message = "Plan saved to your account history.";
        persist_list();
    }

    return <div className="min-h-svh bg-muted/40">
        <header className="border-b bg-background"><div className="mx-auto flex h-16 w-full max-w-7xl items-center justify-between px-5 sm:px-8"><div className="flex items-center gap-3"><div className="flex size-9 items-center justify-center rounded-xl bg-primary text-primary-foreground font-semibold">S</div><div><p className="font-semibold tracking-tight">SmartCart</p><p className="text-xs text-muted-foreground">Shopping planner</p></div></div><Badge variant="secondary">{planning_area}</Badge></div></header>
        <main className="mx-auto flex w-full max-w-7xl flex-col gap-6 px-5 py-8 sm:px-8">
            <section className="flex flex-wrap items-end justify-between gap-4"><div className="flex flex-col gap-2"><p className="text-sm font-medium text-primary">PLAN A BETTER SHOPPING TRIP</p><h1 className="text-3xl font-semibold tracking-tight sm:text-4xl">Your list, thoughtfully planned.</h1><p className="max-w-2xl text-muted-foreground">Save your list, compare shop-managed offers, and plan around your chosen shopping window.</p></div><div className="rounded-xl border bg-card px-4 py-3 shadow-sm"><p className="text-xs text-muted-foreground">Planning area</p><p className="font-medium">{planning_area}, Sri Lanka</p></div></section>
            <div className="flex flex-wrap gap-2"><Button variant={active_tab == "planner" and "default" or "outline"} onClick={lambda { active_tab = "planner"; }}>Planner</Button><Button variant={active_tab == "history" and "default" or "outline"} onClick={lambda { active_tab = "history"; }}>Saved plans</Button><Button variant={active_tab == "preferences" and "default" or "outline"} onClick={lambda { active_tab = "preferences"; }}>Preferences</Button></div>
            {status_message and <p role="status" className="rounded-md border border-primary/30 bg-primary/5 p-3 text-sm">{status_message}</p>}
            {loading and <Card><CardContent className="p-6 text-sm text-muted-foreground">Loading your saved list and preferences…</CardContent></Card>}
            {not loading and active_tab == "planner" and <div className="grid gap-5 lg:grid-cols-[0.9fr_1.1fr]">
                <Card className="shadow-sm"><CardHeader><CardTitle>Shopping list</CardTitle><CardDescription>Your items are saved to your account as you edit. New accounts start with an empty list.</CardDescription></CardHeader><CardContent className="flex flex-col gap-5">
                    <form onSubmit={add_item} className="flex flex-col gap-4"><div className="flex flex-col gap-2"><label htmlFor="item-name" className="text-sm font-medium">Product name</label><Input id="item-name" value={item_name} onChange={handle_item_name} placeholder="Enter the exact product name" /></div>
                        <div className="grid gap-4 sm:grid-cols-2"><div className="flex flex-col gap-2"><label htmlFor="item-category" className="text-sm font-medium">Category</label><select id="item-category" value={item_category} onChange={handle_item_category} className="h-10 rounded-md border border-input bg-background px-3 text-sm"><option>Electronics</option><option>Computers & accessories</option><option>Mobile phones</option><option>Groceries</option><option>Clothing</option><option>Footwear</option><option>Stationery</option><option>Household</option><option>Hardware</option><option>Other</option></select></div><div className="flex flex-col gap-2"><label htmlFor="item-quantity" className="text-sm font-medium">Quantity</label><Input id="item-quantity" type="number" min="1" max="99" value={item_quantity} onChange={handle_item_quantity} /></div></div>
                        <div className="grid gap-4 sm:grid-cols-2"><div className="flex flex-col gap-2"><label htmlFor="item-brand" className="text-sm font-medium">Preferred brand</label><Input id="item-brand" value={item_brand} onChange={handle_item_brand} placeholder="Optional brand" /></div><div className="flex flex-col gap-2"><label htmlFor="item-details" className="text-sm font-medium">Specifications or details</label><Input id="item-details" value={item_details} onChange={handle_item_details} placeholder="Model, size, color, or notes" /></div></div>
                        {form_error and <p role="alert" className="rounded-md border border-destructive/30 bg-destructive/5 p-3 text-sm text-destructive">{form_error}</p>}<Button type="submit" variant="outline" className="w-full sm:w-fit">Add item to list</Button>
                    </form>
                    <div className="flex flex-col gap-2">{if len(selected_items) == 0 {<div className="rounded-lg border border-dashed bg-background p-5"><p className="font-medium">Your list is empty</p><p className="mt-1 text-sm text-muted-foreground">Add a product above to start planning.</p></div>}}{for (index, item) in enumerate(selected_items) {<div key={str(index)} className="flex items-start justify-between gap-3 rounded-lg border bg-background px-3 py-3"><div className="min-w-0"><p className="font-medium">{item["name"]}</p><p className="text-xs text-muted-foreground">{item["category"]} · Qty {str(item["quantity"])}</p>{item["brand"] and <p className="text-xs text-muted-foreground">Brand: {item["brand"]}</p>}{item["details"] and <p className="text-xs text-muted-foreground">{item["details"]}</p>}</div><button type="button" onClick={lambda { remove_item(item); }} className="shrink-0 rounded-md px-2 py-1 text-sm text-muted-foreground hover:bg-muted">Remove</button></div>}}</div>
                    <div className="flex flex-col gap-2"><label htmlFor="trip-date" className="text-sm font-medium">Shopping date</label><Input id="trip-date" type="date" value={trip_date} onChange={handle_trip_date} /><label htmlFor="trip-window" className="text-sm font-medium">Available time window</label><Input id="trip-window" value={trip_window} onChange={handle_trip_window} placeholder="For example, 1:30 PM to 4:00 PM" /><p className="text-xs text-muted-foreground">Scheduling notes are saved with the plan; no live calendar or opening-hours integration is connected.</p></div>
                    <div className="flex flex-col gap-2"><label htmlFor="priority" className="text-sm font-medium">Optimization priority</label><select id="priority" value={priority} onChange={handle_priority} className="h-10 rounded-md border border-input bg-background px-3 text-sm"><option value="cost">Lowest total price</option><option value="distance">Shortest distance</option><option value="stops">Fewest stops</option><option value="time">Shortest travel time</option></select><p className="text-xs text-muted-foreground">Distance and time optimization require road routing, which is not connected yet.</p></div>
                    <Button onClick={make_plan} disabled={len(selected_items) == 0 or saving} className="h-11 w-full shadow-sm">Generate shopping plan</Button>
                </CardContent></Card>
                <div className="flex flex-col gap-5">
                    {if plan is not None {chosen = plan as ShoppingPlan;<div className="flex flex-col gap-4"><div className="grid gap-4 xl:grid-cols-3">{for (option_index, option) in enumerate(plan_options) {<Card key={str(option_index)} className="border-primary/20 shadow-sm"><CardHeader><CardTitle>{option.name}</CardTitle><CardDescription>{option.focus}</CardDescription></CardHeader><CardContent className="flex flex-col gap-3"><div className="flex items-end justify-between rounded-lg bg-muted/60 p-3"><div><p className="text-xs text-muted-foreground">Product total</p><p className="text-xl font-semibold tabular-nums">LKR {str(option.total)}</p></div><p className="text-sm">{str(option.stops)} stops</p></div>{for (line_index, line) in enumerate(option.lines) {<div key={str(line_index)} className="border-b pb-3 last:border-0"><p className="font-medium">{line.item}</p><p className="text-sm text-muted-foreground">{line.shop} · {line.area}</p><p className="text-xs text-muted-foreground">Qty {str(line.quantity)} · {line.stock}</p><p className="text-sm font-medium">LKR {str(line.price)}</p></div>}}{if len(option.lines) == 0 {<p className="text-sm text-muted-foreground">No matching confirmed in-stock items for this plan.</p>}}<p className="text-xs text-muted-foreground">Travel time and road distance: {option.travel_estimate}</p><Button variant="outline" onClick={lambda { select_plan(option.name); }}>Choose and save this plan</Button></CardContent></Card>}}</div><Card className="border-primary/30 shadow-sm"><CardHeader><CardTitle>Selected plan</CardTitle><CardDescription>Current saved recommendation · {str(chosen.stops)} shop visits</CardDescription></CardHeader><CardContent className="flex flex-col gap-3"><p className="text-2xl font-semibold tabular-nums">LKR {str(chosen.total)} product total</p><p className="text-sm text-muted-foreground">{chosen.explanation}</p></CardContent></Card></div>} else {<Card className="shadow-sm"><CardHeader><CardTitle>Ready to plan</CardTitle><CardDescription>Compare convenience, price, and backup options from current in-stock shop listings.</CardDescription></CardHeader><CardContent><p className="rounded-xl border border-dashed bg-background p-6 text-sm text-muted-foreground">Your list is saved to your signed-in account. Generate three plans to compare current offers.</p></CardContent></Card>}}
                    <Card className="shadow-sm"><CardHeader><CardTitle>Shop inventory comparison</CardTitle><CardDescription>Current listings from registered shops in {planning_area}.</CardDescription></CardHeader><CardContent className="flex flex-col gap-3">
                        {if len(inventory) == 0 {<div className="rounded-lg border border-dashed p-6"><p className="font-medium">No shop listings available</p><p className="mt-1 text-sm text-muted-foreground">No shops have published inventory yet. Listings appear here when shops add products.</p></div>}}
                        {for (index, product) in enumerate(inventory) {<div key={str(index)} className="flex flex-wrap items-center justify-between gap-3 rounded-lg border bg-background p-3"><div><p className="font-medium">{product.name}</p><p className="text-sm text-muted-foreground">{product.shop} · {product.area}</p><p className="text-xs text-muted-foreground">{product.category} · {product.stock} · {product.updated}</p></div><span className="font-semibold tabular-nums">LKR {str(product.price)}</span></div>}}
                    </CardContent></Card>
                    <Card className="shadow-sm"><CardHeader><CardTitle>Route map</CardTitle><CardDescription>Interactive map unavailable</CardDescription></CardHeader><CardContent><div className="rounded-lg border border-dashed bg-muted/30 p-6"><p className="font-medium">Map routing is not connected</p><p className="mt-1 text-sm text-muted-foreground">No map provider is installed. Shop addresses and locations are shown in each listing; no road route is claimed.</p></div></CardContent></Card>
                </div>
            </div>}
            {not loading and active_tab == "preferences" and <div className="grid gap-4 lg:grid-cols-2"><Card><CardHeader><CardTitle>Planning preferences</CardTitle><CardDescription>Save a default strategy and planning area to your account.</CardDescription></CardHeader><CardContent className="flex flex-col gap-4"><div className="flex flex-col gap-2"><label htmlFor="preference-priority" className="text-sm font-medium">Default optimization</label><select id="preference-priority" value={priority} onChange={handle_priority} className="h-10 rounded-md border border-input bg-background px-3 text-sm"><option value="cost">Lowest total price</option><option value="distance">Shortest distance</option><option value="stops">Fewest stops</option><option value="time">Shortest travel time</option></select></div><div className="flex flex-col gap-2"><label htmlFor="planning-area" className="text-sm font-medium">Planning area</label><Input id="planning-area" value={planning_area} onChange={handle_area} placeholder="Moratuwa" /></div><Button disabled={saving} onClick={save_preferences}>{"Saving…" if saving else "Save preferences"}</Button><p className="text-xs text-muted-foreground">Road distance and travel time require an external routing provider; these options remain labeled estimates.</p></CardContent></Card><Card><CardHeader><CardTitle>Scheduling tools</CardTitle><CardDescription>Schedule context for your trip.</CardDescription></CardHeader><CardContent><p className="text-sm text-muted-foreground">Choose a date and time window in Planner. A synced editable calendar and task-conflict integration are not connected yet.</p></CardContent></Card></div>}
            {not loading and active_tab == "history" and <Card className="shadow-sm"><CardHeader><CardTitle>Saved plans</CardTitle><CardDescription>Your recent generated plans for {planning_area}.</CardDescription></CardHeader><CardContent className="flex flex-col gap-3">
                {if len(saved_plans) == 0 {<div className="rounded-lg border border-dashed p-6"><p className="font-medium">No saved plans yet</p><p className="mt-1 text-sm text-muted-foreground">Plans you generate will be saved to your account history.</p></div>}}
                {for (index, saved) in enumerate(saved_plans) {<div key={str(index)} className="flex flex-wrap items-start justify-between gap-4 rounded-lg border bg-background p-4"><div><p className="font-medium">{saved.item_summary}</p><p className="text-sm text-muted-foreground">{saved.area} · Priority: {saved.priority}</p><p className="text-xs text-muted-foreground">{saved.created_at} · {str(saved.stops)} stops</p></div><div className="text-right"><p className="font-semibold tabular-nums">LKR {str(saved.total)}</p><p className="text-xs text-muted-foreground">{saved.explanation}</p></div></div>}}
            </CardContent></Card>}
        </main>
    </div>;
}
