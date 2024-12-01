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
    
    init() {
        Task {
            await self.setCoffeState(state: await self.getCurrentCoffeState())
        }
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task {
                await self.setCoffeState(state: await self.getCurrentCoffeState())
            }
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
            // return  CoffeState (cupsLeft: Int(json["cupsLeft"]!))
        }
        catch {
            print(error)
            return CoffeState(cupsLeft: -1, state: "Error", updated: Date())
        }
    }

}

@main
struct CoffeStatusApp: App {
    @StateObject var store = CoffeStateStore()
    
    var body: some Scene {
        MenuBarExtra {
            Text("Coffe Status: \(store.coffeState.state)");
            Text("Updated: \(String(describing: store.coffeState.updated))");
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        } label: {
            Image(systemName: "cup.and.saucer.fill")
            Text("\(store.coffeState.cupsLeft)")
        }
    }
}
