sv import from ..services.shoppingService { ShopItem, PlanLine, ShoppingPlan, getShopInventory, generateShoppingPlan }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.button { Button }
import from .ui.input { Input }
import from .ui.badge { Badge }

def:pub ShoppingPlanner() -> JsxElement {
    has inventory: list[ShopItem] = [],
        selected_items: list[str] = ["laptop", "mouse", "charger", "groceries"],
        plan: ShoppingPlan | None = None,
        draft: str = "",
        priority: str = "time";

    async can with entry {
        inventory = await getShopInventory();
    }

    def handle_draft(e: ChangeEvent) { draft = e.target.value; }
    def handle_priority(e: ChangeEvent) { priority = e.target.value; }

    def add_item(e: FormEvent) {
        e.preventDefault();
        clean = draft.strip().lower();
        if clean and clean not in selected_items {
            if "laptop" in clean { selected_items = selected_items + ["laptop"]; }
            elif "mouse" in clean { selected_items = selected_items + ["mouse"]; }
            elif "charger" in clean or "phone" in clean { selected_items = selected_items + ["charger"]; }
            elif "grocer" in clean or "food" in clean { selected_items = selected_items + ["groceries"]; }
            else { selected_items = selected_items + [clean]; }
            plan = None;
            draft = "";
        }
    }

    def remove_item(item: str) {
        selected_items = [value for value in selected_items if value != item];
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
                <Card className="shadow-sm"><CardHeader><CardTitle>Shopping list</CardTitle><CardDescription>Add the essentials you need. Your list stays here when you recalculate.</CardDescription></CardHeader><CardContent className="flex flex-col gap-5">
                    <form onSubmit={add_item} className="flex gap-2"><Input aria-label="Product to add" value={draft} onChange={handle_draft} placeholder="Try: laptop or groceries" /><Button type="submit" variant="outline">Add item</Button></form>
                    <div className="flex flex-col gap-2">{for item in selected_items {<div key={item} className="flex items-center justify-between rounded-lg border bg-background px-3 py-3"><div><p className="font-medium capitalize">{item}</p><p className="text-xs text-muted-foreground">{"Electronics · suitable demo options" if item != "groceries" else "Groceries · essentials bundle"}</p></div><button type="button" onClick={lambda { remove_item(item); }} className="rounded-md px-2 py-1 text-sm text-muted-foreground hover:bg-muted">Remove</button></div>}}</div>
                    <div className="flex flex-col gap-2"><label htmlFor="priority" className="text-sm font-medium">Planning priority</label><select id="priority" value={priority} onChange={handle_priority} className="h-10 rounded-md border border-input bg-background px-3 text-sm"><option value="time">Fewer stops · time-aware fallback</option><option value="cost">Lowest confirmed item prices</option></select><p className="text-xs text-muted-foreground">Road routing and calendar integration are not connected; estimates are clearly labeled.</p></div>
                    <Button onClick={make_plan} disabled={len(selected_items) == 0} className="h-11 w-full shadow-sm">Generate shopping plan</Button>
                </CardContent></Card>
                <div className="flex flex-col gap-5">
                    {if plan is not None {chosen = plan as ShoppingPlan;<Card className="border-primary/30 shadow-sm"><CardHeader><div className="flex flex-wrap items-start justify-between gap-3"><div><CardTitle>Your suggested plan</CardTitle><CardDescription>Grouped using current demo inventory</CardDescription></div><Badge variant="secondary">Estimate · simulated data</Badge></div></CardHeader><CardContent className="flex flex-col gap-4">
                        {if len(chosen.lines) == 0 {<div className="rounded-lg border border-dashed p-5 text-sm text-muted-foreground">No listed products matched in-stock demo records. Try a listed item from the inventory below.</div>}}
                        {for (index, line) in enumerate(chosen.lines) {<div key={str(index)} className="flex items-center justify-between gap-3 border-b pb-3 last:border-0"><div><p className="font-medium">{line.item}</p><p className="text-sm text-muted-foreground">{line.shop} · {line.area}</p><p className="text-xs text-emerald-700">{line.stock}</p></div><p className="shrink-0 font-semibold tabular-nums">LKR {str(line.price)}</p></div>}}
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
