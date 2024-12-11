//
//  coffe_statusApp.swift
//  coffe-status
//
//  Created by Daniel Jansson on 2024-11-30.
//

import SwiftUI

struct CoffeState {
    var cupsLeft: Int;
    var state: String;
    var updated: Date;
}

class CoffeStateStore: ObservableObject {
    @Published var coffeState: CoffeState = .init(cupsLeft: 0, state: "", updated: Date())
    var timer: Timer?
    let UPDATE_INTERVAL: TimeInterval = 15.0
    
    init() {
        refreshCoffeeState()
        timer = Timer.scheduledTimer(withTimeInterval: self.UPDATE_INTERVAL, repeats: true) { _ in
            self.refreshCoffeeState()
        }
    }
    deinit {
        timer?.invalidate()
    }
    
    func setCoffeState (state: CoffeState) async {
        await MainActor.run {
            coffeState = state
        }
    }
    
    func getCurrentCoffeState() async -> CoffeState {
        do {
            let url = URL(string: "https://scalenet.swace.cloud/api/status")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            
            return CoffeState(cupsLeft: json["cupsLeft"]! as! Int, state: json["state"]! as! String, updated: Date())
        }
        catch {
            print(error)
            return CoffeState(cupsLeft: -1, state: "Error", updated: Date())
        }
    }
    
    func refreshCoffeeState() {
        Task {
            await self.setCoffeState(state: await self.getCurrentCoffeState())
        }
    }
    
}

@main
struct CoffeStatusApp: App {
    @StateObject var store = CoffeStateStore()
    
    var body: some Scene {
        MenuBarExtra {
            Text("Coffe Status: \(store.coffeState.state)");
            Text("Updated: \(String(describing: dateInLocalTimeZone(date: store.coffeState.updated)))");
            Button("Refresh") {
                store.refreshCoffeeState()
            }.keyboardShortcut("r")
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        } label: {
            Image(systemName: store.coffeState.state == "BREWING" ? "cup.and.heat.waves.fill" : "cup.and.saucer.fill")
            Text(store.coffeState.state == "OFFLINE" ? "!" : "\(store.coffeState.cupsLeft)")
        }
    }
    
    func dateInLocalTimeZone(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}
