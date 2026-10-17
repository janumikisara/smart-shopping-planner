import from authService { createUserProfile, registerAccount, getAuthenticatedRole, authorizeDashboard }
import from services.shopService { ShopProfile, InventoryEntry, getShopProfile, saveShopProfile, saveShopLocation, getSavedShopLocations, listOwnInventory, addInventoryEntry, updateInventoryEntry, deleteInventoryEntry, getPublicShopProfile, listShopInventory }
import from services.shoppingService { ShoppingRequest, ShopItem, PlanLine, ShoppingPlan, getShopInventory, generateShoppingPlan }
import from services.userPlanningService { SavedListItem, PlanningPreference, SavedShoppingPlan, PlanResult, getShoppingList, saveShoppingList, getPlanningPreferences, savePlanningPreferences, getSavedPlans, createSavedShoppingPlan }
import from .components.ShoppingPlanner { ShoppingPlanner }
import from .components.RoleLogin { RoleLogin }
import from .components.RoleRegistration { RoleRegistration }
import from .components.RoleGuard { RoleGuard }
import from .components.UserDashboard { UserDashboard }
import from .components.ShopDashboard { ShopDashboard }
import from .components.DeveloperDashboard { DeveloperDashboard }
import ".styles.global.css";
import from "@jac/runtime" { Router, Routes, Route, Navigate }

def:pub app() -> JsxElement {
    return <Router><Routes>
        <Route path="/" element={<Navigate to="/login" replace={True} />} />
        <Route path="/login" element={<RoleLogin />} />
        <Route path="/register" element={<RoleRegistration />} />
        <Route path="/dashboard/user" element={<RoleGuard role="user"><UserDashboard /></RoleGuard>} />
        <Route path="/dashboard/shop" element={<RoleGuard role="shop"><ShopDashboard /></RoleGuard>} />
        <Route path="/dashboard/developer" element={<RoleGuard role="developer"><DeveloperDashboard /></RoleGuard>} />
        <Route path="/planner" element={<RoleGuard role="user"><ShoppingPlanner /></RoleGuard>} />
        <Route path="*" element={<Navigate to="/login" replace={True} />} />
    </Routes></Router>;
}
