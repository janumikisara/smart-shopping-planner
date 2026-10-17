import from .components.ShoppingPlanner { ShoppingPlanner }
import ".styles.global.css";
import from "@jac/runtime" { Router, Routes, Route }

def:pub app() -> JsxElement {
    return <Router><Routes><Route path="/" element={<ShoppingPlanner />} /></Routes></Router>;
}
