import Kitura
import LoggerAPI
import HeliumLogger
import Foundation
import ActivitiesService
import MySQL

// Disable stdout buffering (so log will appear)
setbuf(stdout, nil)

// Init logger
HeliumLogger.use(.info)

// Create connection string (use env variables, if exists)
let env = ProcessInfo.processInfo.environment
var connectionString = MySQLConnectionString(host: env["MYSQL_HOST"] ?? "localhost")
if let portString = env["MYSQL_PORT"], let port = Int(portString) {
  connectionString.port = port
}
connectionString.user = env["MYSQL_USER"] ?? "root"
connectionString.password = env["MYSQL_PASSWORD"] ?? "password"
connectionString.database = env["MYSQL_DATABASE"] ?? "game-night"

// Create connection pool
var pool = MySQLConnectionPool(connectionString: connectionString, poolSize: 10) {
  return MySQL.MySQLConnection()
}

// Create handlers
let handlers = Handlers(connectionPool: pool)

// Create router
let router = Router()

// Setup paths
// TODO: Move into a controller object?
router.all("/*", middleware: BodyParser())
router.all("/*", middleware: AllRemoteOriginMiddleware())
router.all("/*", middleware: LoggerMiddleware())
router.options("/*", handler: handlers.getOptions)

router.get("/*", middleware: CheckRequestMiddleware(method: .get))
router.get("/activities", handler: handlers.getActivities)
router.get("/activities/:id", handler: handlers.getActivity)

router.post("/*", middleware: CheckRequestMiddleware(method: .post))
router.post("/activities", handler: handlers.postActivity)

router.put("/*", middleware: CheckRequestMiddleware(method: .put))
router.put("/activities/:id", handler: handlers.postActivity)

router.delete("/*", middleware: CheckRequestMiddleware(method: .delete))
//router.delete("/activities/:id", handler: handlers.deleteActivity)

// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: 8080, with: router)

// Start the Kitura runloop (this call never returns)
Kitura.run()
