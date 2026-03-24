import { application } from "./application"

import MobileMenuController from "./mobile_menu_controller"
import ToastController from "./toast_controller"
import ClipboardController from "./clipboard_controller"
import SearchController from "./search_controller"
import CountdownController from "./countdown_controller"
import RiskGaugeController from "./risk_gauge_controller"
import FeedController from "./feed_controller"

application.register("mobile-menu", MobileMenuController)
application.register("toast", ToastController)
application.register("clipboard", ClipboardController)
application.register("search", SearchController)
application.register("countdown", CountdownController)
application.register("risk-gauge", RiskGaugeController)
application.register("feed", FeedController)
