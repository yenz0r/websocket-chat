import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    // Example of configuring a controller
    let todoController = TodoController()
    router.get("todos", use: todoController.index)
    router.post("todos", use: todoController.create)
    router.delete("todos", Todo.parameter, use: todoController.delete)
}

enum SendingType {
    case data, text
}

func getUserIdentifiers(user socket: WebSocket, in clients: [String: WebSocket]) -> [String]? {
    guard let keys = (clients as NSDictionary).allKeys(for: socket) as? [String] else {
        return nil
    }
    return keys
}

public func routeSocket(_ serverSocket: NIOWebSocketServer) throws {
    var clients = [String: WebSocket]()

    serverSocket.get("chat-room") { ws, req in
        ws.onBinary { ws, data in
            var dataDict: [String: String] = [:]
            do {
                dataDict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: String]
            } catch {
                print("data err")
            }

            guard let key = dataDict.keys.first, let value = dataDict.values.first else { return }

            switch key {
            case "login" :
                guard !clients.keys.contains(value) else {
                    ws.send("Fail connection by \(value)\n")
                    return
                }
                ws.send("Connected by \(value)\n")
                clients.values.forEach { $0.send("User \(value) - connected!\n") }
                clients[value] = ws
            case "message" :
                guard let name = getUserIdentifiers(user: ws, in: clients)?.first else {
                    return
                }
                clients.values.forEach { $0.send("\(name) : \(value)\n") }
            default:
                print("hz")
                break
            }
        }

        ws.onCloseCode { code in
            guard let name = getUserIdentifiers(user: ws, in: clients)?.first else { return }
            clients.values.forEach { $0.send("User \(name) - disconnected!\n") }
            clients.removeValue(forKey: name)
        }
    }
}
